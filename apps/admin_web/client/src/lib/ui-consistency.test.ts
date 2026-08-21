import { describe, expect, it } from "vitest";
import {
  adminAuditActionLabel,
  adminAuditEntityLabel,
  adminProductTypeLabel,
  adminStatusMeta,
} from "./ui-consistency";

describe("shared UI consistency vocabulary", () => {
  it("uses the same Arabic status semantics across store and generic contexts", () => {
    expect(adminStatusMeta("active", "store").label).toBe("مفعّل");
    expect(adminStatusMeta("active", "generic").label).toBe("نشط");
    expect(adminStatusMeta("in_progress", "request").label).toBe("قيد المتابعة");
    expect(adminStatusMeta("approved", "merchantApplication").label).toBe("مفعّل — المتجر نشط");
  });

  it("never exposes an unknown wire status as visible UI text", () => {
    const meta = adminStatusMeta("future_backend_status", "store");
    expect(meta.label).toBe("حالة غير معروفة");
    expect(meta.label).not.toContain("future_backend_status");
  });

  it("maps product wire values to the customer vocabulary", () => {
    expect(adminProductTypeLabel("honey")).toBe("عسل");
    expect(adminProductTypeLabel("gift")).toBe("هدية");
    expect(adminProductTypeLabel("future_type")).toBe("نوع غير محدد");
  });

  it("maps known audit events and redacts unknown technical names", () => {
    expect(adminAuditActionLabel("store.approve")).toBe("اعتماد متجر");
    expect(adminAuditEntityLabel("merchant_applications")).toBe("طلبات التجار");
    expect(adminAuditActionLabel("future.action")).toBe("إجراء إداري");
    expect(adminAuditEntityLabel("future_table")).toBe("كيان إداري");
  });
});
