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
    .select("id, user_id, display_name, experience, location, phone, specialties, certificate_note, status, review_note, reviewed_at, reviewed_by, submitted_at", { count: "exact" })
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
  const result = await service
    .from("merchant_applications")
    .update({ status: input.status, review_note: reviewNote, reviewed_at: new Date().toISOString(), reviewed_by: session.user.id })
    .eq("id", applicationId)
    .select("id, user_id, display_name, status, review_note, reviewed_at, reviewed_by, submitted_at")
    .single();
  if (result.error) throw result.error;
  await recordAudit(session, {
    action: `merchant_application.${input.status}`,
    entityType: "merchant_applications",
    entityId: applicationId,
    metadata: { reviewNote },
  });
  return result.data;
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
  if (Object.keys(update).length === 0) throw new Error("لا توجد تغييرات صالحة.");
  const service = createServiceSupabaseClient();
  const result = await service.from("products").update(update).eq("id", productId).select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "product.update", entityType: "products", entityId: productId, metadata: { fields: Object.keys(update) } });
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
  const identities = await service.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (identities.error) throw identities.error;
  const profileByUserId = new Map((profiles.data ?? []).map((profile) => [profile.user_id, profile]));
  const identityByUserId = new Map(identities.data.users.map((user) => [user.id, user]));
  return (users.data ?? []).map((user) => ({
    ...user,
    email: identityByUserId.get(user.id)?.email ?? null,
    emailConfirmedAt: identityByUserId.get(user.id)?.email_confirmed_at ?? null,
    profile: profileByUserId.get(user.id) ?? null,
  }));
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

export async function sendNotification(session: AdminSession, input: { userId: string; titleAr: string; bodyAr?: string | null; notificationType?: string; payload?: Record<string, unknown> }) {
  if (!hasPermission(session, "notification.write")) throw new Error("لا تملك صلاحية إرسال إشعار.");
  const service = createServiceSupabaseClient();
  const result = await service.from("notifications").insert({
    user_id: requireText(input.userId, "المستخدم"),
    title_ar: requireText(input.titleAr, "عنوان الإشعار"),
    body_ar: input.bodyAr ?? null,
    notification_type: input.notificationType ?? "admin_message",
    payload: (input.payload ?? {}) as Json,
  }).select("id, user_id, notification_type, title_ar, body_ar, payload, read_at, created_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "notification.create", entityType: "notifications", entityId: result.data.id, metadata: { userId: input.userId } });
  return result.data;
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
