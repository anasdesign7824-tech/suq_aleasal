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
import type { AssalProductQuery, AssalRepository } from "./repository";

export interface DemoCatalog {
  regions: Array<Record<string, unknown>>;
  stores: Array<Record<string, unknown>>;
  products: Array<Record<string, unknown>>;
  reviews: Array<Record<string, unknown>>;
  requests: Array<Record<string, unknown>>;
  notifications: Array<Record<string, unknown>>;
}

const empty = <T>(messageAr: string): AssalLoadState<T> => ({ kind: "empty", messageAr });
const data = <T>(value: T): AssalLoadState<T> => ({ kind: "data", value });

const asString = (value: unknown): string => typeof value === "string" ? value : "";
const asNullableString = (value: unknown): string | null => typeof value === "string" ? value : null;
const asNumber = (value: unknown): number => typeof value === "number" ? value : 0;
const asBoolean = (value: unknown): boolean => value === true;

export class DemoRepository implements AssalRepository {
  readonly mode = "demo" as const;

  constructor(private readonly catalog: DemoCatalog) {}

  async listRegions(): Promise<AssalLoadState<AssalRegion[]>> {
    const values = this.catalog.regions.map((row) => ({
      id: asString(row.id),
      nameAr: asString(row.name_ar),
      nameEn: asNullableString(row.name_en),
      code: asNullableString(row.code),
      parentRegionId: asNullableString(row.parent_region_id),
      isActive: row.is_active !== false,
    }));
    return values.length ? data(values) : empty("لا توجد مناطق تجريبية متاحة");
  }

  async listTaxonomy(): Promise<AssalLoadState<AssalTaxonomy[]>> {
    const seen = new Set<string>();
    const values: AssalTaxonomy[] = [];
    for (const row of this.catalog.products) {
      const id = asNullableString(row.subcategory_id);
      if (!id || seen.has(id)) continue;
      seen.add(id);
      values.push({ id, code: id, nameAr: asString(row.subcategory_name_ar), nameEn: null, description: null, metadata: {} });
    }
    return values.length ? data(values) : empty("لا توجد تصنيفات تجريبية");
  }

  async listStores(regionId?: string): Promise<AssalLoadState<AssalStoreSummary[]>> {
    const values = this.catalog.stores
      .filter((row) => !regionId || row.region_id === regionId)
      .map((row) => ({
        id: asString(row.id), merchantId: asString(row.merchant_id), nameAr: asString(row.name_ar), slug: asString(row.slug),
        description: asNullableString(row.description), regionId: asNullableString(row.region_id), logoUrl: asNullableString(row.logo_url),
        coverUrl: asNullableString(row.cover_url), isVerified: asBoolean(row.is_verified), status: asString(row.status) as AssalStoreSummary["status"],
        ratingAverage: asNumber(row.rating_average), reviewCount: asNumber(row.review_count), followersCount: asNumber(row.followers_count),
      }));
    return values.length ? data(values) : empty("لا توجد متاجر ضمن هذا الاختيار");
  }

  async listProducts(query: AssalProductQuery = {}): Promise<AssalLoadState<AssalProductSummary[]>> {
    const search = query.search?.trim().toLowerCase();
    const values = this.catalog.products
      .filter((row) => !query.categoryId || row.category_id === query.categoryId)
      .filter((row) => !query.storeId || row.store_id === query.storeId)
      .filter((row) => !query.featuredOnly || row.is_featured === true)
      .filter((row) => !search || asString(row.name_ar).toLowerCase().includes(search))
      .map((row) => this.product(row));
    return values.length ? data(values) : empty("لا توجد منتجات مطابقة للبحث");
  }

  async getProduct(productId: string): Promise<AssalLoadState<AssalProductSummary>> {
    const row = this.catalog.products.find((item) => item.id === productId);
    return row ? data(this.product(row)) : { kind: "error", messageAr: "المنتج غير موجود في البيانات التجريبية", code: "not_found" };
  }

  async listReviews(productId: string): Promise<AssalLoadState<AssalReviewSummary[]>> {
    const values = this.catalog.reviews.filter((row) => row.product_id === productId).map((row) => ({
      id: asString(row.id), productId: asString(row.product_id), storeId: asString(row.store_id), authorId: asString(row.author_id),
      rating: asNumber(row.rating), status: asString(row.status) as AssalReviewSummary["status"], body: asNullableString(row.body), createdAt: asNullableString(row.created_at),
    }));
    return values.length ? data(values) : empty("لا توجد مراجعات بعد");
  }

  async listRequests(requesterId: string): Promise<AssalLoadState<AssalRequestSummary[]>> {
    const values = this.catalog.requests.filter((row) => row.requester_id === requesterId).map((row) => ({
      id: asString(row.id), requesterId: asString(row.requester_id), storeId: asString(row.store_id), subject: asString(row.subject),
      status: asString(row.status) as AssalRequestSummary["status"], body: asNullableString(row.body), preferredHandoffOption: asNullableString(row.preferred_handoff_option), createdAt: asNullableString(row.created_at),
    }));
    return values.length ? data(values) : empty("لا توجد طلبات تواصل");
  }

  async listNotifications(userId: string): Promise<AssalLoadState<AssalNotificationSummary[]>> {
    const values = this.catalog.notifications.filter((row) => row.user_id === userId).map((row) => ({
      id: asString(row.id), userId: asString(row.user_id), notificationType: asString(row.notification_type), titleAr: asString(row.title_ar),
      bodyAr: asNullableString(row.body_ar), payload: (row.payload as Record<string, unknown> | undefined) ?? {}, readAt: asNullableString(row.read_at),
    }));
    return values.length ? data(values) : empty("لا توجد إشعارات جديدة");
  }

  private product(row: Record<string, unknown>): AssalProductSummary {
    return {
      id: asString(row.id), storeId: asString(row.store_id), nameAr: asString(row.name_ar), nameEn: asNullableString(row.name_en),
      description: asNullableString(row.description), productType: asString(row.product_type) as AssalProductSummary["productType"],
      status: asString(row.status) as AssalProductSummary["status"], taxonomyId: asNullableString(row.subcategory_id),
      gradeLevel: Array.isArray(row.grade_levels) && typeof row.grade_levels[0] === "number" ? row.grade_levels[0] : null,
      isFeatured: asBoolean(row.is_featured), primaryImageUrl: asNullableString(row.primary_image_url), ratingAverage: asNumber(row.rating_average), reviewCount: asNumber(row.review_count),
    };
  }
}
