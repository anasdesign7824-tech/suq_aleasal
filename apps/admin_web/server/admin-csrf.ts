import type { NextFunction, Request, Response } from "express";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

function configuredOrigins(): Set<string> {
  const values = (process.env.ASSALKOM_ADMIN_ALLOWED_ORIGINS ?? "")
    .split(",")
    .map((value) => value.trim())
    .filter(Boolean);
  return new Set(values.map(normalizeOrigin).filter((value): value is string => value !== null));
}

function normalizeOrigin(value: string): string | null {
  try {
    const origin = new URL(value).origin;
    return origin === "null" ? null : origin;
  } catch {
    return null;
  }
}

function requestOrigin(request: Pick<Request, "headers">): string | null {
  const forwarded = request.headers["x-forwarded-proto"];
  const protocol = process.env.ASSALKOM_ADMIN_HTTPS === "true"
    ? "https"
    : typeof forwarded === "string" && forwarded.split(",")[0]?.trim() === "https"
      ? "https"
      : "http";
  const host = request.headers.host;
  return host ? `${protocol}://${host}` : null;
}

export function isSameOriginAdminMutation(request: Pick<Request, "method" | "headers">): boolean {
  if (SAFE_METHODS.has(request.method.toUpperCase())) return true;

  const originHeader = request.headers.origin;
  const refererHeader = request.headers.referer;
  const origin = typeof originHeader === "string" ? normalizeOrigin(originHeader) : null;
  const refererOrigin = typeof refererHeader === "string"
    ? (() => {
        try {
          return normalizeOrigin(new URL(refererHeader).origin);
        } catch {
          return null;
        }
      })()
    : null;
  const candidate = origin ?? refererOrigin;

  if (!candidate && request.headers["sec-fetch-site"] === "same-origin") return true;
  if (!candidate) return false;

  const allowed = configuredOrigins();
  const localOrigin = requestOrigin(request);
  if (localOrigin) allowed.add(localOrigin);
  return allowed.has(candidate);
}

export function requireSameOriginAdminMutation(request: Request, response: Response, next: NextFunction): void {
  if (isSameOriginAdminMutation(request)) {
    next();
    return;
  }
  response.status(403).json({
    error: "admin_csrf_rejected",
    messageAr: "رُفض الطلب الإداري لأنه لا ينتمي إلى مصدر لوحة الإدارة الموثوق.",
  });
}
