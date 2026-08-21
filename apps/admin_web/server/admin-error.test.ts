import { describe, expect, it } from "vitest";
import { buildAdminErrorResponse } from "./admin-error";

describe("admin error response contract", () => {
  it("maps permission denial 42501 to an actionable Arabic 403 without exposing raw database text", () => {
    const result = buildAdminErrorResponse({ code: "42501", message: "permission denied for schema private" });
    expect(result.status).toBe(403);
    expect(result.payload.error).toBe("42501");
    expect(result.payload.messageAr).toContain("صلاحيات");
    expect(result.payload.messageAr).not.toContain("private");
  });

  it("maps unique and foreign-key violations to actionable client errors", () => {
    expect(buildAdminErrorResponse({ code: "23505", message: "duplicate key" }).status).toBe(409);
    expect(buildAdminErrorResponse({ code: "23503", message: "foreign key" }).status).toBe(409);
    expect(buildAdminErrorResponse({ code: "23514", message: "check failed" }).status).toBe(400);
  });

  it("maps missing rows and preserves a safe Arabic application error", () => {
    const missing = buildAdminErrorResponse({ code: "PGRST116", message: "JSON object requested" });
    expect(missing.status).toBe(404);
    expect(missing.payload.messageAr).toContain("غير موجود");
    const appError = buildAdminErrorResponse(new Error("اسم المنتج مطلوب"));
    expect(appError.status).toBe(500);
    expect(appError.payload.messageAr).toBe("اسم المنتج مطلوب");
  });

  it("does not expose an unknown non-Arabic infrastructure message when no safe mapping exists", () => {
    const result = buildAdminErrorResponse({ code: "unexpected", message: "internal database password=secret" });
    expect(result.status).toBe(500);
    expect(result.payload.error).toBe("unexpected");
    expect(result.payload.messageAr).toBe("تعذر تنفيذ العملية الإدارية الآن.");
    expect(result.payload.messageAr).not.toContain("secret");
  });
});
