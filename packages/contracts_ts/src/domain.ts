import type { Database } from "./database";

export type AssalRole = "customer" | "merchant" | "admin";
export type ProductType = "honey" | "wax" | "mix" | "raw" | "gift";
export type ProductStatus = "draft" | "pending" | "active" | "paused" | "rejected";
export type StoreStatus = "pending" | "active" | "paused" | "rejected" | "suspended";
export type VerificationStatus = "pending" | "verified" | "rejected" | "suspended";
export type ReviewStatus = "pending" | "approved" | "rejected" | "hidden";
export type RequestStatus = "open" | "in_progress" | "answered" | "closed" | "cancelled";

export interface AssalRegion {
  id: string;
  nameAr: string;
  nameEn: string | null;
  code: string | null;
  parentRegionId: string | null;
  isActive: boolean;
}

export interface AssalTaxonomy {
  id: string;
  code: string;
  nameAr: string;
  nameEn: string | null;
  description: string | null;
  metadata: Record<string, unknown>;
}

export interface AssalStoreSummary {
  id: string;
  merchantId: string;
  nameAr: string;
  slug: string;
  description: string | null;
  regionId: string | null;
  logoUrl: string | null;
  coverUrl: string | null;
  isVerified: boolean;
  status: StoreStatus;
  ratingAverage: number;
  reviewCount: number;
  followersCount: number;
}

export interface AssalProductSummary {
  id: string;
  storeId: string;
  nameAr: string;
  nameEn: string | null;
  description: string | null;
  productType: ProductType;
  status: ProductStatus;
  taxonomyId: string | null;
  gradeLevel: number | null;
  isFeatured: boolean;
  primaryImageUrl: string | null;
  ratingAverage: number;
  reviewCount: number;
}

export interface AssalReviewSummary {
  id: string;
  productId: string;
  storeId: string;
  authorId: string;
  rating: number;
  status: ReviewStatus;
  body: string | null;
  createdAt: string | null;
}

export interface AssalRequestSummary {
  id: string;
  requesterId: string;
  storeId: string;
  subject: string;
  status: RequestStatus;
  body: string | null;
  preferredHandoffOption: string | null;
  createdAt: string | null;
}

export interface AssalNotificationSummary {
  id: string;
  userId: string;
  notificationType: string;
  titleAr: string;
  bodyAr: string | null;
  payload: Record<string, unknown>;
  readAt: string | null;
}

export type AssalLoadState<T> =
  | { kind: "loading" }
  | { kind: "data"; value: T }
  | { kind: "empty"; messageAr: string }
  | { kind: "error"; messageAr: string; code?: string };

export type DatabaseRow<TableName extends keyof Database["public"]["Tables"]> = Database["public"]["Tables"][TableName]["Row"];
