import type {
  AssalLoadState,
  AssalNotificationSummary,
  AssalProductSummary,
  AssalRegion,
  AssalRequestSummary,
  AssalReviewSummary,
  AssalStoreSummary,
  AssalTaxonomy,
} from "../../contracts_ts/src/domain";
import type { AssalProductQuery, AssalRepository, ProductionSelectGateway } from "./repository";

const empty = <T>(messageAr: string): AssalLoadState<T> => ({ kind: "empty", messageAr });
const data = <T>(value: T): AssalLoadState<T> => ({ kind: "data", value });
const text = (value: unknown): string => typeof value === "string" ? value : "";
const nullableText = (value: unknown): string | null => typeof value === "string" ? value : null;
const numberValue = (value: unknown): number => typeof value === "number" ? value : 0;

export class ProductionRepository implements AssalRepository {
  readonly mode = "production" as const;

  constructor(private readonly gateway: ProductionSelectGateway) {}

  async listRegions(): Promise<AssalLoadState<AssalRegion[]>> {
    const rows = await this.gateway.select("regions", { is_active: true });
    const values = rows.map((row) => ({ id: text(row.id), nameAr: text(row.name_ar), nameEn: nullableText(row.name_en), code: nullableText(row.code), parentRegionId: nullableText(row.parent_region_id), isActive: row.is_active !== false }));
    return values.length ? data(values) : empty("لا توجد مناطق متاحة");
  }

  async listTaxonomy(): Promise<AssalLoadState<AssalTaxonomy[]>> {
    const rows = await this.gateway.select("honey_taxonomy", { is_active: true });
    const values = rows.map((row) => ({ id: text(row.id), code: text(row.code), nameAr: text(row.name_ar), nameEn: nullableText(row.name_en), description: nullableText(row.description), metadata: (row.metadata as Record<string, unknown> | undefined) ?? {} }));
    return values.length ? data(values) : empty("لا توجد تصنيفات متاحة");
  }

  async listStores(regionId?: string): Promise<AssalLoadState<AssalStoreSummary[]>> {
    const rows = await this.gateway.select("stores", { status: "active", ...(regionId ? { region_id: regionId } : {}) });
    const values = rows.map((row) => ({ id: text(row.id), merchantId: text(row.merchant_id), nameAr: text(row.name_ar), slug: text(row.slug), description: nullableText(row.description), regionId: nullableText(row.region_id), logoUrl: nullableText(row.logo_url), coverUrl: nullableText(row.cover_url), isVerified: row.is_verified === true, status: text(row.status) as AssalStoreSummary["status"], ratingAverage: numberValue(row.rating_average), reviewCount: numberValue(row.review_count), followersCount: numberValue(row.followers_count) }));
    return values.length ? data(values) : empty("لا توجد متاجر متاحة");
  }

  async listProducts(query: AssalProductQuery = {}): Promise<AssalLoadState<AssalProductSummary[]>> {
    const rows = await this.gateway.select("products", { status: "active", ...(query.storeId ? { store_id: query.storeId } : {}) });
    const search = query.search?.trim().toLowerCase();
    const values = rows
      .filter((row) => !query.featuredOnly || row.is_featured === true)
      .filter((row) => !search || text(row.name_ar).toLowerCase().includes(search))
      .map((row) => this.product(row));
    return values.length ? data(values) : empty("لا توجد منتجات مطابقة للبحث");
  }

  async getProduct(productId: string): Promise<AssalLoadState<AssalProductSummary>> {
    const rows = await this.gateway.select("products", { id: productId, status: "active" });
    return rows.length ? data(this.product(rows[0])) : { kind: "error", messageAr: "المنتج غير موجود", code: "not_found" };
  }

  async listReviews(productId: string): Promise<AssalLoadState<AssalReviewSummary[]>> {
    const rows = await this.gateway.select("reviews", { product_id: productId, status: "approved" });
    const values = rows.map((row) => ({ id: text(row.id), productId: text(row.product_id), storeId: text(row.store_id), authorId: text(row.author_id), rating: numberValue(row.rating), status: text(row.status) as AssalReviewSummary["status"], body: nullableText(row.body), createdAt: nullableText(row.created_at) }));
    return values.length ? data(values) : empty("لا توجد مراجعات بعد");
  }

  async listRequests(requesterId: string): Promise<AssalLoadState<AssalRequestSummary[]>> {
    const rows = await this.gateway.select("requests", { requester_id: requesterId });
    const values = rows.map((row) => ({ id: text(row.id), requesterId: text(row.requester_id), storeId: text(row.store_id), subject: text(row.subject), status: text(row.status) as AssalRequestSummary["status"], body: nullableText(row.body), preferredHandoffOption: nullableText(row.preferred_handoff_option), createdAt: nullableText(row.created_at) }));
    return values.length ? data(values) : empty("لا توجد طلبات تواصل");
  }

  async listNotifications(userId: string): Promise<AssalLoadState<AssalNotificationSummary[]>> {
    const rows = await this.gateway.select("notifications", { user_id: userId });
    const values = rows.map((row) => ({ id: text(row.id), userId: text(row.user_id), notificationType: text(row.notification_type), titleAr: text(row.title_ar), bodyAr: nullableText(row.body_ar), payload: (row.payload as Record<string, unknown> | undefined) ?? {}, readAt: nullableText(row.read_at) }));
    return values.length ? data(values) : empty("لا توجد إشعارات جديدة");
  }

  private product(row: Record<string, unknown>): AssalProductSummary {
    return { id: text(row.id), storeId: text(row.store_id), nameAr: text(row.name_ar), nameEn: nullableText(row.name_en), description: nullableText(row.description), productType: text(row.product_type) as AssalProductSummary["productType"], status: text(row.status) as AssalProductSummary["status"], taxonomyId: nullableText(row.taxonomy_id), gradeLevel: typeof row.grade_level === "number" ? row.grade_level : null, isFeatured: row.is_featured === true, primaryImageUrl: nullableText(row.primary_image_url), ratingAverage: numberValue(row.rating_average), reviewCount: numberValue(row.review_count) };
  }
}
