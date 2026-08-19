import { randomBytes } from "node:crypto";
import type { Database, Json } from "../../../packages/contracts_ts/src/database";
import { createServiceSupabaseClient } from "./supabase";
import { type AdminSession, hasPermission } from "./admin-auth";

const MAX_PAGE_SIZE = 50;
type TableName = Extract<keyof Database["public"]["Tables"], string>;

type QueryOptions = {
  page?: number;
  pageSize?: number;
  search?: string;
};

function pageOf(options: QueryOptions = {}) {
  const page = Math.max(1, Math.floor(options.page ?? 1));
  const pageSize = Math.min(MAX_PAGE_SIZE, Math.max(1, Math.floor(options.pageSize ?? 20)));
  return { page, pageSize, from: (page - 1) * pageSize, to: page * pageSize - 1 };
}

async function countRows(table: TableName): Promise<number> {
  const service = createServiceSupabaseClient();
  const result = await service.from(table).select("id", { count: "exact", head: true });
  if (result.error) throw result.error;
  return result.count ?? 0;
}

export async function getDashboardSnapshot() {
  const [users, stores, products, requests, regions, banners] = await Promise.all([
    countRows("users"),
    countRows("stores"),
    countRows("products"),
    countRows("requests"),
    countRows("regions"),
    countRows("banners"),
  ]);
  return {
    source: "supabase_production" as const,
    counts: { users, stores, products, requests, regions, banners },
    generatedAt: new Date().toISOString(),
  };
}

export async function listProducts(options: QueryOptions = {}) {
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service
    .from("products")
    .select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (options.search?.trim()) query = query.ilike("name_ar", `%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function listStores(options: QueryOptions = {}) {
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service
    .from("stores")
    .select("id, merchant_id, region_id, name_ar, slug, description, phone, logo_url, cover_url, status, is_verified, created_at, updated_at", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (options.search?.trim()) query = query.ilike("name_ar", `%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function deleteStore(session: AdminSession, storeId: string) {
  if (!hasPermission(session, "store.delete")) throw new Error("لا تملك صلاحية حذف المتجر.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("stores").select("id, merchant_id, name_ar").eq("id", storeId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المتجر غير موجود.");
  await recordAudit(session, {
    action: "store.delete.requested",
    entityType: "stores",
    entityId: storeId,
    metadata: { merchantId: existing.data.merchant_id, nameAr: existing.data.name_ar },
  });
  const deleted = await service.from("stores").delete().eq("id", storeId);
  if (deleted.error) throw deleted.error;
  return { id: storeId, deleted: true };
}

export async function deleteProduct(session: AdminSession, productId: string) {
  if (!hasPermission(session, "product.delete")) throw new Error("لا تملك صلاحية حذف المنتج.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("products").select("id, store_id, name_ar").eq("id", productId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المنتج غير موجود.");
  await recordAudit(session, { action: "product.delete.requested", entityType: "products", entityId: productId, metadata: { storeId: existing.data.store_id, nameAr: existing.data.name_ar } });
  const deleted = await service.from("products").delete().eq("id", productId);
  if (deleted.error) throw deleted.error;
  return { id: productId, deleted: true };
}

export async function deleteBanner(session: AdminSession, bannerId: string) {
  if (!hasPermission(session, "banner.delete")) throw new Error("لا تملك صلاحية حذف البانر.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("banners").select("id, title_ar, image_url").eq("id", bannerId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("البانر غير موجود.");
  await recordAudit(session, { action: "banner.delete.requested", entityType: "banners", entityId: bannerId, metadata: { titleAr: existing.data.title_ar, imageUrl: existing.data.image_url } });
  const deleted = await service.from("banners").delete().eq("id", bannerId);
  if (deleted.error) throw deleted.error;
  return { id: bannerId, deleted: true };
}

export async function deleteUser(session: AdminSession, userId: string) {
  if (!hasPermission(session, "user.delete")) throw new Error("لا تملك صلاحية حذف المستخدم.");
  if (userId === session.user.id) throw new Error("لا يمكن حذف الهوية الإدارية الحالية من داخل الجلسة.");
  const service = createServiceSupabaseClient();
  const membership = await service.from("admin_users").select("user_id").eq("user_id", userId).maybeSingle();
  if (membership.error) throw membership.error;
  if (membership.data) throw new Error("لا يُحذف مدير إداري من مسار حذف المستخدمين. عطّل العضوية من قسم المديرين أولًا.");
  const existing = await service.from("users").select("id").eq("id", userId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المستخدم غير موجود.");
  await recordAudit(session, { action: "user.delete.requested", entityType: "users", entityId: userId, metadata: { cascade: true } });
  const deleted = await service.auth.admin.deleteUser(userId);
  if (deleted.error) throw deleted.error;
  return { id: userId, deleted: true };
}

export async function uploadPublicImage(session: AdminSession, input: { contentType: string; base64: string; purpose?: string }) {
  if (!hasPermission(session, "storage.public.write")) throw new Error("لا تملك صلاحية رفع الصور العامة.");
  const contentType = input.contentType.trim().toLowerCase();
  const supported = new Map([["image/jpeg", "jpg"], ["image/png", "png"], ["image/webp", "webp"], ["image/gif", "gif"]]);
  const extension = supported.get(contentType);
  if (!extension) throw new Error("نوع الصورة غير مدعوم. استخدم JPG أو PNG أو WEBP أو GIF.");
  const encoded = input.base64.replace(/^data:[^;]+;base64,/, "");
  const bytes = Buffer.from(encoded, "base64");
  if (!bytes.length || bytes.length > 10 * 1024 * 1024) throw new Error("حجم الصورة يجب أن يكون بين 1 بايت و10 ميجابايت.");
  const purpose = (input.purpose?.trim().replace(/[^a-z0-9_-]/gi, "-") || "admin").slice(0, 32);
  const path = `${purpose}/${Date.now()}-${randomBytes(12).toString("hex")}.${extension}`;
  const service = createServiceSupabaseClient();
  const uploaded = await service.storage.from("assalkom_public").upload(path, bytes, { contentType, upsert: false });
  if (uploaded.error) throw uploaded.error;
  const publicUrl = service.storage.from("assalkom_public").getPublicUrl(path).data.publicUrl;
  await recordAudit(session, { action: "storage.public_image.upload", entityType: "storage.objects", metadata: { bucket: "assalkom_public", path, contentType, bytes: bytes.length } });
  return { bucket: "assalkom_public", path, publicUrl, contentType, bytes: bytes.length };
}

export async function listRequests(options: QueryOptions = {}) {
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  const result = await service
    .from("requests")
    .select("id, requester_id, store_id, subject, body, status, preferred_handoff_option, created_at, updated_at", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function listMerchantApplications(options: QueryOptions = {}) {
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service
    .from("merchant_applications")
    .select("id, user_id, display_name, experience, location, phone, specialties, certificate_note, store_description, region_id, logo_url, cover_url, status, review_note, reviewed_at, reviewed_by, submitted_at", { count: "exact" })
    .order("submitted_at", { ascending: false })
    .range(from, to);
  if (options.search?.trim()) query = query.ilike("display_name", `%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function reviewMerchantApplication(
  session: AdminSession,
  applicationId: string,
  input: { status: "approved" | "rejected" | "needs_more_info"; reviewNote?: string | null },
) {
  if (!hasPermission(session, "merchant.review")) throw new Error("لا تملك صلاحية مراجعة طلبات التجار.");
  const reviewNote = input.reviewNote?.trim() || null;
  const service = createServiceSupabaseClient();
  const result = await service.rpc("admin_review_merchant_application", {
    p_application_id: applicationId,
    p_status: input.status,
    p_review_note: reviewNote ?? undefined,
    p_reviewer_id: session.user.id,
  });
  if (result.error) throw result.error;
  const payload = (result.data ?? {}) as {
    application?: Record<string, unknown>;
    store?: Record<string, unknown> | null;
    notification?: Record<string, unknown> | null;
  };
  const application = payload.application ?? (result.data as Record<string, unknown>);
  await recordAudit(session, {
    action: `merchant_application.${input.status}`,
    entityType: "merchant_applications",
    entityId: applicationId,
    metadata: {
      reviewNote,
      synchronized: input.status === "approved",
      storeId: payload.store?.id ?? null,
      notificationId: payload.notification?.id ?? null,
    },
  });
  return { ...application, store: payload.store ?? null, notification: payload.notification ?? null };
}

export async function listRegions() {
  const service = createServiceSupabaseClient();
  const result = await service
    .from("regions")
    .select("id, parent_region_id, name_ar, name_en, code, region_level, name_ar_normalized, name_en_normalized, is_active, created_at")
    .eq("is_active", true)
    .order("region_level", { ascending: true })
    .order("name_ar", { ascending: true })
    .limit(500);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listTaxonomy() {
  const service = createServiceSupabaseClient();
  const result = await service
    .from("honey_taxonomy")
    .select("id, code, name_ar, name_en, description, metadata, is_active, created_at, updated_at")
    .eq("is_active", true)
    .order("name_ar", { ascending: true })
    .limit(200);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listCategories() {
  const service = createServiceSupabaseClient();
  const result = await service
    .from("categories")
    .select("id, parent_id, name_ar, name_en, slug, category_kind, sort_order, is_active, created_at, updated_at")
    .order("sort_order", { ascending: true })
    .order("name_ar", { ascending: true })
    .limit(200);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listBanners() {
  const service = createServiceSupabaseClient();
  const result = await service
    .from("banners")
    .select("id, title_ar, body_ar, image_url, cta_label_ar, cta_url, starts_at, ends_at, sort_order, is_active, created_at, updated_at")
    .order("sort_order", { ascending: true })
    .order("created_at", { ascending: false })
    .limit(100);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function recordAudit(
  session: AdminSession,
  input: { action: string; entityType: string; entityId?: string | null; metadata?: Record<string, unknown> },
) {
  if (!session.user.id) throw new Error("لا توجد هوية إدارية لتسجيل التدقيق.");
  const service = createServiceSupabaseClient();
  const result = await service.from("audit_logs").insert({
    actor_user_id: session.user.id,
    action: input.action,
    entity_type: input.entityType,
    entity_id: input.entityId ?? null,
    metadata: (input.metadata ?? {}) as Json,
  });
  if (result.error) throw result.error;
}

export async function moderateStore(
  session: AdminSession,
  storeId: string,
  action: "approve" | "reject" | "suspend" | "reactivate",
) {
  const permission = action === "approve" ? "store.approve" : action === "reject" ? "store.reject" : "store.suspend";
  if (!hasPermission(session, permission)) throw new Error("لا تملك صلاحية تعديل المتجر.");
  const patch = action === "approve"
    ? { status: "active", is_verified: true }
    : action === "reject"
      ? { status: "rejected", is_verified: false }
      : action === "suspend"
        ? { status: "suspended", is_verified: false }
        : { status: "active" };
  const service = createServiceSupabaseClient();
  const result = await service.from("stores").update(patch).eq("id", storeId).select("id, status, is_verified").single();
  if (result.error) throw result.error;
  await recordAudit(session, {
    action: `store.${action}`,
    entityType: "stores",
    entityId: storeId,
    metadata: { patch },
  });
  return result.data;
}

export type ProductWriteInput = {
  storeId: string;
  taxonomyId?: string | null;
  categoryId?: string | null;
  nameAr: string;
  nameEn?: string | null;
  description?: string | null;
  productType?: string;
  gradeLevel?: number | null;
  isFeatured?: boolean;
  status?: string;
  metadata?: Record<string, unknown>;
  price?: number | null;
  currencyCode?: string | null;
  imageUrls?: string[];
};

function requireText(value: unknown, label: string): string {
  if (typeof value !== "string" || !value.trim()) throw new Error(`${label} مطلوب.`);
  return value.trim();
}

export async function createProduct(session: AdminSession, input: ProductWriteInput) {
  if (!hasPermission(session, "product.write")) throw new Error("لا تملك صلاحية إنشاء منتج.");
  const nameAr = requireText(input.nameAr, "اسم المنتج");
  const storeId = requireText(input.storeId, "المتجر");
  const metadata = {
    ...(input.metadata ?? {}),
    ...(input.price === undefined ? {} : { price: input.price === null ? null : String(input.price) }),
    ...(input.currencyCode === undefined ? {} : { currency_code: input.currencyCode }),
  };
  const service = createServiceSupabaseClient();
  const created = await service.from("products").insert({
    store_id: storeId,
    taxonomy_id: input.taxonomyId ?? null,
    name_ar: nameAr,
    name_en: input.nameEn ?? null,
    description: input.description ?? null,
    product_type: input.productType ?? "honey",
    grade_level: input.gradeLevel ?? null,
    is_featured: input.isFeatured ?? false,
    status: input.status ?? "draft",
    metadata: metadata as Json,
  }).select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at").single();
  if (created.error) throw created.error;
  await recordAudit(session, { action: "product.create", entityType: "products", entityId: created.data.id, metadata: { storeId, status: input.status ?? "draft" } });
  if (input.categoryId) {
    const relation = await service.from("product_categories").upsert({ product_id: created.data.id, category_id: input.categoryId });
    if (relation.error) throw relation.error;
  }
  if (input.imageUrls !== undefined) {
    const urls = input.imageUrls.filter((url) => typeof url === "string" && url.trim()).map((url) => url.trim());
    if (urls.length) {
      const images = await service.from("product_images").insert(urls.map((imageUrl, sortOrder) => ({ product_id: created.data.id, image_url: imageUrl, sort_order: sortOrder })));
      if (images.error) throw images.error;
    }
  }
  return created.data;
}

export async function updateProduct(session: AdminSession, productId: string, patch: Partial<ProductWriteInput>) {
  if (!hasPermission(session, "product.write")) throw new Error("لا تملك صلاحية تعديل المنتج.");
  const update: Database["public"]["Tables"]["products"]["Update"] = {};
  if (patch.storeId !== undefined) update.store_id = requireText(patch.storeId, "المتجر");
  if (patch.taxonomyId !== undefined) update.taxonomy_id = patch.taxonomyId;
  if (patch.nameAr !== undefined) update.name_ar = requireText(patch.nameAr, "اسم المنتج");
  if (patch.nameEn !== undefined) update.name_en = patch.nameEn;
  if (patch.description !== undefined) update.description = patch.description;
  if (patch.productType !== undefined) update.product_type = patch.productType;
  if (patch.gradeLevel !== undefined) update.grade_level = patch.gradeLevel;
  if (patch.isFeatured !== undefined) update.is_featured = patch.isFeatured;
  if (patch.status !== undefined) update.status = patch.status;
  if (patch.metadata !== undefined || patch.price !== undefined || patch.currencyCode !== undefined) {
    const service = createServiceSupabaseClient();
    const current = await service.from("products").select("metadata").eq("id", productId).single();
    if (current.error) throw current.error;
    update.metadata = {
      ...((current.data.metadata as Record<string, unknown> | null) ?? {}),
      ...(patch.metadata ?? {}),
      ...(patch.price === undefined ? {} : { price: patch.price === null ? null : String(patch.price) }),
      ...(patch.currencyCode === undefined ? {} : { currency_code: patch.currencyCode }),
    } as Json;
  }
  if (Object.keys(update).length === 0 && patch.imageUrls === undefined) throw new Error("لا توجد تغييرات صالحة.");
  const service = createServiceSupabaseClient();
  const result = Object.keys(update).length
    ? await service.from("products").update(update).eq("id", productId).select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at").single()
    : await service.from("products").select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at").eq("id", productId).single();
  if (result.error) throw result.error;
  if (patch.imageUrls !== undefined) {
    const removed = await service.from("product_images").delete().eq("product_id", productId);
    if (removed.error) throw removed.error;
    const urls = patch.imageUrls.filter((url) => typeof url === "string" && url.trim()).map((url) => url.trim());
    if (urls.length) {
      const images = await service.from("product_images").insert(urls.map((imageUrl, sortOrder) => ({ product_id: productId, image_url: imageUrl, sort_order: sortOrder })));
      if (images.error) throw images.error;
    }
  }
  await recordAudit(session, { action: "product.update", entityType: "products", entityId: productId, metadata: { fields: [...Object.keys(update), ...(patch.imageUrls === undefined ? [] : ["imageUrls"])] } });
  return result.data;
}

export type BannerWriteInput = {
  titleAr: string;
  bodyAr?: string | null;
  imageUrl?: string | null;
  ctaLabelAr?: string | null;
  ctaUrl?: string | null;
  startsAt?: string | null;
  endsAt?: string | null;
  sortOrder?: number;
  isActive?: boolean;
};

export async function createBanner(session: AdminSession, input: BannerWriteInput) {
  if (!hasPermission(session, "banner.write")) throw new Error("لا تملك صلاحية إنشاء بانر.");
  const service = createServiceSupabaseClient();
  const result = await service.from("banners").insert({
    title_ar: requireText(input.titleAr, "عنوان البانر"),
    body_ar: input.bodyAr ?? null,
    image_url: input.imageUrl ?? null,
    cta_label_ar: input.ctaLabelAr ?? null,
    cta_url: input.ctaUrl ?? null,
    starts_at: input.startsAt ?? null,
    ends_at: input.endsAt ?? null,
    sort_order: input.sortOrder ?? 0,
    is_active: input.isActive ?? false,
  }).select("id, title_ar, body_ar, image_url, cta_label_ar, cta_url, starts_at, ends_at, sort_order, is_active, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "banner.create", entityType: "banners", entityId: result.data.id, metadata: { isActive: input.isActive ?? false } });
  return result.data;
}

export async function updateBanner(session: AdminSession, bannerId: string, patch: Partial<BannerWriteInput>) {
  if (!hasPermission(session, "banner.write")) throw new Error("لا تملك صلاحية تعديل بانر.");
  const update: Database["public"]["Tables"]["banners"]["Update"] = {};
  if (patch.titleAr !== undefined) update.title_ar = requireText(patch.titleAr, "عنوان البانر");
  if (patch.bodyAr !== undefined) update.body_ar = patch.bodyAr;
  if (patch.imageUrl !== undefined) update.image_url = patch.imageUrl;
  if (patch.ctaLabelAr !== undefined) update.cta_label_ar = patch.ctaLabelAr;
  if (patch.ctaUrl !== undefined) update.cta_url = patch.ctaUrl;
  if (patch.startsAt !== undefined) update.starts_at = patch.startsAt;
  if (patch.endsAt !== undefined) update.ends_at = patch.endsAt;
  if (patch.sortOrder !== undefined) update.sort_order = patch.sortOrder;
  if (patch.isActive !== undefined) {
    if (patch.isActive && !hasPermission(session, "banner.publish")) throw new Error("لا تملك صلاحية نشر البانر.");
    update.is_active = patch.isActive;
  }
  if (Object.keys(update).length === 0) throw new Error("لا توجد تغييرات صالحة.");
  const service = createServiceSupabaseClient();
  const result = await service.from("banners").update(update).eq("id", bannerId).select("id, title_ar, body_ar, image_url, cta_label_ar, cta_url, starts_at, ends_at, sort_order, is_active, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "banner.update", entityType: "banners", entityId: bannerId, metadata: { fields: Object.keys(update) } });
  return result.data;
}

export async function upsertCategory(session: AdminSession, input: { id?: string; parentId?: string | null; nameAr: string; nameEn?: string | null; slug: string; categoryKind?: string; sortOrder?: number; isActive?: boolean }) {
  if (!hasPermission(session, "taxonomy.manage")) throw new Error("لا تملك صلاحية إدارة التصنيفات.");
  const service = createServiceSupabaseClient();
  const result = await service.from("categories").upsert({
    id: input.id,
    parent_id: input.parentId ?? null,
    name_ar: requireText(input.nameAr, "اسم التصنيف"),
    name_en: input.nameEn ?? null,
    slug: requireText(input.slug, "slug التصنيف"),
    category_kind: input.categoryKind ?? "honey",
    sort_order: input.sortOrder ?? 0,
    is_active: input.isActive ?? true,
  }).select("id, parent_id, name_ar, name_en, slug, category_kind, sort_order, is_active, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "category.upsert", entityType: "categories", entityId: result.data.id, metadata: { slug: result.data.slug } });
  return result.data;
}

export async function upsertTaxonomy(session: AdminSession, input: { id?: string; code: string; nameAr: string; nameEn?: string | null; description?: string | null; metadata?: Record<string, unknown>; isActive?: boolean }) {
  if (!hasPermission(session, "taxonomy.manage")) throw new Error("لا تملك صلاحية إدارة تصنيف العسل.");
  const service = createServiceSupabaseClient();
  const result = await service.from("honey_taxonomy").upsert({
    id: input.id,
    code: requireText(input.code, "رمز التصنيف"),
    name_ar: requireText(input.nameAr, "اسم التصنيف"),
    name_en: input.nameEn ?? null,
    description: input.description ?? null,
    metadata: (input.metadata ?? {}) as Json,
    is_active: input.isActive ?? true,
  }).select("id, code, name_ar, name_en, description, metadata, is_active, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "taxonomy.upsert", entityType: "honey_taxonomy", entityId: result.data.id, metadata: { code: result.data.code } });
  return result.data;
}

export async function answerRequest(session: AdminSession, requestId: string, body: string) {
  if (!hasPermission(session, "message.write")) throw new Error("لا تملك صلاحية الرد على الطلب.");
  const message = requireText(body, "نص الرد");
  const service = createServiceSupabaseClient();
  const inserted = await service.from("request_messages").insert({ request_id: requestId, sender_id: session.user.id, body: message }).select("id, request_id, sender_id, body, created_at").single();
  if (inserted.error) throw inserted.error;
  const updated = await service.from("requests").update({ status: "answered" }).eq("id", requestId).select("id, status, updated_at").single();
  if (updated.error) throw updated.error;
  await recordAudit(session, { action: "request.answer", entityType: "requests", entityId: requestId, metadata: { messageId: inserted.data.id } });
  return { message: inserted.data, request: updated.data };
}

export async function listAdminUsers() {
  const service = createServiceSupabaseClient();
  const memberships = await service.from("admin_users").select("user_id, role_id, is_active, scope, created_at, updated_at").order("created_at", { ascending: true }).limit(100);
  if (memberships.error) throw memberships.error;
  const roles = await service.from("admin_roles").select("id, code, name_ar, permissions").limit(50);
  if (roles.error) throw roles.error;
  const identities = await service.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (identities.error) throw identities.error;
  const rolesById = new Map((roles.data ?? []).map((role) => [role.id, role]));
  const identitiesById = new Map(identities.data.users.map((user) => [user.id, user]));
  return (memberships.data ?? []).map((membership) => ({
    ...membership,
    email: identitiesById.get(membership.user_id)?.email ?? null,
    name: identitiesById.get(membership.user_id)?.user_metadata?.name ?? identitiesById.get(membership.user_id)?.user_metadata?.display_name ?? null,
    role: rolesById.get(membership.role_id) ?? null,
  }));
}

export async function updateAdminMembership(session: AdminSession, userId: string, input: { roleId?: string; isActive?: boolean; scope?: Record<string, unknown> }) {
  if (!hasPermission(session, "admin.manage")) throw new Error("لا تملك صلاحية إدارة المديرين.");
  if (userId === session.user.id && input.isActive === false) throw new Error("لا يمكن للمدير تعطيل هويته الحالية.");
  const update: Database["public"]["Tables"]["admin_users"]["Update"] = {};
  if (input.roleId !== undefined) update.role_id = requireText(input.roleId, "الدور");
  if (input.isActive !== undefined) update.is_active = input.isActive;
  if (input.scope !== undefined) update.scope = input.scope as Json;
  if (Object.keys(update).length === 0) throw new Error("لا توجد تغييرات صالحة.");
  const service = createServiceSupabaseClient();
  const result = await service.from("admin_users").update(update).eq("user_id", userId).select("user_id, role_id, is_active, scope, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "admin_user.update", entityType: "admin_users", entityId: userId, metadata: { fields: Object.keys(update) } });
  return result.data;
}

export async function listAuditLogs() {
  const service = createServiceSupabaseClient();
  const result = await service.from("audit_logs").select("id, actor_user_id, action, entity_type, entity_id, metadata, created_at").order("created_at", { ascending: false }).limit(100);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listUsers() {
  const service = createServiceSupabaseClient();
  const users = await service.from("users").select("id, created_at, last_seen_at").order("created_at", { ascending: false }).limit(100);
  if (users.error) throw users.error;
  const profiles = await service.from("profiles").select("user_id, display_name, phone, avatar_url, bio, locale, role, is_active, created_at, updated_at").limit(100);
  if (profiles.error) throw profiles.error;
  const applications = await service.from("merchant_applications").select("id, user_id, status, location, review_note, submitted_at, reviewed_at").order("submitted_at", { ascending: false }).limit(200);
  if (applications.error) throw applications.error;
  const stores = await service.from("stores").select("id, merchant_id, name_ar, status, is_verified, updated_at").limit(200);
  if (stores.error) throw stores.error;
  const identities = await service.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (identities.error) throw identities.error;
  const profileByUserId = new Map((profiles.data ?? []).map((profile) => [profile.user_id, profile]));
  const applicationByUserId = new Map((applications.data ?? []).map((application) => [application.user_id, application]));
  const storeByMerchantId = new Map((stores.data ?? []).map((store) => [store.merchant_id, store]));
  const identityByUserId = new Map(identities.data.users.map((user) => [user.id, user]));
  return (users.data ?? []).map((user) => {
    const identity = identityByUserId.get(user.id);
    const application = applicationByUserId.get(user.id) ?? null;
    const store = storeByMerchantId.get(user.id) ?? null;
    return {
      ...user,
      email: identity?.email ?? null,
      emailConfirmedAt: identity?.email_confirmed_at ?? null,
      authCreatedAt: identity?.created_at ?? null,
      lastSignInAt: identity?.last_sign_in_at ?? null,
      lastActiveAt: null,
      phone: identity?.phone ?? null,
      profile: profileByUserId.get(user.id) ?? null,
      merchantApplication: application,
      store,
      networkTelemetry: { ipAddress: null, noteAr: "عنوان IP غير مسجل في مخطط Production الحالي." },
    };
  });
}

export async function listMessages() {
  const service = createServiceSupabaseClient();
  const messages = await service.from("request_messages").select("id, request_id, sender_id, body, created_at").order("created_at", { ascending: false }).limit(100);
  if (messages.error) throw messages.error;
  const requestIds = Array.from(new Set((messages.data ?? []).map((message) => message.request_id)));
  const requests = requestIds.length ? await service.from("requests").select("id, subject, status, store_id").in("id", requestIds).limit(100) : { data: [], error: null };
  if (requests.error) throw requests.error;
  const requestById = new Map((requests.data ?? []).map((request) => [request.id, request]));
  return (messages.data ?? []).map((message) => ({ ...message, request: requestById.get(message.request_id) ?? null }));
}

export async function listNotifications() {
  const service = createServiceSupabaseClient();
  const result = await service.from("notifications").select("id, user_id, notification_type, title_ar, body_ar, payload, read_at, created_at").order("created_at", { ascending: false }).limit(100);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function sendNotification(session: AdminSession, input: { userId?: string | null; broadcast?: boolean; titleAr: string; bodyAr?: string | null; notificationType?: string; imageUrl?: string | null; payload?: Record<string, unknown> }) {
  if (!hasPermission(session, "notification.write")) throw new Error("لا تملك صلاحية إرسال إشعار.");
  const titleAr = requireText(input.titleAr, "عنوان الإشعار");
  const service = createServiceSupabaseClient();
  const usersResult = input.broadcast
    ? await service.from("users").select("id").limit(10000)
    : null;
  if (usersResult?.error) throw usersResult.error;
  const resolvedRecipients: Array<{ id: string }> = input.broadcast
    ? ((usersResult?.data ?? []) as Array<{ id: string }>)
    : [{ id: requireText(input.userId, "المستخدم") }];
  if (!resolvedRecipients.length) throw new Error("لا يوجد مستخدمون مستهدفون في Production.");
  const payload = {
    ...(input.payload ?? {}),
    ...(input.imageUrl?.trim() ? { image_url: input.imageUrl.trim() } : {}),
  } as Json;
  const rows = resolvedRecipients.map((recipient) => ({
    user_id: recipient.id,
    title_ar: titleAr,
    body_ar: input.bodyAr?.trim() || null,
    notification_type: input.notificationType ?? (input.broadcast ? "admin_broadcast" : "admin_message"),
    payload,
  }));
  const inserted = await service.from("notifications").insert(rows).select("id, user_id, notification_type, title_ar, body_ar, payload, read_at, created_at");
  if (inserted.error) throw inserted.error;
  await recordAudit(session, {
    action: input.broadcast ? "notification.broadcast" : "notification.create",
    entityType: "notifications",
    entityId: null,
    metadata: { recipientCount: rows.length, userId: input.userId ?? null, imageUrl: input.imageUrl ?? null },
  });
  return { broadcast: input.broadcast === true, recipientCount: rows.length, items: inserted.data ?? [] };
}

export async function getOperationalAnalytics() {
  const snapshot = await getDashboardSnapshot();
  const service = createServiceSupabaseClient();
  const [activeStores, publishedProducts, openRequests, unreadNotifications] = await Promise.all([
    service.from("stores").select("id", { count: "exact", head: true }).eq("status", "active"),
    service.from("products").select("id", { count: "exact", head: true }).eq("status", "published"),
    service.from("requests").select("id", { count: "exact", head: true }).in("status", ["open", "in_progress"]),
    service.from("notifications").select("id", { count: "exact", head: true }).is("read_at", null),
  ]);
  for (const result of [activeStores, publishedProducts, openRequests, unreadNotifications]) if (result.error) throw result.error;
  return {
    ...snapshot,
    operational: {
      activeStores: activeStores.count ?? 0,
      publishedProducts: publishedProducts.count ?? 0,
      openRequests: openRequests.count ?? 0,
      unreadNotifications: unreadNotifications.count ?? 0,
    },
  };
}

export async function createAdminIdentity(session: AdminSession, input: { email: string; roleCode?: string; scope?: Record<string, unknown> }) {
  if (session.role.code !== "super_admin") throw new Error("إنشاء مدير جديد متاح للمدير العام فقط.");
  const email = requireText(input.email, "البريد الإداري").toLowerCase();
  const roleCode = input.roleCode?.trim() || "moderator";
  const service = createServiceSupabaseClient();
  const role = await service.from("admin_roles").select("id, code, name_ar").eq("code", roleCode).single();
  if (role.error || !role.data) throw role.error ?? new Error("الدور الإداري غير موجود.");
  const password = randomBytes(24).toString("base64url");
  const identity = await service.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { name: "مدير عسلكم", must_change_password: true } });
  if (identity.error || !identity.data.user) throw identity.error ?? new Error("تعذر إنشاء Admin Auth Identity.");
  const membership = await service.from("admin_users").insert({ user_id: identity.data.user.id, role_id: role.data.id, is_active: true, scope: (input.scope ?? {}) as Json, created_by: session.user.id }).select("user_id, role_id, is_active, scope, created_at").single();
  if (membership.error) {
    await service.auth.admin.deleteUser(identity.data.user.id);
    throw membership.error;
  }
  await recordAudit(session, { action: "admin_user.create", entityType: "admin_users", entityId: identity.data.user.id, metadata: { email, roleCode } });
  return { email, temporaryPassword: password, membership: membership.data, role: role.data };
}
