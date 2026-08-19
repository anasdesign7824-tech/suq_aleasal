import type { NextFunction, Request, Response } from "express";
import type { User } from "@supabase/supabase-js";
import { createPublicSupabaseClient, createServiceSupabaseClient } from "./supabase";

export const ADMIN_ACCESS_COOKIE = "assalkom_admin_access";
export const ADMIN_REFRESH_COOKIE = "assalkom_admin_refresh";

export type AdminPermission =
  | "admin.manage"
  | "user.read"
  | "user.manage"
  | "user.delete"
  | "store.read"
  | "store.review"
  | "store.approve"
  | "store.reject"
  | "store.suspend"
  | "store.media.write"
  | "store.delete"
  | "merchant.review"
  | "verification.read"
  | "verification.read_sensitive"
  | "verification.review"
  | "verification.approve"
  | "verification.reject"
  | "product.read"
  | "product.write"
  | "product.delete"
  | "product.review"
  | "product.approve"
  | "product.reject"
  | "taxonomy.read"
  | "taxonomy.manage"
  | "region.manage"
  | "banner.read"
  | "banner.write"
  | "banner.delete"
  | "banner.publish"
  | "request.read"
  | "request.write"
  | "message.read"
  | "message.write"
  | "review.read"
  | "review.moderate"
  | "analytics.read"
  | "notification.write"
  | "audit.read"
  | "storage.public.write";

export type AdminSession = {
  accessToken: string;
  refreshToken?: string;
  user: Pick<User, "id" | "email" | "user_metadata">;
  role: {
    id: string;
    code: string;
    nameAr: string;
    permissions: Record<string, boolean>;
  };
  requiresPasswordChange: boolean;
};

type CookieOptions = {
  httpOnly: true;
  sameSite: "lax";
  secure: boolean;
  path: "/";
  maxAge?: number;
};

const cookieOptions = (maxAge?: number): CookieOptions => ({
  httpOnly: true,
  sameSite: "lax",
  secure: process.env.ASSALKOM_ADMIN_HTTPS === "true",
  path: "/",
  ...(maxAge === undefined ? {} : { maxAge }),
});

function parseCookies(request: Request): Record<string, string> {
  const header = request.headers.cookie;
  if (!header) return {};
  return Object.fromEntries(
    header
      .split(";")
      .map((part) => part.trim().split("="))
      .filter(([name, value]) => name && value)
      .map(([name, value]) => [name, decodeURIComponent(value)]),
  );
}

function normalizePermissions(value: unknown): Record<string, boolean> {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  const permissions: Record<string, boolean> = {};
  for (const [key, rawValue] of Object.entries(value)) {
    if (rawValue === true) permissions[key] = true;
  }
  return permissions;
}

async function getRoleForUser(userId: string) {
  const service = createServiceSupabaseClient();
  const membership = await service
    .from("admin_users")
    .select("user_id, role_id, is_active")
    .eq("user_id", userId)
    .eq("is_active", true)
    .maybeSingle();
  if (membership.error) throw membership.error;
  if (!membership.data) return null;

  const role = await service
    .from("admin_roles")
    .select("id, code, name_ar, permissions")
    .eq("id", membership.data.role_id)
    .maybeSingle();
  if (role.error) throw role.error;
  if (!role.data) return null;

  return {
    id: role.data.id,
    code: role.data.code,
    nameAr: role.data.name_ar,
    permissions: normalizePermissions(role.data.permissions),
  };
}

async function hydrateSession(accessToken: string, refreshToken?: string): Promise<AdminSession | null> {
  const publicClient = createPublicSupabaseClient(accessToken);
  const identity = await publicClient.auth.getUser(accessToken);
  if (identity.error || !identity.data.user) return null;
  const role = await getRoleForUser(identity.data.user.id);
  if (!role) return null;
  return {
    accessToken,
    refreshToken,
    requiresPasswordChange: identity.data.user.user_metadata?.must_change_password === true,
    user: {
      id: identity.data.user.id,
      email: identity.data.user.email,
      user_metadata: identity.data.user.user_metadata,
    },
    role,
  };
}

export async function signInAdmin(email: string, password: string): Promise<AdminSession> {
  const publicClient = createPublicSupabaseClient();
  const result = await publicClient.auth.signInWithPassword({
    email: email.trim().toLowerCase(),
    password,
  });
  if (result.error || !result.data.session || !result.data.user) {
    throw new Error("بيانات الدخول الإدارية غير صحيحة أو الحساب غير مفعل.");
  }
  const role = await getRoleForUser(result.data.user.id);
  if (!role) {
    await publicClient.auth.signOut();
    throw new Error("هذه الهوية لا تملك عضوية إدارية.");
  }
  return {
    accessToken: result.data.session.access_token,
    refreshToken: result.data.session.refresh_token,
    requiresPasswordChange: result.data.user.user_metadata?.must_change_password === true,
    user: {
      id: result.data.user.id,
      email: result.data.user.email,
      user_metadata: result.data.user.user_metadata,
    },
    role,
  };
}

export function setAdminCookies(response: Response, session: AdminSession): void {
  response.cookie(ADMIN_ACCESS_COOKIE, session.accessToken, cookieOptions(60 * 60 * 1000));
  if (session.refreshToken) {
    response.cookie(ADMIN_REFRESH_COOKIE, session.refreshToken, cookieOptions(30 * 24 * 60 * 60 * 1000));
  }
}

export function clearAdminCookies(response: Response): void {
  response.clearCookie(ADMIN_ACCESS_COOKIE, cookieOptions());
  response.clearCookie(ADMIN_REFRESH_COOKIE, cookieOptions());
}

export async function getAdminSession(request: Request, response?: Response): Promise<AdminSession | null> {
  const cookies = parseCookies(request);
  const accessToken = cookies[ADMIN_ACCESS_COOKIE];
  const refreshToken = cookies[ADMIN_REFRESH_COOKIE];
  if (!accessToken && !refreshToken) return null;

  if (accessToken) {
    const session = await hydrateSession(accessToken, refreshToken);
    if (session) return session;
  }

  if (!refreshToken) return null;
  const publicClient = createPublicSupabaseClient();
  const refreshed = await publicClient.auth.refreshSession({ refresh_token: refreshToken });
  if (refreshed.error || !refreshed.data.session) return null;
  const session = await hydrateSession(
    refreshed.data.session.access_token,
    refreshed.data.session.refresh_token,
  );
  if (session && response) setAdminCookies(response, session);
  return session;
}

export function requireAdmin(permission?: AdminPermission) {
  return async (request: Request, response: Response, next: NextFunction) => {
    try {
      const session = await getAdminSession(request, response);
      if (!session) {
        response.status(401).json({ error: "admin_unauthorized", messageAr: "سجّل الدخول إلى الإدارة أولًا." });
        return;
      }
      if (session.requiresPasswordChange && request.path !== "/api/admin/auth/password") {
        response.status(428).json({ error: "admin_password_change_required", messageAr: "يجب تغيير كلمة المرور قبل استخدام لوحة الإدارة." });
        return;
      }
      if (permission && !hasPermission(session, permission)) {
        response.status(403).json({ error: "admin_forbidden", messageAr: "لا تملك الصلاحية لتنفيذ هذا الإجراء." });
        return;
      }
      response.locals.adminSession = session;
      next();
    } catch (error) {
      next(error);
    }
  };
}

export function hasPermission(session: AdminSession, permission: AdminPermission): boolean {
  return session.role.code === "super_admin" || session.role.permissions.all === true || session.role.permissions[permission] === true;
}

export function getRequestAdminSession(response: Response): AdminSession {
  const session = response.locals.adminSession as AdminSession | undefined;
  if (!session) throw new Error("Admin session was not attached to the request.");
  return session;
}

export async function changeAdminPassword(session: AdminSession, newPassword: string): Promise<AdminSession> {
  if (typeof newPassword !== "string" || newPassword.length < 12) throw new Error("كلمة المرور الجديدة يجب ألا تقل عن 12 حرفًا.");
  const service = createServiceSupabaseClient();
  const result = await service.auth.admin.updateUserById(session.user.id, {
    password: newPassword,
    user_metadata: { ...(session.user.user_metadata ?? {}), must_change_password: false },
  });
  if (result.error || !result.data.user) throw result.error ?? new Error("تعذر تحديث كلمة المرور.");
  return { ...session, requiresPasswordChange: false, user: { ...session.user, user_metadata: result.data.user.user_metadata } };
}
