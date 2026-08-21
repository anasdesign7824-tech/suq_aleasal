export type AdminErrorResponse = {
  status: number;
  payload: { error: string; messageAr: string };
};

type ErrorCandidate = {
  code?: unknown;
  message?: unknown;
  status?: unknown;
};

const DATABASE_ERROR_MESSAGES: Record<string, { status: number; messageAr: string }> = {
  "42501": {
    status: 403,
    messageAr: "رفضت قاعدة البيانات العملية بسبب صلاحيات مسار الإدارة. تحقق من منح صلاحية المسار الإداري ثم أعد المحاولة.",
  },
  "23505": {
    status: 409,
    messageAr: "يوجد سجل مطابق مسبقًا. راجع الحقول الفريدة ثم أعد المحاولة.",
  },
  "23503": {
    status: 409,
    messageAr: "لا يمكن تنفيذ العملية لأن هناك سجلات مرتبطة بهذا العنصر. راجع الارتباطات ثم أعد المحاولة.",
  },
  "23514": {
    status: 400,
    messageAr: "البيانات لا تطابق قيود النظام. راجع الحقول المطلوبة والقيم المسموحة.",
  },
  "PGRST116": {
    status: 404,
    messageAr: "العنصر المطلوب غير موجود في المصدر الحالي.",
  },
};

function isHttpStatus(value: unknown): value is number {
  return typeof value === "number" && value >= 400 && value < 600;
}

export function buildAdminErrorResponse(error: unknown): AdminErrorResponse {
  const candidate = (error ?? null) as ErrorCandidate | null;
  const code = typeof candidate?.code === "string" ? candidate.code : undefined;
  const rawMessage = typeof candidate?.message === "string"
    ? candidate.message
    : error instanceof Error
      ? error.message
      : "";
  const mapped = code ? DATABASE_ERROR_MESSAGES[code] : undefined;
  const status = mapped?.status ?? (isHttpStatus(candidate?.status) ? candidate.status : 500);
  const safeRawMessage = /[\u0600-\u06FF]/.test(rawMessage) ? rawMessage : "";
  const messageAr = mapped?.messageAr ?? (safeRawMessage || "تعذر تنفيذ العملية الإدارية الآن.");
  return {
    status,
    payload: {
      error: code ?? "admin_backend_error",
      messageAr,
    },
  };
}
