import { describe, expect, it } from "vitest";
import { hasPermission, type AdminSession } from "./admin-auth";

const session = (code: string, permissions: Record<string, boolean>): AdminSession => ({
  accessToken: "test-access-token",
  user: { id: "admin-id", email: "admin@example.com", user_metadata: {} },
  role: { id: "role-id", code, nameAr: "مدير", permissions },
});

describe("admin permission boundary", () => {
  it("allows an explicit permission", () => {
    expect(hasPermission(session("admin", { "store.read": true }), "store.read")).toBe(true);
  });

  it("denies an unrelated permission", () => {
    expect(hasPermission(session("admin", { "store.read": true }), "store.approve")).toBe(false);
  });

  it("allows super_admin through the server-side role boundary", () => {
    expect(hasPermission(session("super_admin", {}), "admin.manage")).toBe(true);
  });

  it("allows the explicit all permission only for the assigned role", () => {
    expect(hasPermission(session("admin", { all: true }), "audit.read")).toBe(true);
    expect(hasPermission(session("moderator", { "review.moderate": true }), "audit.read")).toBe(false);
  });
});
