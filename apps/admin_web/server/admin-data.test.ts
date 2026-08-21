import { describe, expect, it } from "vitest";
import { ADMIN_NETWORK_TELEMETRY_UNAVAILABLE, ADMIN_PRODUCT_STATUSES, STORE_MODERATION_ACTIONS, assertBannerSchedule, assertUserDeletionAllowed, buildAdminNetworkTelemetry, buildAdminNotificationPayload, buildAdminPaginationTelemetry, buildAuditEntry, buildProductInsert, decodePublicImageInput, MAX_PUBLIC_IMAGE_BYTES, requireTaxonomyKey, sanitizeStoragePurpose, storeModerationPermission } from "./admin-data";

describe("admin product draft payload", () => {
  it("builds a draft payload with store, taxonomy, price, currency, and metadata", () => {
    const insert = buildProductInsert({
      storeId: "store-1",
      taxonomyId: "taxonomy-sidr",
      nameAr: "عسل سدر",
      nameEn: "Sidr Honey",
      description: "وصف المنتج",
      productType: "honey",
      gradeLevel: 1,
      isFeatured: false,
      status: "draft",
      price: 35,
      currencyCode: "SAR",
      metadata: { origin_country: "اليمن", tags: ["سدر"] },
    });

    expect(insert).toMatchObject({
      store_id: "store-1",
      taxonomy_id: "taxonomy-sidr",
      name_ar: "عسل سدر",
      status: "draft",
      is_featured: false,
    });
    expect(insert.metadata).toMatchObject({
      origin_country: "اليمن",
      price: "35",
      currency_code: "SAR",
    });
  });

  it("rejects an empty store or product name before reaching Storage/DB", () => {
    expect(() => buildProductInsert({ storeId: "", nameAr: "عسل" })).toThrow("المتجر مطلوب");
    expect(() => buildProductInsert({ storeId: "store-1", nameAr: "   " })).toThrow("اسم المنتج مطلوب");
  });
});

describe("admin product status contract", () => {
  it("keeps the Admin status vocabulary aligned with the mobile domain", () => {
    expect(ADMIN_PRODUCT_STATUSES).toEqual(["draft", "pending", "active", "paused", "rejected"]);
    expect(ADMIN_PRODUCT_STATUSES).not.toContain("archived");
  });
});

describe("admin store moderation contract", () => {
  it("covers every moderation action and uses an existing least-privilege permission", () => {
    expect(STORE_MODERATION_ACTIONS).toEqual(["approve", "reject", "suspend", "reactivate"]);
    expect(storeModerationPermission("approve")).toBe("store.approve");
    expect(storeModerationPermission("reactivate")).toBe("store.approve");
    expect(storeModerationPermission("reject")).toBe("store.reject");
    expect(storeModerationPermission("suspend")).toBe("store.suspend");
  });
});

describe("admin user deletion guard", () => {
  it("rejects deleting the current admin and any admin membership", () => {
    expect(() => assertUserDeletionAllowed("admin-1", "admin-1", false)).toThrow("لا يمكن حذف الهوية الإدارية الحالية");
    expect(() => assertUserDeletionAllowed("admin-1", "user-2", true)).toThrow("لا يُحذف مدير إداري");
    expect(() => assertUserDeletionAllowed("admin-1", "user-2", false)).not.toThrow();
  });
});

describe("admin telemetry contract", () => {
  it("does not invent an IP or last-active value when Production does not store telemetry", () => {
    expect(buildAdminNetworkTelemetry()).toEqual({ ipAddress: null, noteAr: ADMIN_NETWORK_TELEMETRY_UNAVAILABLE });
    expect(buildAdminNetworkTelemetry().ipAddress).toBeNull();
  });
});

describe("admin pagination telemetry contract", () => {
  it("records page, bounded page size, result count, total, and non-negative elapsed time", () => {
    const result = buildAdminPaginationTelemetry({
      resource: "users",
      page: 2,
      pageSize: 50,
      returnedCount: 7,
      total: 57,
      startedAt: Date.now() - 20,
    });
    expect(result.resource).toBe("users");
    expect(result.page).toBe(2);
    expect(result.pageSize).toBe(50);
    expect(result.returnedCount).toBe(7);
    expect(result.total).toBe(57);
    expect(result.elapsedMs).toBeGreaterThanOrEqual(0);
  });
});

describe("admin audit entry contract", () => {
  it("contains actor, action, entity, and metadata without inventing success fields", () => {
    const entry = buildAuditEntry({ user: { id: "admin-1" } } as never, {
      action: "product.delete",
      entityType: "products",
      entityId: "product-1",
      metadata: { deleted: true, storeId: "store-1" },
    });
    expect(entry).toEqual({
      actor_user_id: "admin-1",
      action: "product.delete",
      entity_type: "products",
      entity_id: "product-1",
      metadata: { deleted: true, storeId: "store-1" },
    });
    expect(() => buildAuditEntry({ user: { id: "" } } as never, { action: "x", entityType: "y" })).toThrow("هوية إدارية");
  });

  it("redacts sensitive values while preserving presence flags", () => {
    const entry = buildAuditEntry({ user: { id: "admin-1" } } as never, {
      action: "payment_request.confirmed",
      entityType: "payment_requests",
      entityId: "payment-1",
      metadata: {
        email: "owner@example.com",
        phone: "+967700000000",
        paymentReference: "BANK-REF-123",
        note: "نص قد يحتوي بيانات حساسة",
        proofPath: "customer/proof.pdf",
        safe: "kept",
      },
    });
    expect(entry.metadata).toEqual({
      hasEmail: true,
      hasPhone: true,
      hasPaymentReference: true,
      hasNote: true,
      hasProofPath: true,
      safe: "kept",
    });
  });
});

describe("admin taxonomy key contract", () => {
  it("accepts seeded code/slug shapes and rejects whitespace or unsupported punctuation", () => {
    expect(requireTaxonomyKey("CAT-001", "رمز التصنيف")).toBe("CAT-001");
    expect(requireTaxonomyKey("catalog-sub-sidr", "slug التصنيف")).toBe("catalog-sub-sidr");
    expect(() => requireTaxonomyKey("CAT 001", "رمز التصنيف")).toThrow("أحرف وأرقام");
    expect(() => requireTaxonomyKey("slug/invalid", "slug التصنيف")).toThrow("أحرف وأرقام");
  });
});

describe("admin banner schedule contract", () => {
  it("rejects an end before or equal to the start and accepts open-ended schedules", () => {
    expect(() => assertBannerSchedule("2026-08-20T10:00:00Z", "2026-08-20T09:00:00Z")).toThrow("انتهاء البانر بعد بدايته");
    expect(() => assertBannerSchedule("2026-08-20T10:00:00Z", "2026-08-20T10:00:00Z")).toThrow("انتهاء البانر بعد بدايته");
    expect(() => assertBannerSchedule("2026-08-20T10:00:00Z", "2026-08-20T11:00:00Z")).not.toThrow();
    expect(() => assertBannerSchedule("2026-08-20T10:00:00Z", null)).not.toThrow();
  });
});

describe("admin notification payload contract", () => {
  it("preserves custom payload fields and adds only a trimmed image_url when provided", () => {
    expect(buildAdminNotificationPayload({ payload: { screen: "home", store_id: "store-1" }, imageUrl: "  https://cdn.example/notice.webp  " })).toEqual({ screen: "home", store_id: "store-1", image_url: "https://cdn.example/notice.webp" });
    expect(buildAdminNotificationPayload({ payload: { screen: "home" }, imageUrl: "  " })).toEqual({ screen: "home" });
  });
});

describe("public image input validation", () => {
  it("decodes a data URL and strips whitespace before the storage write", () => {
    const result = decodePublicImageInput({
      contentType: " IMAGE/PNG ",
      base64: "data:image/png;base64, iVBORw0KGg\noAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII= ",
    });

    expect(result.contentType).toBe("image/png");
    expect(result.extension).toBe("png");
    expect(result.bytes.subarray(0, 8)).toEqual(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]));
  });

  it("accepts SVG because the Production public bucket allows it", () => {
    const result = decodePublicImageInput({
      contentType: "image/svg+xml",
      base64: "PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciLz4=",
    });

    expect(result.extension).toBe("svg");
    expect(result.bytes.length).toBeGreaterThan(0);
  });

  it("rejects GIF because the Production public bucket does not allow it", () => {
    expect(() =>
      decodePublicImageInput({ contentType: "image/gif", base64: "R0lGODlh" }),
    ).toThrow("نوع الصورة غير مدعوم");
  });

  it("rejects malformed base64 before reaching Storage", () => {
    expect(() =>
      decodePublicImageInput({ contentType: "image/png", base64: "not base64?" }),
    ).toThrow("بيانات الصورة المشفرة غير صالحة");
  });

  it("rejects empty payloads", () => {
    expect(() =>
      decodePublicImageInput({ contentType: "image/png", base64: "" }),
    ).toThrow("بيانات الصورة المشفرة غير صالحة");
  });

  it("rejects payloads larger than the public bucket limit", () => {
    const bytes = Buffer.alloc(MAX_PUBLIC_IMAGE_BYTES + 1, 1);
    expect(() =>
      decodePublicImageInput({
        contentType: "image/jpeg",
        base64: bytes.toString("base64"),
      }),
    ).toThrow("10 ميجابايت");
  });

  it("rejects a valid payload whose bytes do not match the declared MIME", () => {
    expect(() =>
      decodePublicImageInput({
        contentType: "image/png",
        base64: "2vv8aGVsbG8=",
      }),
    ).toThrow("توقيع الملف");
  });

  it("sanitizes traversal and separators out of the generated purpose prefix", () => {
    const purpose = sanitizeStoragePurpose("../private/..\\proof secrets");
    expect(purpose).not.toContain("/");
    expect(purpose).not.toContain("\\\\");
    expect(purpose).not.toContain("..");
    expect(purpose).toMatch(/^-+private-+proof-secrets$/);
  });
});
