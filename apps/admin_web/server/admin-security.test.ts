import { afterEach, describe, expect, it } from "vitest";
import type { Response } from "express";
import { setAdminCookies, type AdminSession } from "./admin-auth";

const originalHttps = process.env.ASSALKOM_ADMIN_HTTPS;

afterEach(() => {
  if (originalHttps === undefined) delete process.env.ASSALKOM_ADMIN_HTTPS;
  else process.env.ASSALKOM_ADMIN_HTTPS = originalHttps;
});

const session: AdminSession = {
  accessToken: "access-token-issued-by-supabase",
  refreshToken: "refresh-token-issued-by-supabase",
  user: { id: "admin-id", email: "admin@example.com", user_metadata: {} },
  role: { id: "role-id", code: "admin", nameAr: "مدير", permissions: {} },
  requiresPasswordChange: false,
};

describe("admin cookie security", () => {
  it("sets HttpOnly, SameSite=Lax, root path, and non-secure cookies for local HTTP", () => {
    process.env.ASSALKOM_ADMIN_HTTPS = "false";
    const cookies: Array<{ name: string; value: string; options: Record<string, unknown> }> = [];
    const response = {
      cookie(name: string, value: string, options: Record<string, unknown>) {
        cookies.push({ name, value, options });
      },
    } as unknown as Response;

    setAdminCookies(response, session);

    expect(cookies).toHaveLength(2);
    expect(cookies.map((cookie) => cookie.name)).toEqual([
      "assalkom_admin_access",
      "assalkom_admin_refresh",
    ]);
    for (const cookie of cookies) {
      expect(cookie.value).toMatch(/token-issued-by-supabase/);
      expect(cookie.options).toMatchObject({ httpOnly: true, sameSite: "lax", secure: false, path: "/" });
    }
  });

  it("sets Secure cookies when HTTPS is explicitly enabled", () => {
    process.env.ASSALKOM_ADMIN_HTTPS = "true";
    const cookies: Array<Record<string, unknown>> = [];
    const response = {
      cookie(_name: string, _value: string, options: Record<string, unknown>) {
        cookies.push(options);
      },
    } as unknown as Response;

    setAdminCookies(response, session);

    expect(cookies).toHaveLength(2);
    expect(cookies.every((options) => options.secure === true)).toBe(true);
  });
});
