import { afterEach, describe, expect, it } from "vitest";
import { isSameOriginAdminMutation } from "./admin-csrf";

const originalAllowedOrigins = process.env.ASSALKOM_ADMIN_ALLOWED_ORIGINS;
const originalHttps = process.env.ASSALKOM_ADMIN_HTTPS;

afterEach(() => {
  if (originalAllowedOrigins === undefined) delete process.env.ASSALKOM_ADMIN_ALLOWED_ORIGINS;
  else process.env.ASSALKOM_ADMIN_ALLOWED_ORIGINS = originalAllowedOrigins;
  if (originalHttps === undefined) delete process.env.ASSALKOM_ADMIN_HTTPS;
  else process.env.ASSALKOM_ADMIN_HTTPS = originalHttps;
});

describe("admin same-origin mutation guard", () => {
  it("allows safe methods without an origin header", () => {
    expect(isSameOriginAdminMutation({ method: "GET", headers: {} })).toBe(true);
    expect(isSameOriginAdminMutation({ method: "OPTIONS", headers: {} })).toBe(true);
  });

  it("allows a same-origin local mutation", () => {
    expect(isSameOriginAdminMutation({
      method: "POST",
      headers: { origin: "http://127.0.0.1:3210", host: "127.0.0.1:3210" },
    })).toBe(true);
  });

  it("allows configured dev frontend origins", () => {
    process.env.ASSALKOM_ADMIN_ALLOWED_ORIGINS = "http://localhost:5173";
    expect(isSameOriginAdminMutation({
      method: "PATCH",
      headers: { origin: "http://localhost:5173", host: "127.0.0.1:3210" },
    })).toBe(true);
  });

  it("rejects a cross-origin mutation even when the request has a body", () => {
    expect(isSameOriginAdminMutation({
      method: "DELETE",
      headers: { origin: "https://evil.example", host: "127.0.0.1:3210" },
    })).toBe(false);
  });

  it("rejects a mutation with no origin evidence", () => {
    expect(isSameOriginAdminMutation({
      method: "POST",
      headers: { host: "127.0.0.1:3210" },
    })).toBe(false);
  });

  it("supports same-origin HTTPS when the admin is explicitly configured for HTTPS", () => {
    process.env.ASSALKOM_ADMIN_HTTPS = "true";
    expect(isSameOriginAdminMutation({
      method: "PUT",
      headers: { origin: "https://localhost:3210", host: "localhost:3210" },
    })).toBe(true);
  });
});
