import { describe, expect, it } from "vitest";
import { normalizeAdminRequestError } from "./admin-api";

describe("admin request failure normalization", () => {
  it("maps browser aborts to a retryable timeout error", () => {
    const error = normalizeAdminRequestError(new DOMException("aborted", "AbortError"));
    expect(error).toMatchObject({ status: 504, code: "admin_request_timeout" });
    expect(error?.message).toContain("انتهت مهلة الاتصال");
  });

  it("maps fetch/network failures to a retryable unavailable-server error", () => {
    const error = normalizeAdminRequestError(new TypeError("Failed to fetch"));
    expect(error).toMatchObject({ status: 503, code: "admin_network_unavailable" });
    expect(error?.message).toContain("تعذر الوصول إلى الخادم المحلي");
  });

  it("keeps application errors for the response parser", () => {
    expect(normalizeAdminRequestError(new Error("invalid payment status"))).toBeNull();
  });
});
