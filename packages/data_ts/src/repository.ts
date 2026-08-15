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

export type AssalDataSourceMode = "demo" | "production";

export interface AssalProductQuery {
  categoryId?: string;
  storeId?: string;
  search?: string;
  featuredOnly?: boolean;
}

export interface AssalRepository {
  readonly mode: AssalDataSourceMode;
  listRegions(): Promise<AssalLoadState<AssalRegion[]>>;
  listTaxonomy(): Promise<AssalLoadState<AssalTaxonomy[]>>;
  listStores(regionId?: string): Promise<AssalLoadState<AssalStoreSummary[]>>;
  listProducts(query?: AssalProductQuery): Promise<AssalLoadState<AssalProductSummary[]>>;
  getProduct(productId: string): Promise<AssalLoadState<AssalProductSummary>>;
  listReviews(productId: string): Promise<AssalLoadState<AssalReviewSummary[]>>;
  listRequests(requesterId: string): Promise<AssalLoadState<AssalRequestSummary[]>>;
  listNotifications(userId: string): Promise<AssalLoadState<AssalNotificationSummary[]>>;
}

export interface ProductionSelectGateway {
  select(table: string, filters?: Record<string, unknown>): Promise<Record<string, unknown>[]>;
}

export class ProductionRepositoryNotConfigured extends Error {
  constructor() {
    super("Production repository requires an explicit Supabase gateway configuration.");
    this.name = "ProductionRepositoryNotConfigured";
  }
}
