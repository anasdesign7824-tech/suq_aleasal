import { useEffect, useMemo, useState } from "react";
import { CheckCircle2, FileText, RefreshCw, ShieldCheck, XCircle } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type VerificationDocument = {
  id: string;
  document_type: string;
  file_name: string;
  mime_type: string;
  byte_size: number;
  review_status: string;
  review_note?: string | null;
  file_path?: string;
  signed_url?: string;
};

type VerificationRow = {
  id: string;
  store_id: string;
  merchant_id: string;
  plan_code: string;
  origin: string;
  status: string;
  payment_status: string;
  payment_reference?: string | null;
  submitted_at?: string | null;
  reviewed_at?: string | null;
  review_note?: string | null;
  expires_at?: string | null;
  created_at: string;
  store?: { id: string; name_ar: string; merchant_id: string; status: string; logo_url?: string | null; cover_url?: string | null } | null;
  merchant?: { user_id: string; display_name: string; phone?: string | null } | null;
  documents: VerificationDocument[];
};

type LoadState = { items: VerificationRow[]; loading: boolean; error: string | null };

const statusLabels: Record<string, string> = {
  draft: "مسودة",
  payment_pending: "بانتظار الرسوم",
  submitted: "أُرسل للمراجعة",
  under_review: "قيد المراجعة",
  needs_more_info: "يحتاج معلومات",
  approved: "موثق Pro",
  rejected: "مرفوض",
  revoked: "مسحوب",
  expired: "منتهٍ",
};

const paymentLabels: Record<string, string> = {
  not_started: "لم تبدأ الرسوم",
  pending: "بانتظار الدفع",
  paid: "تم الدفع",
  failed: "فشل الدفع",
  refunded: "تم رد الرسوم",
  waived: "معفى من الرسوم",
};

const documentLabels: Record<string, string> = {
  identity: "الهوية الشخصية",
  business_registration: "إثبات تسجيل النشاط",
  tax_or_license: "الرخصة أو البطاقة الضريبية",
  origin_certificate: "شهادة مصدر العسل",
  quality_certificate: "شهادة الجودة",
  address_proof: "إثبات العنوان",
  other: "مستند إضافي",
};

function statusBadge(status: string) {
  const tone = status === "approved"
    ? "border-emerald-300 bg-emerald-50 text-emerald-800"
    : status === "rejected" || status === "revoked"
      ? "border-red-300 bg-red-50 text-red-800"
      : status === "needs_more_info"
        ? "border-blue-300 bg-blue-50 text-blue-800"
        : "border-amber-300 bg-amber-50 text-amber-800";
  return <Badge variant="outline" className={tone}>{statusLabels[status] ?? status}</Badge>;
}

function formatDate(value?: string | null) {
  if (!value) return "غير مسجل";
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? value : date.toLocaleString("ar-YE");
}

export function AdminStoreVerificationPanel() {
  const [state, setState] = useState<LoadState>({ items: [], loading: true, error: null });
  const [selected, setSelected] = useState<VerificationRow | null>(null);
  const [selectedDetail, setSelectedDetail] = useState<{ request: VerificationRow; documents: VerificationDocument[] } | null>(null);
  const [note, setNote] = useState("");
  const [paymentReference, setPaymentReference] = useState("");
  const [busy, setBusy] = useState(false);

  const load = async () => {
    setState((previous) => ({ ...previous, loading: true, error: null }));
    try {
      const result = await adminApi.storeVerificationRequests({ page: 1, pageSize: 50 });
      setState({ items: result.items as VerificationRow[], loading: false, error: null });
    } catch (error) {
      setState({ items: [], loading: false, error: error instanceof Error ? error.message : "تعذر قراءة طلبات التوثيق." });
    }
  };

  useEffect(() => { void load(); }, []);

  const openDetails = async (row: VerificationRow) => {
    setSelected(row);
    setSelectedDetail(null);
    setNote(row.review_note ?? "");
    setPaymentReference(row.payment_reference ?? "");
    try {
      const details = await adminApi.storeVerificationRequest(row.id);
      setSelectedDetail({ request: details.request as VerificationRow, documents: details.documents as VerificationDocument[] });
    } catch (error) {
      setState((previous) => ({ ...previous, error: error instanceof Error ? error.message : "تعذر قراءة مستندات الطلب." }));
    }
  };

  const runAction = async (action: "approve" | "reject" | "needs_more_info" | "revoke") => {
    if (!selected) return;
    const confirmText = action === "approve"
      ? "اعتماد التوثيق سيُظهر شارة Pro للمستخدم. هل تريد المتابعة؟"
      : action === "revoke"
        ? "سيتم سحب الشارة الحالية. هل تريد المتابعة؟"
        : "تأكيد تنفيذ القرار على طلب التوثيق؟";
    if (!window.confirm(confirmText)) return;
    setBusy(true);
    try {
      await adminApi.reviewStoreVerification(selected.id, { action, reviewNote: note.trim() || null });
      setSelected(null);
      setSelectedDetail(null);
      await load();
    } catch (error) {
      setState((previous) => ({ ...previous, error: error instanceof Error ? error.message : "تعذر تنفيذ قرار التوثيق." }));
    } finally {
      setBusy(false);
    }
  };

  const reconcilePayment = async (paymentStatus: "paid" | "waived" | "failed" | "refunded") => {
    if (!selected) return;
    const labels = { paid: "تأكيد الدفع", waived: "الإعفاء الإداري", failed: "تسجيل فشل الدفع", refunded: "تسجيل رد الرسوم" } as const;
    if (!window.confirm(`سيتم تنفيذ: ${labels[paymentStatus]}. هل تريد المتابعة؟`)) return;
    setBusy(true);
    try {
      const result = await adminApi.reconcileStoreVerificationPayment(selected.id, {
        paymentStatus,
        paymentReference: paymentReference.trim() || null,
        note: note.trim() || null,
      });
      const updated = result.item as Partial<VerificationRow>;
      setSelected((current) => current ? { ...current, ...updated, payment_status: String(updated.payment_status ?? current.payment_status), status: String(updated.status ?? current.status) } : current);
      setPaymentReference(String(updated.payment_reference ?? paymentReference));
      await load();
    } catch (error) {
      setState((previous) => ({ ...previous, error: error instanceof Error ? error.message : "تعذر تسوية رسوم التوثيق." }));
    } finally {
      setBusy(false);
    }
  };

  const pendingCount = useMemo(() => state.items.filter((item) => ["submitted", "under_review", "needs_more_info"].includes(item.status)).length, [state.items]);

  return (
    <section className="space-y-5">
      <div className="admin-card flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <div className="section-kicker">خدمة Pro</div>
          <h2 className="mt-1 text-xl font-bold text-[#342118]">مراجعة توثيق المتاجر</h2>
          <p className="mt-1 text-sm leading-7 text-[#806b5a]">فتح المتجر لا يمنح الشارة. هذه الطلبات لها رسوم ومستندات ومراجعة وسجل قرار مستقل.</p>
        </div>
        <div className="flex items-center gap-2">
          <Badge variant="outline" className="border-[#e3c28d] bg-[#fff7e9] text-[#8b5a2b]">{pendingCount} قيد المتابعة</Badge>
          <Button onClick={() => void load()} variant="outline" className="border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button>
        </div>
      </div>

      {state.loading ? <div className="admin-card p-8 text-center text-sm text-[#806b5a]">جارٍ قراءة طلبات التوثيق…</div>
        : state.error ? <div className="admin-card p-8 text-center text-sm text-red-800">{state.error}</div>
          : state.items.length === 0 ? <div className="admin-card p-8 text-center text-sm text-[#806b5a]">لا توجد طلبات توثيق Pro في Production.</div>
            : <div className="grid gap-4">{state.items.map((row) => (
              <button key={row.id} onClick={() => void openDetails(row)} className="admin-card flex w-full flex-col gap-4 p-5 text-right transition hover:border-[#d6a45d] md:flex-row md:items-center md:justify-between">
                <div className="min-w-0">
                  <div className="flex flex-wrap items-center gap-2">{statusBadge(row.status)}<Badge variant="outline" className="border-[#eadcc9] text-[#806b5a]">{paymentLabels[row.payment_status] ?? row.payment_status}</Badge></div>
                  <h3 className="mt-3 truncate text-base font-bold text-[#3f281d]">{row.store?.name_ar ?? `متجر ${row.store_id.slice(0, 8)}`}</h3>
                  <p className="mt-1 text-xs text-[#806b5a]">{row.merchant?.display_name ?? row.merchant_id} · أُنشئ {formatDate(row.created_at)}</p>
                </div>
                <div className="grid grid-cols-2 gap-3 text-xs text-[#806b5a] md:min-w-64"><div className="rounded-xl bg-[#fff7e9] p-3"><span className="block text-[#a37747]">المستندات</span><strong className="mt-1 block text-base text-[#4f2e1f]">{row.documents.length}</strong></div><div className="rounded-xl bg-[#fff7e9] p-3"><span className="block text-[#a37747]">الإرسال</span><strong className="mt-1 block text-base text-[#4f2e1f]">{formatDate(row.submitted_at)}</strong></div></div>
              </button>
            ))}</div>}

      {selected && <div className="admin-card space-y-5 p-6">
        <div className="flex flex-col gap-3 border-b border-[#eee1d0] pb-5 sm:flex-row sm:items-start sm:justify-between"><div><div className="flex items-center gap-2">{statusBadge(selected.status)}<ShieldCheck className="size-5 text-[#9c5a00]" /></div><h3 className="mt-2 text-xl font-bold text-[#3f281d]">{selected.store?.name_ar ?? "تفاصيل طلب التوثيق"}</h3><p className="mt-1 text-sm text-[#806b5a]">المستخدم: {selected.merchant?.display_name ?? selected.merchant_id}</p></div><Button onClick={() => { setSelected(null); setSelectedDetail(null); }} variant="ghost" className="text-[#806b5a]">إغلاق</Button></div>
        <div className="grid gap-3 text-sm text-[#6f5b4c] sm:grid-cols-3"><div><span className="font-semibold">الدفع:</span> {paymentLabels[selected.payment_status] ?? selected.payment_status}</div><div><span className="font-semibold">التقديم:</span> {formatDate(selected.submitted_at)}</div><div><span className="font-semibold">المراجعة:</span> {formatDate(selected.reviewed_at)}</div></div>
        <div className="rounded-2xl border border-[#eadcc9] bg-[#fffaf3] p-4">
          <div className="text-sm font-bold text-[#4f2e1f]">تسوية رسوم Pro</div>
          <p className="mt-1 text-xs leading-6 text-[#806b5a]">لا تُعتبر الرسوم مدفوعة بمجرد إرسال المرجع. هذه الأزرار تسجل قرار الإدارة فقط، ولا تنفذ عملية مالية خارجية.</p>
          <Input value={paymentReference} onChange={(event) => setPaymentReference(event.target.value)} placeholder="مرجع التحويل أو رقم العملية" className="mt-3 border-[#eadcc9] bg-white" />
          <div className="mt-3 flex flex-wrap gap-2">
            <Button disabled={busy} onClick={() => void reconcilePayment("paid")} className="bg-emerald-700 hover:bg-emerald-800">تأكيد الدفع</Button>
            <Button disabled={busy} onClick={() => void reconcilePayment("waived")} variant="outline" className="border-[#c9a36a] text-[#7a4e1f]">إعفاء إداري</Button>
            <Button disabled={busy} onClick={() => void reconcilePayment("failed")} variant="outline" className="border-red-200 text-red-800">تسجيل فشل</Button>
            <Button disabled={busy} onClick={() => void reconcilePayment("refunded")} variant="outline" className="border-red-300 text-red-900">تسجيل رد الرسوم</Button>
          </div>
        </div>
        <div className="grid gap-3 sm:grid-cols-2">{(selectedDetail?.documents ?? selected.documents).map((document) => <div key={document.id} className="rounded-2xl border border-[#eadcc9] bg-[#fffaf3] p-4"><div className="flex items-center gap-3"><FileText className="size-5 text-[#9c5a00]" /><div className="min-w-0"><p className="truncate text-sm font-bold text-[#4f2e1f]">{documentLabels[document.document_type] ?? document.document_type}</p><p className="truncate text-xs text-[#806b5a]">{document.file_name} · {document.review_status}</p></div></div>{document.signed_url && <a className="mt-3 inline-block text-xs font-bold text-[#8b5a2b] underline" href={document.signed_url} target="_blank" rel="noreferrer">فتح المستند في نافذة آمنة</a>}</div>)}</div>
        <label className="block text-sm font-semibold text-[#4f2e1f]">ملاحظة القرار<textarea value={note} onChange={(event) => setNote(event.target.value)} rows={3} className="mt-2 w-full rounded-2xl border border-[#eadcc9] bg-white p-3 text-sm outline-none focus:border-[#c77d1a]" placeholder="اكتب سبب القرار أو المعلومات المطلوبة" /></label>
        <div className="flex flex-wrap gap-2"><Button disabled={busy} onClick={() => void runAction("approve")} className="bg-emerald-700 hover:bg-emerald-800"><CheckCircle2 className="ml-2 size-4" />اعتماد التوثيق</Button><Button disabled={busy} onClick={() => void runAction("needs_more_info")} variant="outline" className="border-blue-200 text-blue-800">طلب استكمال</Button><Button disabled={busy} onClick={() => void runAction("reject")} variant="outline" className="border-red-200 text-red-800"><XCircle className="ml-2 size-4" />رفض</Button>{selected.status === "approved" && <Button disabled={busy} onClick={() => void runAction("revoke")} variant="outline" className="border-red-300 text-red-900">سحب الشارة</Button>}</div>
      </div>}
    </section>
  );
}
