export type AdminStatusContext = "generic" | "product" | "store" | "request" | "merchantApplication";

export type AdminStatusMeta = {
  label: string;
  className: string;
};

const unknownStatus: AdminStatusMeta = {
  label: "حالة غير معروفة",
  className: "border-[#d8c7b6] bg-[#faf6f0] text-[#816b58]",
};

const genericStatusMeta: Record<string, AdminStatusMeta> = {
  approved: { label: "معتمد", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  rejected: { label: "مرفوض", className: "border-red-300 bg-red-50 text-red-800" },
  pending: { label: "قيد المراجعة", className: "border-amber-300 bg-amber-50 text-amber-800" },
  active: { label: "نشط", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  paused: { label: "متوقف مؤقتًا", className: "border-slate-300 bg-slate-50 text-slate-700" },
  suspended: { label: "معلّق", className: "border-red-300 bg-red-50 text-red-800" },
  draft: { label: "مسودة", className: "border-slate-300 bg-slate-50 text-slate-700" },
};

const scopedStatusMeta: Record<AdminStatusContext, Record<string, AdminStatusMeta>> = {
  generic: genericStatusMeta,
  product: {
    draft: genericStatusMeta.draft,
    pending: { label: "قيد المراجعة", className: "border-amber-300 bg-amber-50 text-amber-800" },
    active: genericStatusMeta.active,
    paused: genericStatusMeta.paused,
    rejected: genericStatusMeta.rejected,
  },
  store: {
    pending: { label: "قيد التفعيل", className: "border-amber-300 bg-amber-50 text-amber-800" },
    active: { label: "مفعّل", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
    paused: genericStatusMeta.paused,
    rejected: genericStatusMeta.rejected,
    suspended: genericStatusMeta.suspended,
  },
  request: {
    open: { label: "مفتوح", className: "border-amber-300 bg-amber-50 text-amber-800" },
    in_progress: { label: "قيد المتابعة", className: "border-blue-300 bg-blue-50 text-blue-800" },
    answered: { label: "تم الرد", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
    closed: { label: "مغلق", className: "border-slate-300 bg-slate-50 text-slate-700" },
    cancelled: { label: "ملغي", className: "border-slate-300 bg-slate-50 text-slate-700" },
  },
  merchantApplication: {
    submitted: { label: "تم الإرسال", className: "border-amber-300 bg-amber-50 text-amber-800" },
    under_review: { label: "قيد المراجعة", className: "border-blue-300 bg-blue-50 text-blue-800" },
    approved: { label: "مفعّل — المتجر نشط", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
    rejected: genericStatusMeta.rejected,
    needs_more_info: { label: "يحتاج معلومات", className: "border-blue-300 bg-blue-50 text-blue-800" },
  },
};

export function adminStatusMeta(status: string, context: AdminStatusContext = "generic"): AdminStatusMeta {
  return scopedStatusMeta[context][status] ?? genericStatusMeta[status] ?? unknownStatus;
}

const productTypeLabels: Record<string, string> = {
  honey: "عسل",
  wax: "شمع",
  mix: "خلطة",
  raw: "منتج خام",
  gift: "هدية",
};

export function adminProductTypeLabel(productType: string): string {
  return productTypeLabels[productType] ?? "نوع غير محدد";
}

const auditActionLabels: Record<string, string> = {
  "store.approve": "اعتماد متجر",
  "store.reject": "رفض متجر",
  "store.suspend": "تعليق متجر",
  "store.reactivate": "إعادة تفعيل متجر",
  "product.create": "إنشاء منتج",
  "product.update": "تحديث منتج",
  "product.delete": "حذف منتج",
  "request.answer": "الرد على طلب تواصل",
  "merchant_application.review": "مراجعة طلب تاجر",
  "store_verification.review": "مراجعة توثيق متجر",
  "notification.send": "إرسال إشعار",
  "banner.create": "إنشاء بانر",
  "banner.update": "تحديث بانر",
  "banner.delete": "حذف بانر",
};

const auditEntityLabels: Record<string, string> = {
  stores: "المتاجر",
  products: "المنتجات",
  requests: "طلبات التواصل",
  merchant_applications: "طلبات التجار",
  store_verification_requests: "طلبات توثيق المتاجر",
  notifications: "الإشعارات",
  banners: "البانرات",
  users: "المستخدمون",
};

export function adminAuditActionLabel(action: string): string {
  return auditActionLabels[action] ?? "إجراء إداري";
}

export function adminAuditEntityLabel(entityType: string): string {
  return auditEntityLabels[entityType] ?? "كيان إداري";
}
