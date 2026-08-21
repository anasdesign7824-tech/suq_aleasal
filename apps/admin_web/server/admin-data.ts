import { randomBytes } from "node:crypto";
import type { Database, Json } from "../../../packages/contracts_ts/src/database";
import { createServiceSupabaseClient } from "./supabase";
import { type AdminPermission, type AdminSession, hasPermission } from "./admin-auth";

const MAX_PAGE_SIZE = 50;
export const MAX_PUBLIC_IMAGE_BYTES = 10 * 1024 * 1024;
export const ADMIN_PRODUCT_STATUSES = ["draft", "pending", "active", "paused", "rejected"] as const;
export const STORE_MODERATION_ACTIONS = ["approve", "reject", "suspend", "reactivate"] as const;
export type StoreModerationAction = (typeof STORE_MODERATION_ACTIONS)[number];
export const ADMIN_NETWORK_TELEMETRY_UNAVAILABLE = "عنوان IP غير مسجل في مخطط Production الحالي.";
export function buildAdminNetworkTelemetry(): { ipAddress: null; noteAr: string } {
  return { ipAddress: null, noteAr: ADMIN_NETWORK_TELEMETRY_UNAVAILABLE };
}
export function storeModerationPermission(action: StoreModerationAction): AdminPermission {
  return action === "approve" || action === "reactivate" ? "store.approve" : action === "reject" ? "store.reject" : "store.suspend";
}
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

export type AdminPaginationTelemetry = {
  resource: string;
  page: number;
  pageSize: number;
  returnedCount: number;
  total: number;
  elapsedMs: number;
};

export function buildAdminPaginationTelemetry(input: Omit<AdminPaginationTelemetry, "elapsedMs"> & { startedAt: number }): AdminPaginationTelemetry {
  return {
    resource: input.resource,
    page: input.page,
    pageSize: input.pageSize,
    returnedCount: input.returnedCount,
    total: input.total,
    elapsedMs: Math.max(0, Date.now() - input.startedAt),
  };
}

function logAdminPagination(input: Omit<AdminPaginationTelemetry, "elapsedMs"> & { startedAt: number }) {
  console.info("[Admin Performance]", buildAdminPaginationTelemetry(input));
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
  const startedAt = Date.now();
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service
    .from("products")
    .select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at, product_images(id, image_url, sort_order)", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (options.search?.trim()) query = query.ilike("name_ar", `%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  const items = result.data ?? [];
  logAdminPagination({ resource: "products", page, pageSize, returnedCount: items.length, total: result.count ?? 0, startedAt });
  return { items, page, pageSize, total: result.count ?? 0 };
}

export async function listStores(options: QueryOptions = {}) {
  const startedAt = Date.now();
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
  const items = result.data ?? [];
  logAdminPagination({ resource: "stores", page, pageSize, returnedCount: items.length, total: result.count ?? 0, startedAt });
  return { items, page, pageSize, total: result.count ?? 0 };
}

export async function deleteStore(session: AdminSession, storeId: string) {
  if (!hasPermission(session, "store.delete")) throw new Error("لا تملك صلاحية حذف المتجر.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("stores").select("id, merchant_id, name_ar").eq("id", storeId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المتجر غير موجود.");
  const deleted = await service.from("stores").delete().eq("id", storeId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, {
    action: "store.delete",
    entityType: "stores",
    entityId: storeId,
    metadata: { merchantId: existing.data.merchant_id, nameAr: existing.data.name_ar, cascade: true },
  });
  return { id: storeId, deleted: true };
}

export async function deleteProduct(session: AdminSession, productId: string) {
  if (!hasPermission(session, "product.delete")) throw new Error("لا تملك صلاحية حذف المنتج.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("products").select("id, store_id, name_ar").eq("id", productId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المنتج غير موجود.");
  const deleted = await service.from("products").delete().eq("id", productId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, { action: "product.delete", entityType: "products", entityId: productId, metadata: { storeId: existing.data.store_id, nameAr: existing.data.name_ar, deleted: true } });
  return { id: productId, deleted: true };
}

export async function deleteBanner(session: AdminSession, bannerId: string) {
  if (!hasPermission(session, "banner.delete")) throw new Error("لا تملك صلاحية حذف البانر.");
  const service = createServiceSupabaseClient();
  const existing = await service.from("banners").select("id, title_ar, image_url").eq("id", bannerId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("البانر غير موجود.");
  const deleted = await service.from("banners").delete().eq("id", bannerId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, { action: "banner.delete", entityType: "banners", entityId: bannerId, metadata: { titleAr: existing.data.title_ar, imageUrl: existing.data.image_url, deleted: true } });
  return { id: bannerId, deleted: true };
}

export function assertUserDeletionAllowed(currentAdminId: string, targetUserId: string, targetIsAdmin: boolean): void {
  if (targetUserId === currentAdminId) throw new Error("لا يمكن حذف الهوية الإدارية الحالية من داخل الجلسة.");
  if (targetIsAdmin) throw new Error("لا يُحذف مدير إداري من مسار حذف المستخدمين. عطّل العضوية من قسم المديرين أولًا.");
}

export async function deleteUser(session: AdminSession, userId: string) {
  if (!hasPermission(session, "user.delete")) throw new Error("لا تملك صلاحية حذف المستخدم.");
  const service = createServiceSupabaseClient();
  const membership = await service.from("admin_users").select("user_id").eq("user_id", userId).maybeSingle();
  if (membership.error) throw membership.error;
  assertUserDeletionAllowed(session.user.id, userId, Boolean(membership.data));
  const existing = await service.from("users").select("id").eq("id", userId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("المستخدم غير موجود.");
  const deleted = await service.auth.admin.deleteUser(userId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, { action: "user.delete", entityType: "users", entityId: userId, metadata: { cascade: true, deleted: true } });
  return { id: userId, deleted: true };
}

export function sanitizeStoragePurpose(purpose?: string): string {
  return (purpose?.trim().replace(/[^a-z0-9_-]/gi, "-") || "admin").slice(0, 32);
}

export function validatePublicImageSignature(contentType: string, bytes: Buffer): void {
  const startsWith = (signature: number[]) => bytes.subarray(0, signature.length).equals(Buffer.from(signature));
  const valid = contentType === "image/jpeg"
    ? startsWith([0xff, 0xd8, 0xff])
    : contentType === "image/png"
      ? startsWith([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])
      : contentType === "image/webp"
        ? startsWith([0x52, 0x49, 0x46, 0x46]) && bytes.subarray(8, 12).equals(Buffer.from([0x57, 0x45, 0x42, 0x50]))
        : (() => {
            const prefix = bytes.subarray(0, 4096).toString("utf8").trimStart().toLowerCase();
            return prefix.startsWith("<svg") || (prefix.startsWith("<?xml") && prefix.includes("<svg"));
          })();
  if (!valid) throw new Error("توقيع الملف لا يطابق نوع الصورة المعلن.");
}

export function decodePublicImageInput(input: { contentType?: string; base64?: string }) {
  const contentType = typeof input.contentType === "string" ? input.contentType.trim().toLowerCase() : "";
  const supported = new Map([
    ["image/jpeg", "jpg"],
    ["image/png", "png"],
    ["image/webp", "webp"],
    ["image/svg+xml", "svg"],
  ]);
  const extension = supported.get(contentType);
  if (!extension) throw new Error("نوع الصورة غير مدعوم. استخدم JPG أو PNG أو WEBP أو SVG.");
  const encoded = typeof input.base64 === "string"
    ? input.base64.replace(/^data:[^;]+;base64,/, "").replace(/\s/g, "")
    : "";
  if (!encoded || encoded.length % 4 === 1 || !/^[A-Za-z0-9+/]*={0,2}$/.test(encoded)) {
    throw new Error("بيانات الصورة المشفرة غير صالحة.");
  }
  const bytes = Buffer.from(encoded, "base64");
  if (!bytes.length || bytes.length > MAX_PUBLIC_IMAGE_BYTES) {
    throw new Error("حجم الصورة يجب أن يكون بين 1 بايت و10 ميجابايت.");
  }
  validatePublicImageSignature(contentType, bytes);
  return { contentType, extension, bytes };
}

export async function uploadPublicImage(session: AdminSession, input: { contentType: string; base64: string; purpose?: string }) {
  if (!hasPermission(session, "storage.public.write")) throw new Error("لا تملك صلاحية رفع الصور العامة.");
  const { contentType, extension, bytes } = decodePublicImageInput(input);
  const purpose = sanitizeStoragePurpose(input.purpose);
  const path = `${purpose}/${Date.now()}-${randomBytes(12).toString("hex")}.${extension}`;
  const service = createServiceSupabaseClient();
  const uploaded = await service.storage.from("assalkom_public").upload(path, bytes, { contentType, upsert: false });
  if (uploaded.error) throw uploaded.error;
  const publicUrl = service.storage.from("assalkom_public").getPublicUrl(path).data.publicUrl;
  await recordAudit(session, { action: "storage.public_image.upload", entityType: "storage.objects", metadata: { bucket: "assalkom_public", path, contentType, bytes: bytes.length } });
  return { bucket: "assalkom_public", path, publicUrl, contentType, bytes: bytes.length };
}

export async function listRequests(options: QueryOptions = {}) {
  const startedAt = Date.now();
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  const result = await service
    .from("requests")
    .select("id, requester_id, store_id, subject, body, status, preferred_handoff_option, created_at, updated_at", { count: "exact" })
    .order("created_at", { ascending: false })
    .range(from, to);
  if (result.error) throw result.error;
  const items = result.data ?? [];
  logAdminPagination({ resource: "requests", page, pageSize, returnedCount: items.length, total: result.count ?? 0, startedAt });
  return { items, page, pageSize, total: result.count ?? 0 };
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
      hasReviewNote: Boolean(reviewNote?.trim()),
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

export async function listDeliveryMethods() {
  const service = createServiceSupabaseClient();
  const result = await service
    .from("delivery_methods")
    .select("id, code, name_ar, description, is_active, created_at")
    .eq("is_active", true)
    .order("name_ar", { ascending: true })
    .limit(100);
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listStoreLogistics(storeId: string) {
  const normalizedStoreId = requireText(storeId, "المتجر");
  const service = createServiceSupabaseClient();
  const [delivery, pickup] = await Promise.all([
    service
      .from("merchant_delivery_options")
      .select("id, store_id, delivery_method_id, region_id, fee_amount, currency, estimated_days, is_active, created_at")
      .eq("store_id", normalizedStoreId)
      .order("created_at", { ascending: false }),
    service
      .from("merchant_pickup_locations")
      .select("id, store_id, region_id, name_ar, address, phone, geo_lat, geo_lng, is_active, created_at, updated_at")
      .eq("store_id", normalizedStoreId)
      .order("created_at", { ascending: false }),
  ]);
  if (delivery.error) throw delivery.error;
  if (pickup.error) throw pickup.error;
  const methodIds = Array.from(new Set((delivery.data ?? []).map((item) => item.delivery_method_id)));
  const regionIds = Array.from(new Set([
    ...(delivery.data ?? []).map((item) => item.region_id).filter((value): value is string => Boolean(value)),
    ...(pickup.data ?? []).map((item) => item.region_id).filter((value): value is string => Boolean(value)),
  ]));
  const [methods, regions] = await Promise.all([
    methodIds.length ? service.from("delivery_methods").select("id, code, name_ar, description, is_active").in("id", methodIds) : Promise.resolve({ data: [], error: null }),
    regionIds.length ? service.from("regions").select("id, parent_region_id, name_ar, name_en, code, region_level, is_active").in("id", regionIds) : Promise.resolve({ data: [], error: null }),
  ]);
  if (methods.error) throw methods.error;
  if (regions.error) throw regions.error;
  return {
    deliveryMethods: methods.data ?? [],
    deliveryOptions: delivery.data ?? [],
    pickupLocations: pickup.data ?? [],
    regions: regions.data ?? [],
  };
}

function finiteNumber(value: unknown, label: string, options: { integer?: boolean; min?: number } = {}) {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || (options.integer && !Number.isInteger(parsed)) || (options.min !== undefined && parsed < options.min)) {
    throw new Error(`${label} غير صالح.`);
  }
  return parsed;
}

export async function upsertDeliveryOption(
  session: AdminSession,
  input: { id?: string; storeId: string; deliveryMethodId: string; regionId?: string | null; feeAmount?: number | string | null; currency?: string; estimatedDays?: number | string | null; isActive?: boolean },
) {
  if (!hasPermission(session, "logistics.manage")) throw new Error("لا تملك صلاحية إدارة طرق التوصيل.");
  const storeId = requireText(input.storeId, "المتجر");
  const deliveryMethodId = requireText(input.deliveryMethodId, "طريقة التوصيل");
  const currency = (input.currency?.trim().toUpperCase() || "YER").slice(0, 8);
  const feeAmount = finiteNumber(input.feeAmount, "رسوم التوصيل", { min: 0 });
  const estimatedDays = finiteNumber(input.estimatedDays, "مدة التوصيل", { integer: true, min: 0 });
  const service = createServiceSupabaseClient();
  const payload = {
    ...(input.id ? { id: input.id } : {}),
    store_id: storeId,
    delivery_method_id: deliveryMethodId,
    region_id: input.regionId || null,
    fee_amount: feeAmount,
    currency,
    estimated_days: estimatedDays,
    is_active: input.isActive ?? true,
  };
  const result = await service.from("merchant_delivery_options").upsert(payload, { onConflict: "store_id,delivery_method_id,region_id" }).select("id, store_id, delivery_method_id, region_id, fee_amount, currency, estimated_days, is_active, created_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "delivery_option.upsert", entityType: "merchant_delivery_options", entityId: result.data.id, metadata: { storeId, deliveryMethodId, regionId: input.regionId ?? null } });
  return result.data;
}

export async function deleteDeliveryOption(session: AdminSession, id: string) {
  if (!hasPermission(session, "logistics.manage")) throw new Error("لا تملك صلاحية إدارة طرق التوصيل.");
  const optionId = requireText(id, "خيار التوصيل");
  const service = createServiceSupabaseClient();
  const existing = await service.from("merchant_delivery_options").select("id, store_id, delivery_method_id").eq("id", optionId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("خيار التوصيل غير موجود.");
  const deleted = await service.from("merchant_delivery_options").delete().eq("id", optionId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, { action: "delivery_option.delete", entityType: "merchant_delivery_options", entityId: optionId, metadata: { storeId: existing.data.store_id } });
  return { id: optionId, deleted: true };
}

export async function upsertPickupLocation(
  session: AdminSession,
  input: { id?: string; storeId: string; regionId?: string | null; nameAr: string; address?: string | null; phone?: string | null; geoLat?: number | string | null; geoLng?: number | string | null; isActive?: boolean },
) {
  if (!hasPermission(session, "logistics.manage")) throw new Error("لا تملك صلاحية إدارة نقاط الاستلام.");
  const storeId = requireText(input.storeId, "المتجر");
  const nameAr = requireText(input.nameAr, "اسم نقطة الاستلام");
  const geoLat = finiteNumber(input.geoLat, "خط العرض");
  const geoLng = finiteNumber(input.geoLng, "خط الطول");
  const service = createServiceSupabaseClient();
  const payload = {
    ...(input.id ? { id: input.id } : {}),
    store_id: storeId,
    region_id: input.regionId || null,
    name_ar: nameAr,
    address: input.address?.trim() || null,
    phone: input.phone?.trim() || null,
    geo_lat: geoLat,
    geo_lng: geoLng,
    is_active: input.isActive ?? true,
  };
  const result = await service.from("merchant_pickup_locations").upsert(payload).select("id, store_id, region_id, name_ar, address, phone, geo_lat, geo_lng, is_active, created_at, updated_at").single();
  if (result.error) throw result.error;
  await recordAudit(session, { action: "pickup_location.upsert", entityType: "merchant_pickup_locations", entityId: result.data.id, metadata: { storeId, regionId: input.regionId ?? null } });
  return result.data;
}

export async function deletePickupLocation(session: AdminSession, id: string) {
  if (!hasPermission(session, "logistics.manage")) throw new Error("لا تملك صلاحية إدارة نقاط الاستلام.");
  const locationId = requireText(id, "نقطة الاستلام");
  const service = createServiceSupabaseClient();
  const existing = await service.from("merchant_pickup_locations").select("id, store_id, name_ar").eq("id", locationId).maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error("نقطة الاستلام غير موجودة.");
  const deleted = await service.from("merchant_pickup_locations").delete().eq("id", locationId);
  if (deleted.error) throw deleted.error;
  await recordAudit(session, { action: "pickup_location.delete", entityType: "merchant_pickup_locations", entityId: locationId, metadata: { storeId: existing.data.store_id, nameAr: existing.data.name_ar } });
  return { id: locationId, deleted: true };
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

const AUDIT_SENSITIVE_METADATA_FLAGS: Record<string, string> = {
  email: "hasEmail",
  phone: "hasPhone",
  senderPhone: "hasSenderPhone",
  accountNumber: "hasAccountNumber",
  iban: "hasIban",
  proofPath: "hasProofPath",
  paymentReference: "hasPaymentReference",
  note: "hasNote",
  reviewNote: "hasReviewNote",
  adminNote: "hasAdminNote",
};

function redactAuditMetadata(metadata: Record<string, unknown> = {}) {
  const redacted = { ...metadata };
  for (const [sensitiveKey, flagKey] of Object.entries(AUDIT_SENSITIVE_METADATA_FLAGS)) {
    if (!(sensitiveKey in redacted)) continue;
    const value = redacted[sensitiveKey];
    delete redacted[sensitiveKey];
    redacted[flagKey] = typeof value === "string" ? value.trim().length > 0 : value != null;
  }
  return redacted;
}

export function buildAuditEntry(
  session: AdminSession,
  input: { action: string; entityType: string; entityId?: string | null; metadata?: Record<string, unknown> },
) {
  if (!session.user.id) throw new Error("لا توجد هوية إدارية لتسجيل التدقيق.");
  return {
    actor_user_id: session.user.id,
    action: input.action,
    entity_type: input.entityType,
    entity_id: input.entityId ?? null,
    metadata: redactAuditMetadata(input.metadata) as Json,
  };
}

export async function recordAudit(
  session: AdminSession,
  input: { action: string; entityType: string; entityId?: string | null; metadata?: Record<string, unknown> },
) {
  const service = createServiceSupabaseClient();
  const result = await service.from("audit_logs").insert(buildAuditEntry(session, input));
  if (result.error) throw result.error;
}

export async function moderateStore(
  session: AdminSession,
  storeId: string,
  action: StoreModerationAction,
) {
  const permission = storeModerationPermission(action);
  if (!hasPermission(session, permission)) throw new Error("لا تملك صلاحية تعديل المتجر.");
  const service = createServiceSupabaseClient();
  const result = await service.rpc("admin_moderate_store", {
    p_store_id: storeId,
    p_action: action,
    p_reviewer_id: session.user.id,
  });
  if (result.error) throw result.error;
  const payload = (result.data ?? {}) as {
    store?: Record<string, unknown> | null;
    merchant_profile?: Record<string, unknown> | null;
    application?: Record<string, unknown> | null;
    notification?: Record<string, unknown> | null;
  };
  await recordAudit(session, {
    action: `store.${action}`,
    entityType: "stores",
    entityId: storeId,
    metadata: {
      synchronized: action === "approve" || action === "reactivate",
      merchantId: payload.store?.merchant_id ?? null,
      applicationId: payload.application?.id ?? null,
      notificationId: payload.notification?.id ?? null,
    },
  });
  return payload.store ?? result.data;
}

export type StoreVerificationReviewAction =
  | 'approve'
  | 'reject'
  | 'needs_more_info'
  | 'revoke';

export type StoreVerificationPaymentStatus =
  | 'paid'
  | 'waived'
  | 'failed'
  | 'refunded';

export async function listStoreVerificationRequests(options: QueryOptions = {}) {
  if (!options) throw new Error('خيارات القراءة غير صالحة.');
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service
    .from('store_verification_requests')
    .select('id, store_id, merchant_id, plan_code, origin, status, payment_status, payment_reference, submitted_at, reviewed_at, reviewed_by, review_note, expires_at, created_at, updated_at', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to);
  if (options.search?.trim()) query = query.ilike('store_id', `%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  const requests = result.data ?? [];
  const storeIds = Array.from(new Set(requests.map((item) => item.store_id)));
  const merchantIds = Array.from(new Set(requests.map((item) => item.merchant_id)));
  const [stores, profiles, documents] = await Promise.all([
    storeIds.length ? service.from('stores').select('id, merchant_id, name_ar, status, logo_url, cover_url').in('id', storeIds) : Promise.resolve({ data: [], error: null }),
    merchantIds.length ? service.from('profiles').select('user_id, display_name, phone, avatar_url').in('user_id', merchantIds) : Promise.resolve({ data: [], error: null }),
    requests.length ? service.from('store_verification_documents').select('id, request_id, document_type, file_name, mime_type, byte_size, review_status, review_note, file_path, created_at').in('request_id', requests.map((item) => item.id)).order('created_at', { ascending: true }) : Promise.resolve({ data: [], error: null }),
  ]);
  for (const result of [stores, profiles, documents]) if (result.error) throw result.error;
  const storesById = new Map((stores.data ?? []).map((item) => [item.id, item]));
  const profilesById = new Map((profiles.data ?? []).map((item) => [item.user_id, item]));
  const docsByRequest = new Map<string, Array<Record<string, unknown>>>();
  for (const document of documents.data ?? []) {
    const list = docsByRequest.get(document.request_id) ?? [];
    list.push(document);
    docsByRequest.set(document.request_id, list);
  }
  return {
    items: requests.map((request) => ({
      ...request,
      store: storesById.get(request.store_id) ?? null,
      merchant: profilesById.get(request.merchant_id) ?? null,
      documents: docsByRequest.get(request.id) ?? [],
    })),
    page,
    pageSize,
    total: result.count ?? 0,
  };
}

export async function getStoreVerificationRequest(session: AdminSession, requestId: string) {
  if (!hasPermission(session, 'verification.read_sensitive')) throw new Error('لا تملك صلاحية قراءة مستندات التوثيق.');
  const service = createServiceSupabaseClient();
  const request = await service.from('store_verification_requests').select('*').eq('id', requestId).maybeSingle();
  if (request.error) throw request.error;
  if (!request.data) throw new Error('طلب التوثيق غير موجود.');
  const documents = await service.from('store_verification_documents').select('id, request_id, store_id, merchant_id, document_type, file_path, file_name, mime_type, byte_size, review_status, review_note, created_at, updated_at').eq('request_id', requestId).order('created_at', { ascending: true });
  if (documents.error) throw documents.error;
  const signedDocuments = await Promise.all((documents.data ?? []).map(async (document) => {
    const signed = await service.storage.from('assalkom_private').createSignedUrl(document.file_path, 600);
    if (signed.error) throw signed.error;
    return { ...document, signed_url: signed.data.signedUrl };
  }));
  return { request: request.data, documents: signedDocuments };
}

export async function reviewStoreVerification(
  session: AdminSession,
  requestId: string,
  action: StoreVerificationReviewAction,
  reviewNote?: string,
  expiresAt?: string | null,
) {
  const permission = action === 'approve' ? 'verification.approve' : action === 'reject' ? 'verification.reject' : 'verification.review';
  if (!hasPermission(session, permission)) throw new Error('لا تملك صلاحية مراجعة توثيق المتجر.');
  const service = createServiceSupabaseClient();
  const result = await service.rpc('admin_review_store_verification', {
    p_request_id: requestId,
    p_action: action,
    ...(reviewNote?.trim() ? { p_review_note: reviewNote.trim() } : {}),
    p_reviewer_id: session.user.id,
    ...(expiresAt ? { p_expires_at: expiresAt } : {}),
  });
  if (result.error) throw result.error;
  await recordAudit(session, {
    action: `store_verification.${action}`,
    entityType: 'store_verification_requests',
    entityId: requestId,
    metadata: { hasReviewNote: Boolean(reviewNote?.trim()), expiresAt: expiresAt ?? null },
  });
  return result.data;
}

export async function reconcileStoreVerificationPayment(
  session: AdminSession,
  requestId: string,
  paymentStatus: StoreVerificationPaymentStatus,
  paymentReference?: string,
  note?: string,
) {
  if (!hasPermission(session, 'verification.review')) {
    throw new Error('لا تملك صلاحية تسوية رسوم توثيق المتجر.');
  }
  const service = createServiceSupabaseClient();
  const result = await service.rpc('admin_set_store_verification_payment', {
    p_request_id: requestId,
    p_payment_status: paymentStatus,
    ...(paymentReference?.trim() ? { p_payment_reference: paymentReference.trim() } : {}),
    ...(note?.trim() ? { p_note: note.trim() } : {}),
    p_reviewer_id: session.user.id,
  });
  if (result.error) throw result.error;
  await recordAudit(session, {
    action: `store_verification.payment.${paymentStatus}`,
    entityType: 'store_verification_requests',
    entityId: requestId,
    metadata: {
      hasPaymentReference: Boolean(paymentReference?.trim()),
      hasNote: Boolean(note?.trim()),
    },
  });
  return result.data;
}

export type SubscriptionPaymentStatus = 'confirmed' | 'failed' | 'refunded' | 'waived' | 'under_review';

export async function listSubscriptionPlans(session: AdminSession) {
  if (!hasPermission(session, 'plans.read')) throw new Error('لا تملك صلاحية قراءة الخطط.');
  const service = createServiceSupabaseClient();
  const result = await service.from('subscription_plans').select('*').order('sort_order', { ascending: true }).order('billing_interval', { ascending: true });
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function listSubscriptionCampaigns(session: AdminSession) {
  if (!hasPermission(session, 'campaigns.manage')) throw new Error('لا تملك صلاحية إدارة الحملات.');
  const service = createServiceSupabaseClient();
  const result = await service.from('subscription_campaigns').select('*').order('created_at', { ascending: false });
  if (result.error) throw result.error;
  return result.data ?? [];
}

export async function updateLaunchCampaign(
  session: AdminSession,
  input: { discountPercent: number | string; isActive: boolean; startsAt?: string | null; endsAt?: string | null; appliesTo?: string[]; discountByPlanCode?: Record<string, number | string> },
) {
  if (!hasPermission(session, 'campaigns.manage')) throw new Error('لا تملك صلاحية إدارة حملة الافتتاح.');
  const parsedDiscount = finiteNumber(input.discountPercent, 'نسبة الخصم', { min: 0 });
  if (parsedDiscount === null || parsedDiscount > 100) throw new Error('نسبة الخصم يجب أن تكون بين 0 و100.');
  const discountPercent = parsedDiscount;
  const discountByPlanCode: Record<string, number> = {};
  for (const [code, value] of Object.entries(input.discountByPlanCode ?? {})) {
    const parsed = finiteNumber(value, `نسبة خصم ${code}`, { min: 0 });
    if (parsed === null || parsed > 100) throw new Error(`نسبة خصم ${code} يجب أن تكون بين 0 و100.`);
    discountByPlanCode[code] = parsed;
  }
  const service = createServiceSupabaseClient();
  const existing = await service.from('subscription_campaigns').select('id, code').eq('code', 'app_launch_2026').maybeSingle();
  if (existing.error) throw existing.error;
  if (!existing.data) throw new Error('حملة الافتتاح غير مهيأة في Production.');
  const updated = await service.from('subscription_campaigns').update({
    discount_percent: discountPercent,
    discount_by_plan_code: discountByPlanCode,
    is_active: Boolean(input.isActive),
    starts_at: input.startsAt ?? null,
    ends_at: input.endsAt ?? null,
    applies_to: input.appliesTo?.length ? input.appliesTo : ['subscription', 'verification'],
    updated_by: session.user.id,
  }).eq('id', existing.data.id).select('*').single();
  if (updated.error) throw updated.error;
  await recordAudit(session, { action: `campaign.app_launch.${input.isActive ? 'activate' : 'deactivate'}`, entityType: 'subscription_campaigns', entityId: updated.data.id, metadata: { discountPercent, discountByPlanCode, startsAt: input.startsAt ?? null, endsAt: input.endsAt ?? null } });
  return updated.data;
}

export async function getLocalTransferSettings(session: AdminSession) {
  if (!hasPermission(session, 'payments.read')) throw new Error('لا تملك صلاحية قراءة إعدادات الحوالة.');
  const service = createServiceSupabaseClient();
  const result = await service.from('local_transfer_settings').select('*').eq('code', 'primary').maybeSingle();
  if (result.error) throw result.error;
  return result.data;
}

export async function updateLocalTransferSettings(session: AdminSession, input: { bankName?: string | null; beneficiaryName?: string | null; accountNumber?: string | null; iban?: string | null; phone?: string | null; instructionsAr?: string | null; logoUrl?: string | null; isActive: boolean }) {
  if (!hasPermission(session, 'payments.manage')) throw new Error('لا تملك صلاحية تعديل إعدادات الحوالة.');
  const service = createServiceSupabaseClient();
  const updated = await service.from('local_transfer_settings').update({ bank_name: input.bankName?.trim() || null, beneficiary_name: input.beneficiaryName?.trim() || null, account_number: input.accountNumber?.trim() || null, iban: input.iban?.trim() || null, phone: input.phone?.trim() || null, instructions_ar: input.instructionsAr?.trim() || null, logo_url: input.logoUrl?.trim() || null, is_active: Boolean(input.isActive), updated_by: session.user.id }).eq('code', 'primary').select('*').single();
  if (updated.error) throw updated.error;
  await recordAudit(session, { action: 'payment.transfer_settings.update', entityType: 'local_transfer_settings', entityId: updated.data.id, metadata: { bankName: updated.data.bank_name, isActive: updated.data.is_active } });
  return updated.data;
}

export async function listPaymentRequests(session: AdminSession, options: QueryOptions = {}) {
  if (!hasPermission(session, 'payments.read')) throw new Error('لا تملك صلاحية قراءة طلبات الدفع.');
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  let query = service.from('payment_requests').select('*, plan:subscription_plans(id, code, name_ar, billing_interval), store:stores(id, name_ar)', { count: 'exact' }).order('created_at', { ascending: false }).range(from, to);
  if (options.search?.trim()) query = query.or(`payment_reference.ilike.%${options.search.trim()}%,sender_name.ilike.%${options.search.trim()}%`);
  const result = await query;
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function getPaymentRequest(session: AdminSession, paymentRequestId: string) {
  if (!hasPermission(session, 'payments.read')) throw new Error('لا تملك صلاحية قراءة طلب الدفع.');
  const service = createServiceSupabaseClient();
  const result = await service.from('payment_requests').select('*, plan:subscription_plans(id, code, name_ar, billing_interval), store:stores(id, name_ar)').eq('id', requireText(paymentRequestId, 'طلب الدفع')).maybeSingle();
  if (result.error) throw result.error;
  if (!result.data) throw new Error('طلب الدفع غير موجود.');
  const events = await service.from('payment_events').select('*').eq('payment_request_id', paymentRequestId).order('created_at', { ascending: false });
  if (events.error) throw events.error;
  let proofUrl: string | null = null;
  if (result.data.proof_path) {
    const signed = await service.storage.from('assalkom_private').createSignedUrl(result.data.proof_path, 600);
    if (signed.error) throw signed.error;
    proofUrl = signed.data.signedUrl;
  }
  return { ...result.data, proof_url: proofUrl, events: events.data ?? [] };
}

export async function reconcilePaymentRequest(session: AdminSession, paymentRequestId: string, status: SubscriptionPaymentStatus, note?: string) {
  if (!hasPermission(session, 'payments.manage')) throw new Error('لا تملك صلاحية تسوية طلب الدفع.');
  const service = createServiceSupabaseClient();
  const result = await service.rpc('admin_reconcile_payment_request', { p_payment_request_id: paymentRequestId, p_status: status, ...(note?.trim() ? { p_note: note.trim() } : {}), p_reviewer_id: session.user.id });
  if (result.error) throw result.error;
  await recordAudit(session, { action: `payment_request.${status}`, entityType: 'payment_requests', entityId: paymentRequestId, metadata: { hasNote: Boolean(note?.trim()) } });
  return result.data;
}

export async function listMerchantSubscriptions(session: AdminSession, options: QueryOptions = {}) {
  if (!hasPermission(session, 'plans.read')) throw new Error('لا تملك صلاحية قراءة الاشتراكات.');
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  const result = await service.from('merchant_subscriptions').select('*, plan:subscription_plans(id, code, name_ar, billing_interval, price_amount, store_limit, product_limit)', { count: 'exact' }).order('created_at', { ascending: false }).range(from, to);
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function setMerchantSubscriptionStatus(session: AdminSession, subscriptionId: string, status: 'active' | 'expired' | 'cancelled' | 'suspended', note?: string) {
  if (!hasPermission(session, 'plans.manage')) throw new Error('لا تملك صلاحية تفعيل الخطط.');
  const service = createServiceSupabaseClient();
  const result = await service.rpc('admin_set_subscription_status', { p_subscription_id: subscriptionId, p_status: status, ...(note?.trim() ? { p_note: note.trim() } : {}), p_reviewer_id: session.user.id });
  if (result.error) throw result.error;
  await recordAudit(session, { action: `subscription.${status}`, entityType: 'merchant_subscriptions', entityId: subscriptionId, metadata: { hasNote: Boolean(note?.trim()) } });
  return result.data;
}

export async function activateSubscriptionForUser(session: AdminSession, merchantId: string, planId: string, note?: string) {
  if (!hasPermission(session, 'plans.manage')) throw new Error('لا تملك صلاحية تفعيل الخطط.');
  const service = createServiceSupabaseClient();
  const result = await service.rpc('admin_activate_subscription_for_user', {
    p_merchant_id: requireText(merchantId, 'المستخدم'),
    p_plan_id: requireText(planId, 'الخطة'),
    ...(note?.trim() ? { p_note: note.trim() } : {}),
    p_reviewer_id: session.user.id,
  });
  if (result.error) throw result.error;
  const activationPayload = result.data && typeof result.data === 'object' && !Array.isArray(result.data) ? result.data as { id?: unknown } : null;
  await recordAudit(session, {
    action: 'subscription.manual_activate',
    entityType: 'merchant_subscriptions',
    entityId: String(activationPayload?.id ?? merchantId),
    metadata: { merchantId, planId, hasNote: Boolean(note?.trim()) },
  });
  return result.data;
}

export async function listDesignRequests(session: AdminSession, options: QueryOptions = {}) {
  if (!hasPermission(session, 'design.read')) throw new Error('لا تملك صلاحية قراءة طلبات التصميم.');
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  const result = await service.from('design_requests').select('*, store:stores(id, name_ar)', { count: 'exact' }).order('created_at', { ascending: false }).range(from, to);
  if (result.error) throw result.error;
  return { items: result.data ?? [], page, pageSize, total: result.count ?? 0 };
}

export async function updateDesignRequest(session: AdminSession, requestId: string, input: { status: string; adminNote?: string | null; assignedAdminId?: string | null }) {
  if (!hasPermission(session, 'design.manage')) throw new Error('لا تملك صلاحية إدارة طلبات التصميم.');
  const allowed = new Set(['draft', 'submitted', 'needs_more_info', 'in_progress', 'ready_for_review', 'completed', 'cancelled']);
  if (!allowed.has(input.status)) throw new Error('حالة طلب التصميم غير صحيحة.');
  const service = createServiceSupabaseClient();
  const updated = await service.from('design_requests').update({ status: input.status, admin_note: input.adminNote?.trim() || null, assigned_admin_id: input.assignedAdminId ?? null, completed_at: input.status === 'completed' ? new Date().toISOString() : null }).eq('id', requestId).select('*').single();
  if (updated.error) throw updated.error;
  await recordAudit(session, { action: `design_request.${input.status}`, entityType: 'design_requests', entityId: requestId, metadata: { hasAdminNote: Boolean(input.adminNote?.trim()) } });
  return updated.data;
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

export function buildProductInsert(input: ProductWriteInput): Database["public"]["Tables"]["products"]["Insert"] {
  const nameAr = requireText(input.nameAr, "اسم المنتج");
  const storeId = requireText(input.storeId, "المتجر");
  const metadata = {
    ...(input.metadata ?? {}),
    ...(input.price === undefined ? {} : { price: input.price === null ? null : String(input.price) }),
    ...(input.currencyCode === undefined ? {} : { currency_code: input.currencyCode }),
  };
  return {
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
  };
}

export async function createProduct(session: AdminSession, input: ProductWriteInput) {
  if (!hasPermission(session, "product.write")) throw new Error("لا تملك صلاحية إنشاء منتج.");
  const service = createServiceSupabaseClient();
  const insert = buildProductInsert(input);
  const created = await service.from("products").insert(insert).select("id, store_id, taxonomy_id, name_ar, name_en, description, product_type, grade_level, status, is_featured, metadata, created_at, updated_at").single();
  if (created.error) throw created.error;
  await recordAudit(session, { action: "product.create", entityType: "products", entityId: created.data.id, metadata: { storeId: insert.store_id, status: input.status ?? "draft" } });
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
  if (patch.status !== undefined && !(ADMIN_PRODUCT_STATUSES as readonly string[]).includes(patch.status)) {
    throw new Error("حالة المنتج غير صحيحة.");
  }
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

export function assertBannerSchedule(startsAt?: string | null, endsAt?: string | null): void {
  if (!startsAt || !endsAt) return;
  const start = new Date(startsAt).getTime();
  const end = new Date(endsAt).getTime();
  if (!Number.isFinite(start) || !Number.isFinite(end)) throw new Error("تاريخ جدولة البانر غير صالح.");
  if (end <= start) throw new Error("يجب أن يكون انتهاء البانر بعد بدايته.");
}

export async function createBanner(session: AdminSession, input: BannerWriteInput) {
  if (!hasPermission(session, "banner.write")) throw new Error("لا تملك صلاحية إنشاء بانر.");
  assertBannerSchedule(input.startsAt, input.endsAt);
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
  if (patch.startsAt !== undefined || patch.endsAt !== undefined) {
    assertBannerSchedule(patch.startsAt ?? null, patch.endsAt ?? null);
  }
  if (patch.sortOrder !== undefined) {
    if (!Number.isFinite(patch.sortOrder) || patch.sortOrder < 0) throw new Error("ترتيب البانر يجب أن يكون رقمًا غير سالب.");
    update.sort_order = patch.sortOrder;
  }
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

export function requireTaxonomyKey(value: string, label: string): string {
  const key = requireText(value, label);
  if (!/^[A-Za-z0-9][A-Za-z0-9_-]*$/.test(key)) throw new Error(`${label} يجب أن يحتوي على أحرف وأرقام و- أو _ فقط.`);
  return key;
}

export async function upsertCategory(session: AdminSession, input: { id?: string; parentId?: string | null; nameAr: string; nameEn?: string | null; slug: string; categoryKind?: string; sortOrder?: number; isActive?: boolean }) {
  if (!hasPermission(session, "taxonomy.manage")) throw new Error("لا تملك صلاحية إدارة التصنيفات.");
  const service = createServiceSupabaseClient();
  const result = await service.from("categories").upsert({
    id: input.id,
    parent_id: input.parentId ?? null,
    name_ar: requireText(input.nameAr, "اسم التصنيف"),
    name_en: input.nameEn ?? null,
    slug: requireTaxonomyKey(input.slug, "slug التصنيف"),
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
    code: requireTaxonomyKey(input.code, "رمز التصنيف"),
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

export async function listUsers(options: QueryOptions = {}) {
  const startedAt = Date.now();
  const { page, pageSize, from, to } = pageOf(options);
  const service = createServiceSupabaseClient();
  const search = options.search?.trim();
  let userQuery = service
    .from("users")
    .select("id, created_at, last_seen_at", { count: "exact" })
    .order("created_at", { ascending: false });
  if (search) {
    const [nameMatches, phoneMatches, authMatches] = await Promise.all([
      service.from("profiles").select("user_id").ilike("display_name", `%${search}%`).limit(1000),
      service.from("profiles").select("user_id").ilike("phone", `%${search}%`).limit(1000),
      service.auth.admin.listUsers({ page: 1, perPage: 1000 }),
    ]);
    if (nameMatches.error) throw nameMatches.error;
    if (phoneMatches.error) throw phoneMatches.error;
    if (authMatches.error) throw authMatches.error;
    const matchingIds = new Set<string>([
      ...(nameMatches.data ?? []).map((row) => row.user_id),
      ...(phoneMatches.data ?? []).map((row) => row.user_id),
      ...authMatches.data.users
        .filter((user) => [user.id, user.email, user.phone, user.user_metadata?.name, user.user_metadata?.display_name].some((value) => typeof value === "string" && value.toLowerCase().includes(search.toLowerCase())))
        .map((user) => user.id),
    ]);
      if (matchingIds.size === 0) {
      logAdminPagination({ resource: "users", page, pageSize, returnedCount: 0, total: 0, startedAt });
      return { items: [], page, pageSize, total: 0 };
    }
    userQuery = userQuery.in("id", Array.from(matchingIds));
  }
  const users = await userQuery.range(from, to);
  if (users.error) throw users.error;
  const userIds = (users.data ?? []).map((user) => user.id);
  const [profiles, applications, stores, identities, memberships, roles] = await Promise.all([
    userIds.length ? service.from("profiles").select("user_id, display_name, phone, avatar_url, bio, locale, role, is_active, created_at, updated_at").in("user_id", userIds) : Promise.resolve({ data: [], error: null }),
    userIds.length ? service.from("merchant_applications").select("id, user_id, status, location, review_note, submitted_at, reviewed_at").in("user_id", userIds).order("submitted_at", { ascending: false }) : Promise.resolve({ data: [], error: null }),
    userIds.length ? service.from("stores").select("id, merchant_id, name_ar, status, is_verified, updated_at").in("merchant_id", userIds) : Promise.resolve({ data: [], error: null }),
    service.auth.admin.listUsers({ page: 1, perPage: 1000 }),
    userIds.length ? service.from("admin_users").select("user_id, role_id, is_active, scope, created_at, updated_at").in("user_id", userIds) : Promise.resolve({ data: [], error: null }),
    service.from("admin_roles").select("id, code, name_ar").limit(50),
  ]);
  if (profiles.error) throw profiles.error;
  if (applications.error) throw applications.error;
  if (stores.error) throw stores.error;
  if (identities.error) throw identities.error;
  if (memberships.error) throw memberships.error;
  if (roles.error) throw roles.error;
  const profileByUserId = new Map((profiles.data ?? []).map((profile) => [profile.user_id, profile]));
  const applicationByUserId = new Map((applications.data ?? []).map((application) => [application.user_id, application]));
  const storeByMerchantId = new Map((stores.data ?? []).map((store) => [store.merchant_id, store]));
  const roleById = new Map((roles.data ?? []).map((role) => [role.id, role]));
  const membershipByUserId = new Map((memberships.data ?? []).map((membership) => [membership.user_id, { ...membership, role: roleById.get(membership.role_id) ?? null }]));
  const identityByUserId = new Map(identities.data.users.map((user) => [user.id, user]));
  const items = (users.data ?? []).map((user) => {
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
      adminMembership: membershipByUserId.get(user.id) ?? null,
      networkTelemetry: buildAdminNetworkTelemetry(),
    };
  });
  logAdminPagination({ resource: "users", page, pageSize, returnedCount: items.length, total: users.count ?? 0, startedAt });
  return { items, page, pageSize, total: users.count ?? 0 };
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

const SENSITIVE_NOTIFICATION_KEYS = new Set([
  "email",
  "phone",
  "contact_phone",
  "contactphone",
  "sender_phone",
  "senderphone",
  "sender_name",
  "sendername",
  "payment_reference",
  "paymentreference",
  "proof_path",
  "proofpath",
  "proof_file_name",
  "prooffilename",
  "proof_mime_type",
  "proofmimetype",
  "proof_byte_size",
  "proofbytesize",
  "account_number",
  "accountnumber",
  "iban",
  "bank_account",
  "bankaccount",
]);

function isSensitiveNotificationKey(key: string): boolean {
  return SENSITIVE_NOTIFICATION_KEYS.has(key.trim().toLowerCase().replace(/-/g, "_"));
}

function redactNotificationValue(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(redactNotificationValue);
  if (!value || typeof value !== "object") return value;
  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>)
      .filter(([key]) => !isSensitiveNotificationKey(key))
      .map(([key, child]) => [key, redactNotificationValue(child)]),
  );
}

export function buildAdminNotificationPayload(input: { payload?: Record<string, unknown>; imageUrl?: string | null }): Json {
  return redactNotificationValue({
    ...(input.payload ?? {}),
    ...(input.imageUrl?.trim() ? { image_url: input.imageUrl.trim() } : {}),
  }) as Json;
}

export async function sendNotification(session: AdminSession, input: { userId?: string | null; broadcast?: boolean; titleAr: string; bodyAr?: string | null; notificationType?: string; imageUrl?: string | null; payload?: Record<string, unknown> }) {
  if (!hasPermission(session, "notification.write")) throw new Error("لا تملك صلاحية إرسال إشعار.");
  const titleAr = requireText(input.titleAr, "عنوان الإشعار");
  const service = createServiceSupabaseClient();
  const broadcast = input.broadcast === true;
  const recipientIds: string[] = [];
  if (broadcast) {
    const pageSize = 1000;
    for (let from = 0; ; from += pageSize) {
      const usersResult = await service.from("users").select("id").order("id", { ascending: true }).range(from, from + pageSize - 1);
      if (usersResult.error) throw usersResult.error;
      const ids = (usersResult.data ?? []).map((user) => user.id);
      recipientIds.push(...ids);
      if (ids.length < pageSize) break;
    }
  } else {
    const userId = requireText(input.userId, "المستخدم");
    const target = await service.from("users").select("id").eq("id", userId).maybeSingle();
    if (target.error) throw target.error;
    if (!target.data) throw new Error("المستخدم المستهدف غير موجود في Production.");
    recipientIds.push(target.data.id);
  }
  if (!recipientIds.length) throw new Error("لا يوجد مستخدمون مستهدفون في Production.");
  const payload = buildAdminNotificationPayload(input);
  const rows = recipientIds.map((userId) => ({
    user_id: userId,
    title_ar: titleAr,
    body_ar: input.bodyAr?.trim() || null,
    notification_type: input.notificationType?.trim() || (broadcast ? "admin_broadcast" : "admin_message"),
    payload,
  }));
  const insertedItems: Array<Database["public"]["Tables"]["notifications"]["Row"]> = [];
  const insertBatchSize = 500;
  for (let from = 0; from < rows.length; from += insertBatchSize) {
    const inserted = await service.from("notifications").insert(rows.slice(from, from + insertBatchSize)).select("id, user_id, notification_type, title_ar, body_ar, payload, read_at, created_at");
    if (inserted.error) throw inserted.error;
    insertedItems.push(...(inserted.data ?? []));
  }
  await recordAudit(session, {
    action: broadcast ? "notification.broadcast" : "notification.create",
    entityType: "notifications",
    entityId: null,
    metadata: { recipientCount: insertedItems.length, userId: broadcast ? null : recipientIds[0], imageUrl: input.imageUrl?.trim() || null },
  });
  return { broadcast, recipientCount: insertedItems.length, items: insertedItems };
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
  await recordAudit(session, { action: "admin_user.create", entityType: "admin_users", entityId: identity.data.user.id, metadata: { roleCode } });
  return { email, temporaryPassword: password, membership: membership.data, role: role.data };
}
