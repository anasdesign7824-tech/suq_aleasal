export type AdminRole = {
  id: string;
  code: string;
  nameAr: string;
  permissions: Record<string, boolean>;
};

export type AdminIdentity = {
  id: string;
  email?: string;
  user_metadata?: Record<string, unknown>;
};

export type AdminSessionPayload = {
  user: AdminIdentity;
  role: AdminRole;
  source: "supabase-production";
  requiresPasswordChange?: boolean;
};

export type AdminError = Error & { status?: number; code?: string };

function queryString(params: Record<string, string | number | undefined>): string {
  const values = Object.entries(params).filter(([, value]) => value !== undefined && value !== "");
  return new URLSearchParams(values.map(([key, value]) => [key, String(value)])).toString();
}

async function request<T>(url: string, init?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    credentials: "same-origin",
    headers: { "Content-Type": "application/json", ...(init?.headers ?? {}) },
    ...init,
  });
  const payload = (await response.json().catch(() => ({}))) as T & { messageAr?: string; error?: string };
  if (!response.ok) {
    const error = new Error(payload.messageAr ?? "تعذر تنفيذ الطلب.") as AdminError;
    error.status = response.status;
    error.code = payload.error;
    throw error;
  }
  return payload as T;
}

export const adminApi = {
  session: () => request<AdminSessionPayload>("/api/admin/auth/session"),
  login: (email: string, password: string) => request<AdminSessionPayload>("/api/admin/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  }),
  logout: () => request<{ ok: true }>("/api/admin/auth/logout", { method: "POST" }),
  changePassword: (newPassword: string) => request<AdminSessionPayload>("/api/admin/auth/password", { method: "POST", body: JSON.stringify({ newPassword }) }),
  overview: () => request<{ source: "supabase_production"; counts: Record<string, number>; generatedAt: string }>("/api/admin/overview"),
  products: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/products?${queryString(params)}`),
  stores: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/stores?${queryString(params)}`),
  requests: (params: { page?: number; pageSize?: number } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/requests?${queryString(params)}`),
  merchantApplications: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/merchant-applications?${queryString(params)}`),
  reviewMerchantApplication: (id: string, input: { status: "approved" | "rejected" | "needs_more_info"; reviewNote?: string | null }) => request<{ item: unknown }>(`/api/admin/merchant-applications/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(input) }),
  regions: () => request<{ items: unknown[] }>("/api/admin/regions"),
  taxonomy: () => request<{ items: unknown[] }>("/api/admin/taxonomy"),
  categories: () => request<{ items: unknown[] }>("/api/admin/categories"),
  banners: () => request<{ items: unknown[] }>("/api/admin/banners"),
  moderateStore: (id: string, action: "approve" | "reject" | "suspend" | "reactivate") => request<{ item: unknown }>(`/api/admin/stores/${encodeURIComponent(id)}/${action}`, { method: "POST" }),
  createProduct: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/products", { method: "POST", body: JSON.stringify(input) }),
  updateProduct: (id: string, input: Record<string, unknown>) => request<{ item: unknown }>(`/api/admin/products/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(input) }),
  createBanner: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/banners", { method: "POST", body: JSON.stringify(input) }),
  updateBanner: (id: string, input: Record<string, unknown>) => request<{ item: unknown }>(`/api/admin/banners/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(input) }),
  upsertCategory: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/categories", { method: "PUT", body: JSON.stringify(input) }),
  upsertTaxonomy: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/taxonomy", { method: "PUT", body: JSON.stringify(input) }),
  answerRequest: (id: string, body: string) => request<{ item: unknown }>(`/api/admin/requests/${encodeURIComponent(id)}/reply`, { method: "POST", body: JSON.stringify({ body }) }),
  adminUsers: () => request<{ items: unknown[] }>("/api/admin/admin-users"),
  createAdminUser: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/admin-users", { method: "POST", body: JSON.stringify(input) }),
  updateAdminUser: (id: string, input: Record<string, unknown>) => request<{ item: unknown }>(`/api/admin/admin-users/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(input) }),
  auditLogs: () => request<{ items: unknown[] }>("/api/admin/audit-logs"),
  users: () => request<{ items: unknown[] }>("/api/admin/users"),
  messages: () => request<{ items: unknown[] }>("/api/admin/messages"),
  notifications: () => request<{ items: unknown[] }>("/api/admin/notifications"),
  sendNotification: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/notifications", { method: "POST", body: JSON.stringify(input) }),
  analytics: () => request<{ counts: Record<string, number>; operational: Record<string, number>; generatedAt: string }>("/api/admin/analytics"),
};
