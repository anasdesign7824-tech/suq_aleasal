import { useState } from "react";
import { CheckCircle2, FileText, Info, RefreshCw, XCircle } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";
import { AdminSafeImage } from "@/components/AdminVisuals";

type Application = {
  id: string;
  user_id: string;
  display_name: string;
  experience?: string | null;
  location?: string | null;
  phone?: string | null;
  specialties?: unknown;
  certificate_note?: string | null;
  logo_url?: string | null;
  cover_url?: string | null;
  status: string;
  review_note?: string | null;
  submitted_at: string;
};

type LoadState<T> = { data: T | null; loading: boolean; error: string | null };

const statusMeta: Record<string, { label: string; className: string }> = {
  submitted: { label: "تم الإرسال", className: "border-amber-300 bg-amber-50 text-amber-800" },
  under_review: { label: "قيد المراجعة", className: "border-blue-300 bg-blue-50 text-blue-800" },
  approved: { label: "مفعّل — المتجر نشط", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  rejected: { label: "مرفوض", className: "border-red-300 bg-red-50 text-red-800" },
  needs_more_info: { label: "يحتاج معلومات", className: "border-blue-300 bg-blue-50 text-blue-800" },
};

function statusBadge(status: string) {
  const meta = statusMeta[status] ?? { label: status, className: "border-[#d8c7b6] bg-[#faf6f0] text-[#816b58]" };
  return <Badge variant="outline" className={meta.className}>{meta.label}</Badge>;
}

function formatSpecialties(value: unknown): string {
  if (value === null || value === undefined) return "";
  if (typeof value === "string") return value;
  try { return JSON.stringify(value); } catch { return ""; }
}

function PanelState({ state, onRefresh }: { state: LoadState<Application[]>; onRefresh: () => void }) {
  if (state.loading) return <div className="flex min-h-48 items-center justify-center px-6 py-10 text-sm font-semibold text-[#806b5a]"><RefreshCw className="ml-2 size-4 animate-spin text-[#c77d1a]" />جارٍ قراءة طلبات التجار الحقيقية…</div>;
  if (state.error) return <div className="flex min-h-48 flex-col items-center justify-center px-6 py-10 text-center"><div className="grid size-12 place-items-center rounded-2xl bg-red-50 text-red-700"><XCircle className="size-5" /></div><h3 className="mt-4 text-base font-bold text-[#4f2e1f]">تعذر قراءة طلبات التجار</h3><p className="mt-1 max-w-md text-sm leading-7 text-[#806b5a]">{state.error}</p><Button variant="outline" onClick={onRefresh} className="mt-4 border-red-200 text-red-800"><RefreshCw className="ml-2 size-4" />إعادة المحاولة</Button></div>;
  if ((state.data ?? []).length === 0) return <div className="flex min-h-48 flex-col items-center justify-center px-6 py-10 text-center"><div className="grid size-12 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><FileText className="size-5" /></div><h3 className="mt-4 text-base font-bold text-[#4f2e1f]">لا توجد طلبات تجار</h3><p className="mt-1 max-w-md text-sm leading-7 text-[#806b5a]">ستظهر هنا طلبات التاجر المرسلة من تطبيق العميل عند وصولها إلى Supabase Production.</p><Button variant="outline" onClick={onRefresh} className="mt-4 border-[#e3c28d] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div>;
  return null;
}

export function MerchantApplicationsPanel({ state, onRefresh, onReviewed }: { state: LoadState<Application[]>; onRefresh: () => void; onReviewed: () => void }) {
  const [notes, setNotes] = useState<Record<string, string>>({});
  const review = async (application: Application, status: "approved" | "rejected" | "needs_more_info") => {
    try {
      await adminApi.reviewMerchantApplication(application.id, { status, reviewNote: notes[application.id]?.trim() || application.review_note?.trim() || null });
      toast.success(status === "approved" ? "تم تفعيل المتجر ومزامنة حساب التاجر وإرسال الإشعار." : status === "needs_more_info" ? "تم طلب معلومات إضافية وإرسال إشعار للتاجر." : "تم حفظ قرار طلب التاجر في Production.");
      onReviewed();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر حفظ قرار المراجعة.");
    }
  };

  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between gap-4 border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">دورة التاجر</div><h2 className="mt-1 text-xl font-bold text-[#342118]">طلبات التجار</h2><p className="mt-1 text-sm leading-6 text-[#806b5a]">استقبال الطلب من التطبيق ثم تفعيل المتجر ومزامنة حساب التاجر والإشعار في عملية واحدة.</p></div><Button onClick={onRefresh} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button></div><PanelState state={state} onRefresh={onRefresh} />{!state.loading && !state.error && (state.data ?? []).length > 0 && <div className="divide-y divide-[#f1e7da]">{(state.data ?? []).map((application) => { const active = application.status === "approved"; return <article className="p-5" key={application.id}><div className="flex flex-wrap items-start justify-between gap-3"><div className="flex items-start gap-3"><div className="size-14 shrink-0 overflow-hidden rounded-2xl bg-[#fff0d6]"><AdminSafeImage src={application.logo_url ?? application.cover_url} alt={application.display_name} fallbackClassName="grid size-full place-items-center bg-[#fff0d6] text-[#9c5a00]" /></div><div><h3 className="text-base font-bold text-[#432a1e]">{application.display_name}</h3><p className="mt-1 text-xs text-[#8e7a68]" dir="ltr">{application.phone ?? application.user_id}</p></div></div>{statusBadge(application.status)}</div><div className="mt-4 grid gap-3 text-sm text-[#6f5b4c] sm:grid-cols-2"><p><span className="font-semibold text-[#4f2e1f]">الموقع:</span> {application.location ?? "غير محدد"}</p><p><span className="font-semibold text-[#4f2e1f]">الخبرة:</span> {application.experience ?? "غير محددة"}</p></div>{formatSpecialties(application.specialties) && <p className="mt-3 text-sm leading-6 text-[#6f5b4c]"><span className="font-semibold text-[#4f2e1f]">التخصصات:</span> {formatSpecialties(application.specialties)}</p>}{application.certificate_note && <p className="mt-2 text-sm leading-6 text-[#6f5b4c]"><span className="font-semibold text-[#4f2e1f]">الشهادة:</span> {application.certificate_note}</p>}{active ? <div className="mt-4 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-3 text-sm font-semibold text-emerald-800">تم تفعيل المتجر ومزامنة حساب التاجر. أُرسل إشعار التفعيل، ولا توجد حاجة لإعادة تنفيذ القرار.</div> : <div className="mt-4 flex flex-col gap-2 sm:flex-row"><Input aria-label="ملاحظة قرار التاجر" placeholder="ملاحظة القرار (اختيارية)" value={notes[application.id] ?? application.review_note ?? ""} onChange={(event) => setNotes((previous) => ({ ...previous, [application.id]: event.target.value }))} className="h-10 rounded-xl border-[#eadcc9]" /><Button onClick={() => void review(application, "approved")} className="bg-[#4f2e1f] hover:bg-[#6b412a]"><CheckCircle2 className="ml-2 size-4" />تفعيل المتجر</Button><Button onClick={() => void review(application, "needs_more_info")} variant="outline" className="border-blue-200 text-blue-800"><Info className="ml-2 size-4" />طلب معلومات</Button><Button onClick={() => void review(application, "rejected")} variant="outline" className="border-red-200 text-red-800"><XCircle className="ml-2 size-4" />رفض</Button></div>}</article>; })}</div>}</section>;
}
