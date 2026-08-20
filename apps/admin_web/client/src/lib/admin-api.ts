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
  const controller = new AbortController();
  const timeout = window.setTimeout(() => controller.abort(), 30_000);
  try {
    const response = await fetch(url, {
      credentials: "same-origin",
      headers: { "Content-Type": "application/json", ...(init?.headers ?? {}) },
      ...init,
      signal: init?.signal ?? controller.signal,
    });
    const payload = (await response.json().catch(() => ({}))) as T & { messageAr?: string; error?: string };
    if (!response.ok) {
      const error = new Error(payload.messageAr ?? "تعذر تنفيذ الطلب.") as AdminError;
      error.status = response.status;
      error.code = payload.error;
      throw error;
    }
    return payload as T;
  } catch (error) {
    if (error instanceof DOMException && error.name === "AbortError") {
      const timeoutError = new Error("انتهت مهلة الاتصال بالخادم المحلي. تحقق من تشغيل لوحة الإدارة ثم أعد المحاولة.") as AdminError;
      timeoutError.status = 504;
      timeoutError.code = "admin_request_timeout";
      throw timeoutError;
    }
    throw error;
  } finally {
    window.clearTimeout(timeout);
  }
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
  deleteProduct: (id: string) => request<{ item: unknown }>(`/api/admin/products/${encodeURIComponent(id)}`, { method: "DELETE" }),
  stores: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/stores?${queryString(params)}`),
  deleteStore: (id: string) => request<{ item: unknown }>(`/api/admin/stores/${encodeURIComponent(id)}`, { method: "DELETE" }),
  requests: (params: { page?: number; pageSize?: number } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/requests?${queryString(params)}`),
  merchantApplications: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/merchant-applications?${queryString(params)}`),
  storeVerificationRequests: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/store-verification-requests?${queryString(params)}`),
  storeVerificationRequest: (id: string) => request<{ request: unknown; documents: unknown[] }>(`/api/admin/store-verification-requests/${encodeURIComponent(id)}`),
  reviewStoreVerification: (id: string, input: { action: 'approve' | 'reject' | 'needs_more_info' | 'revoke'; reviewNote?: string | null; expiresAt?: string | null }) => request<{ item: unknown }>(`/api/admin/store-verification-requests/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  reconcileStoreVerificationPayment: (id: string, input: { paymentStatus: 'paid' | 'waived' | 'failed' | 'refunded'; paymentReference?: string | null; note?: string | null }) => request<{ item: unknown }>(`/api/admin/store-verification-requests/${encodeURIComponent(id)}/payment`, { method: 'PATCH', body: JSON.stringify(input) }),
  subscriptionPlans: () => request<{ items: unknown[] }>('/api/admin/subscription-plans'),
  subscriptionCampaigns: () => request<{ items: unknown[] }>('/api/admin/subscription-campaigns'),
  updateLaunchCampaign: (input: { discountPercent: number; isActive: boolean; startsAt?: string | null; endsAt?: string | null; appliesTo?: string[]; discountByPlanCode?: Record<string, number> }) => request<{ item: unknown }>('/api/admin/subscription-campaigns/app-launch', { method: 'PATCH', body: JSON.stringify(input) }),
  localTransferSettings: () => request<{ item: unknown | null }>('/api/admin/local-transfer-settings'),
  updateLocalTransferSettings: (input: Record<string, unknown>) => request<{ item: unknown }>('/api/admin/local-transfer-settings', { method: 'PUT', body: JSON.stringify(input) }),
  paymentRequests: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/payment-requests?${queryString(params)}`),
  paymentRequest: (id: string) => request<{ item: unknown }>(`/api/admin/payment-requests/${encodeURIComponent(id)}`),
  reconcilePaymentRequest: (id: string, input: { status: 'confirmed' | 'failed' | 'refunded' | 'waived' | 'under_review'; note?: string | null }) => request<{ item: unknown }>(`/api/admin/payment-requests/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  subscriptions: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/subscriptions?${queryString(params)}`),
  setSubscriptionStatus: (id: string, input: { status: 'active' | 'expired' | 'cancelled' | 'suspended'; note?: string | null }) => request<{ item: unknown }>(`/api/admin/subscriptions/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  activateSubscriptionForUser: (input: { merchantId: string; planId: string; note?: string | null }) => request<{ item: unknown }>('/api/admin/subscriptions/activate', { method: 'POST', body: JSON.stringify(input) }),
  designRequests: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/design-requests?${queryString(params)}`),
  updateDesignRequest: (id: string, input: { status: string; adminNote?: string | null; assignedAdminId?: string | null }) => request<{ item: unknown }>(`/api/admin/design-requests/${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(input) }),
  reviewMerchantApplication: (id: string, input: { status: "approved" | "rejected" | "needs_more_info"; reviewNote?: string | null }) => request<{ item: unknown }>(`/api/admin/merchant-applications/${encodeURIComponent(id)}`, { method: "PATCH", body: JSON.stringify(input) }),
  regions: () => request<{ items: unknown[] }>("/api/admin/regions"),
  deliveryMethods: () => request<{ items: unknown[] }>("/api/admin/delivery-methods"),
  storeLogistics: (storeId: string) => request<{ deliveryMethods: unknown[]; deliveryOptions: unknown[]; pickupLocations: unknown[]; regions: unknown[] }>(`/api/admin/stores/${encodeURIComponent(storeId)}/logistics`),
  upsertDeliveryOption: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/logistics/delivery-options", { method: "PUT", body: JSON.stringify(input) }),
  deleteDeliveryOption: (id: string) => request<{ item: unknown }>(`/api/admin/logistics/delivery-options/${encodeURIComponent(id)}`, { method: "DELETE" }),
  upsertPickupLocation: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/logistics/pickup-locations", { method: "PUT", body: JSON.stringify(input) }),
  deletePickupLocation: (id: string) => request<{ item: unknown }>(`/api/admin/logistics/pickup-locations/${encodeURIComponent(id)}`, { method: "DELETE" }),
  taxonomy: () => request<{ items: unknown[] }>("/api/admin/taxonomy"),
  categories: () => request<{ items: unknown[] }>("/api/admin/categories"),
  banners: () => request<{ items: unknown[] }>("/api/admin/banners"),
  deleteBanner: (id: string) => request<{ item: unknown }>(`/api/admin/banners/${encodeURIComponent(id)}`, { method: "DELETE" }),
  uploadPublicImage: (input: { contentType: string; base64: string; purpose?: string }) => request<{ item: { publicUrl: string; path: string; bytes: number } }>("/api/admin/storage/public-image", { method: "POST", body: JSON.stringify(input) }),
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
  users: (params: { page?: number; pageSize?: number; search?: string } = {}) => request<{ items: unknown[]; page: number; pageSize: number; total: number }>(`/api/admin/users?${queryString(params)}`),
  deleteUser: (id: string) => request<{ item: unknown }>(`/api/admin/users/${encodeURIComponent(id)}`, { method: "DELETE" }),
  messages: () => request<{ items: unknown[] }>("/api/admin/messages"),
  notifications: () => request<{ items: unknown[] }>("/api/admin/notifications"),
  sendNotification: (input: Record<string, unknown>) => request<{ item: unknown }>("/api/admin/notifications", { method: "POST", body: JSON.stringify(input) }),
  analytics: () => request<{ counts: Record<string, number>; operational: Record<string, number>; generatedAt: string }>("/api/admin/analytics"),
};
