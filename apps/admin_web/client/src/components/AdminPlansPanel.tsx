import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { RefreshCw, ShieldCheck, Sparkles, WalletCards } from "lucide-react";
import { adminApi } from "@/lib/admin-api";

type Plan = {
  id: string;
  code: string;
  name_ar: string;
  billing_interval: string;
  price_amount: number;
  currency: string;
  store_limit: number;
  product_limit: number;
  verification_included: number;
  entitlements: Record<string, unknown>;
  is_active: boolean;
};
type Campaign = { id: string; name_ar: string; discount_percent: number; discount_by_plan_code?: Record<string, number>; is_active: boolean; starts_at: string | null; ends_at: string | null; applies_to: string[] };
type Payment = { id: string; status: string; payment_type: string; final_amount: number; base_amount: number; discount_percent: number; currency: string; payment_reference: string | null; sender_name: string | null; created_at: string; plan?: { name_ar?: string | null } | null; store?: { name_ar?: string | null } | null };
type Subscription = { id: string; merchant_id: string; status: string; starts_at: string | null; ends_at: string | null; plan?: { name_ar?: string | null; code?: string | null } | null };
type DesignRequest = { id: string; title: string; status: string; description: string; store?: { name_ar?: string | null } | null; created_at: string };
type TransferSettings = { bank_name: string | null; beneficiary_name: string | null; account_number: string | null; iban: string | null; phone: string | null; instructions_ar: string | null; logo_url: string | null; is_active: boolean };
type MerchantUser = { id: string; email?: string | null; phone?: string | null; profile?: { display_name?: string | null; phone?: string | null; role?: string | null } | null; store?: { name_ar?: string | null } | null };

const statusLabels: Record<string, string> = {
  not_started: "لم يبدأ",
  proof_uploaded: "مستند مرفوع",
  under_review: "قيد المراجعة",
  confirmed: "مؤكد",
  failed: "فشل",
  refunded: "مسترد",
  waived: "معفى",
  pending: "معلق",
  active: "نشط",
  expired: "منتهٍ",
  cancelled: "ملغى",
  suspended: "موقوف",
  submitted: "مرسل",
  needs_more_info: "يحتاج معلومات",
  in_progress: "قيد التنفيذ",
  ready_for_review: "جاهز للمراجعة",
  completed: "مكتمل",
};

function statusText(value: string) {
  return statusLabels[value] ?? value;
}

function formatDate(value: string | null | undefined) {
  if (!value) return "—";
  return new Intl.DateTimeFormat("ar-SA", { dateStyle: "medium" }).format(new Date(value));
}

function PlanCard({ plan, launchDiscount, onRefresh }: { plan: Plan; launchDiscount: number; onRefresh: () => void }) {
  const discounted = Math.round(plan.price_amount * (1 - launchDiscount / 100) * 100) / 100;
  const tone = plan.code === "gold" ? "from-[#f4c76b] via-[#fff6d7] to-[#d89828]" : plan.code === "bronze_professional" ? "from-[#c98c54] via-[#fff4df] to-[#8d542d]" : "from-[#fff0d6] via-[#fffaf2] to-[#f4cf8a]";
  return <article className={`relative overflow-hidden rounded-[28px] border border-[#ead4b2] bg-gradient-to-br ${tone} p-5 shadow-[0_18px_45px_rgba(124,76,25,.11)]`}>
    <div className="absolute -left-10 -top-10 size-28 rounded-full bg-white/30 blur-2xl" />
    <div className="relative flex items-start justify-between gap-3"><div><p className="text-[10px] font-bold uppercase tracking-[.18em] text-[#8b5a2b]">خطة عسلكم</p><h3 className="mt-2 text-xl font-black text-[#4f2e1f]">{plan.name_ar}</h3></div><div className="grid size-11 place-items-center rounded-2xl bg-white/65 text-[#9c5a00]"><Sparkles className="size-5" /></div></div>
    <div className="relative mt-5 flex items-end gap-2"><span className="text-sm text-[#8d725a] line-through">{plan.price_amount.toFixed(2)} ر.س</span><span className="text-3xl font-black text-[#4f2e1f]">{discounted.toFixed(2)}</span><span className="pb-1 text-xs font-semibold text-[#79522e]">ر.س / {plan.billing_interval === "year" ? "سنة" : "شهر"}</span></div>
    <p className="relative mt-2 text-xs font-semibold text-[#8b5a2b]">السعر بعد خصم الافتتاح {launchDiscount}% — يعاد حسابه من الخادم</p>
    <div className="relative mt-5 grid grid-cols-2 gap-2 text-xs text-[#65442d]"><div className="rounded-xl bg-white/50 p-3"><strong className="block text-base text-[#4f2e1f]">{plan.store_limit}</strong>متجر</div><div className="rounded-xl bg-white/50 p-3"><strong className="block text-base text-[#4f2e1f]">{plan.product_limit}</strong>منتج نشط لكل متجر</div></div>
    <div className="relative mt-4 space-y-2 text-xs leading-6 text-[#65442d]"><p>✓ {plan.verification_included ? `توثيق ${plan.verification_included === 1 ? "متجر واحد" : `${plan.verification_included} متاجر`} مشمول` : "التوثيق يطلب منفصلًا"}</p><p>✓ {Number(plan.entitlements?.design_requests_per_cycle ?? 0) ? `طلب تصميم مخصص: ${plan.entitlements.design_requests_per_cycle}` : "لا تشمل خدمة التصميم"}</p><p>✓ تحليلات وأولوية ظهور حسب الخطة</p></div>
    <Button onClick={onRefresh} variant="outline" className="relative mt-5 w-full border-[#b9823e] bg-white/55 text-[#6f421f] hover:bg-white/80"><RefreshCw className="ml-2 size-4" />تحديث السعر من Production</Button>
  </article>;
}

export function AdminPlansPanel() {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [campaign, setCampaign] = useState<Campaign | null>(null);
  const [payments, setPayments] = useState<Payment[]>([]);
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [designRequests, setDesignRequests] = useState<DesignRequest[]>([]);
  const [users, setUsers] = useState<MerchantUser[]>([]);
  const [transfer, setTransfer] = useState<TransferSettings>({ bank_name: "", beneficiary_name: "", account_number: "", iban: "", phone: "", instructions_ar: "", logo_url: "", is_active: false });
  const [discountStandard, setDiscountStandard] = useState("10");
  const [discountProfessional, setDiscountProfessional] = useState("15");
  const [discountVerification, setDiscountVerification] = useState("10");
  const [selectedMerchantId, setSelectedMerchantId] = useState("");
  const [selectedPlanId, setSelectedPlanId] = useState("");
  const [manualNote, setManualNote] = useState("");
  const [loading, setLoading] = useState(false);

  const refresh = async () => {
    setLoading(true);
    try {
      const [planResult, campaignResult, paymentResult, subscriptionResult, designResult, transferResult, userResult] = await Promise.all([
        adminApi.subscriptionPlans(), adminApi.subscriptionCampaigns(), adminApi.paymentRequests({ page: 1, pageSize: 50 }), adminApi.subscriptions({ page: 1, pageSize: 50 }), adminApi.designRequests({ page: 1, pageSize: 50 }), adminApi.localTransferSettings(), adminApi.users(),
      ]);
      setPlans(planResult.items as Plan[]);
      const activeCampaign = (campaignResult.items as Campaign[]).find((item) => item.is_active) ?? (campaignResult.items[0] as Campaign | undefined) ?? null;
      setCampaign(activeCampaign);
      const rules = activeCampaign?.discount_by_plan_code ?? {};
      setDiscountStandard(String(rules.standard ?? 10));
      setDiscountProfessional(String(rules.bronze_professional ?? rules.gold ?? 15));
      setDiscountVerification(String(rules.verification ?? activeCampaign?.discount_percent ?? 10));
      setPayments(paymentResult.items as Payment[]);
      setSubscriptions(subscriptionResult.items as Subscription[]);
      setDesignRequests(designResult.items as DesignRequest[]);
      setUsers(userResult.items as MerchantUser[]);
      if (transferResult.item) setTransfer(transferResult.item as TransferSettings);
    } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر قراءة إعدادات الخطط."); } finally { setLoading(false); }
  };

  useEffect(() => { void refresh(); }, []);
  const paidPlans = useMemo(() => plans.filter((plan) => plan.price_amount > 0), [plans]);
  const planDiscount = (code: string) => campaign?.is_active ? Number(campaign.discount_by_plan_code?.[code] ?? campaign.discount_percent) : 0;
  const campaignInput = (isActive: boolean) => ({ discountPercent: Number(discountVerification), discountByPlanCode: { standard: Number(discountStandard), bronze_professional: Number(discountProfessional), gold: Number(discountProfessional), verification: Number(discountVerification) }, isActive, appliesTo: campaign?.applies_to ?? ["subscription", "verification"] });
  const saveCampaign = async () => {
    try { await adminApi.updateLaunchCampaign(campaignInput(campaign?.is_active ?? false)); toast.success("تم حفظ قواعد حملة الافتتاح."); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ الحملة."); }
  };
  const toggleCampaign = async () => {
    try { await adminApi.updateLaunchCampaign(campaignInput(!(campaign?.is_active ?? false))); toast.success(campaign?.is_active ? "تم إيقاف الخصم للطلبات الجديدة." : "تم تفعيل خصم الافتتاح."); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تعديل الحملة."); }
  };
  const saveTransfer = async () => {
    try { await adminApi.updateLocalTransferSettings({ bankName: transfer.bank_name, beneficiaryName: transfer.beneficiary_name, accountNumber: transfer.account_number, iban: transfer.iban, phone: transfer.phone, instructionsAr: transfer.instructions_ar, logoUrl: transfer.logo_url, isActive: transfer.is_active }); toast.success("تم حفظ إعدادات الحوالة."); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ إعدادات الحوالة."); }
  };
  const reconcile = async (payment: Payment, status: "confirmed" | "failed" | "refunded") => {
    const note = window.prompt("ملاحظة المراجعة (اختيارية):", "");
    if (note === null) return;
    try { await adminApi.reconcilePaymentRequest(payment.id, { status, note }); toast.success(status === "confirmed" ? "تم تأكيد الحوالة وتفعيل الخطة." : "تم تحديث حالة طلب الدفع."); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تسوية طلب الدفع."); }
  };
  const setSubscription = async (subscription: Subscription, status: "active" | "suspended" | "cancelled") => {
    const note = window.prompt("سبب القرار (اختياري):", "");
    if (note === null) return;
    try { await adminApi.setSubscriptionStatus(subscription.id, { status, note }); toast.success("تم تحديث حالة الخطة وإرسال الإشعار."); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تحديث الخطة."); }
  };
  const updateDesign = async (request: DesignRequest, status: string) => {
    try { await adminApi.updateDesignRequest(request.id, { status }); toast.success("تم تحديث طلب التصميم."); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تحديث طلب التصميم."); }
  };
  const manualActivate = async () => {
    if (!selectedMerchantId || !selectedPlanId) { toast.error("اختر المستخدم والباقة أولًا."); return; }
    try { await adminApi.activateSubscriptionForUser({ merchantId: selectedMerchantId, planId: selectedPlanId, note: manualNote }); toast.success("تم تفعيل الباقة للمستخدم وإرسال الإشعار."); setManualNote(""); await refresh(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تفعيل الباقة يدويًا."); }
  };
  const openProof = async (payment: Payment) => {
    const tab = window.open("about:blank", "_blank");
    try {
      const result = await adminApi.paymentRequest(payment.id);
      const proofUrl = (result.item as { proof_url?: string | null }).proof_url;
      if (!proofUrl) { tab?.close(); toast.error("لا يوجد سند مرفوع لهذا الطلب."); return; }
      if (tab) tab.location.href = proofUrl; else window.open(proofUrl, "_blank", "noopener,noreferrer");
    } catch (error) { tab?.close(); toast.error(error instanceof Error ? error.message : "تعذر فتح سند الحوالة."); }
  };

  return <div className="space-y-6">
    <section className="rounded-[28px] border border-[#eadcc9] bg-[#5b3623] p-6 text-white shadow-[0_20px_55px_rgba(79,46,31,.14)]"><div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between"><div><p className="text-xs font-bold tracking-[.16em] text-[#ffe4b0]">الخطط والحملة</p><h2 className="mt-2 text-2xl font-black">تفعيل المزايا من مصدر Production</h2><p className="mt-2 max-w-2xl text-sm leading-7 text-[#f8e6cb]">السعر النهائي يعاد حسابه في الخادم، وتأكيد الحوالة وحده ينشئ الاشتراك الفعال ويرسل إشعارًا للتاجر.</p></div><Button onClick={() => void refresh()} disabled={loading} className="bg-[#f39c12] text-[#4f2e1f] hover:bg-[#ffb340]"><RefreshCw className={`ml-2 size-4 ${loading ? "animate-spin" : ""}`} />تحديث كل الطلبات</Button></div></section>
    <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">{plans.map((plan) => <PlanCard key={plan.id} plan={plan} launchDiscount={planDiscount(plan.code)} onRefresh={() => void refresh()} />)}</section>
    <section className="grid gap-5 xl:grid-cols-[minmax(0,1fr)_minmax(320px,.75fr)]"><div className="admin-card p-6"><div className="flex items-start justify-between gap-3"><div><p className="section-kicker">إدارة الخصم</p><h3 className="mt-1 text-xl font-bold text-[#342118]">حملة افتتاح التطبيق</h3></div><Badge variant="outline" className={campaign?.is_active ? "border-emerald-300 bg-emerald-50 text-emerald-800" : "border-slate-300 bg-slate-50 text-slate-700"}>{campaign?.is_active ? "نشطة" : "متوقفة"}</Badge></div><div className="mt-5 grid gap-3 sm:grid-cols-3"><label className="text-sm font-semibold text-[#5f4636]">العادية<input value={discountStandard} onChange={(event) => setDiscountStandard(event.target.value)} type="number" min="0" max="100" className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3" /></label><label className="text-sm font-semibold text-[#5f4636]">Bronze وGold<input value={discountProfessional} onChange={(event) => setDiscountProfessional(event.target.value)} type="number" min="0" max="100" className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3" /></label><label className="text-sm font-semibold text-[#5f4636]">التوثيق<input value={discountVerification} onChange={(event) => setDiscountVerification(event.target.value)} type="number" min="0" max="100" className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3" /></label></div><div className="mt-4 flex flex-wrap gap-3"><Button onClick={() => void saveCampaign()} className="bg-[#4f2e1f] hover:bg-[#6b412a]">حفظ قواعد الخصم</Button><Button onClick={() => void toggleCampaign()} variant="outline" className="border-[#cda36d] text-[#76502e]">{campaign?.is_active ? "إيقاف الخصم" : "تفعيل الخصم"}</Button></div><p className="mt-4 text-xs leading-6 text-[#806b5a]">لا تتغير الطلبات التي دُفعت أو فُعّلت عند إيقاف الحملة. الخصم السنوي مضمّن في سعر السنة، ولا يُراكم خصمًا آخر.</p></div><div className="admin-card p-6"><div className="flex items-center gap-2 text-[#9c5a00]"><WalletCards className="size-5" /><h3 className="text-lg font-bold text-[#342118]">الدفع المتاح</h3></div><p className="mt-3 text-sm leading-7 text-[#806b5a]">الحوالة المحلية فقط. خيار البطاقة مصمم ومجمّد خادميًا، ولا توجد حقول بطاقة أو بيانات حساسة في هذا المسار.</p><div className="mt-4 rounded-2xl bg-[#fff7e9] p-4 text-sm text-[#6f4b2d]">{transfer.is_active ? `الحساب النشط: ${transfer.bank_name ?? "غير محدد"}` : "لم تُفعّل بيانات الحوالة بعد."}</div></div></section>
    <section className="admin-card p-6"><div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between"><div><p className="section-kicker">دورة يدوية آمنة</p><h3 className="mt-1 text-xl font-bold text-[#342118]">تفعيل باقة لمستخدم</h3><p className="mt-2 text-sm leading-7 text-[#806b5a]">تحقق من وصول الحوالة خارج التطبيق، ثم اختر المستخدم والباقة. سيُنشأ الاشتراك ويصل إشعار التفعيل فورًا.</p></div><ShieldCheck className="size-7 text-[#9c5a00]" /></div><div className="mt-5 grid gap-3 lg:grid-cols-[1fr_1fr_1.2fr_auto] lg:items-end"><label className="text-sm font-semibold text-[#5f4636]">المستخدم<select value={selectedMerchantId} onChange={(event) => setSelectedMerchantId(event.target.value)} className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"><option value="">اختر حسابًا حقيقيًا</option>{users.map((user) => <option key={user.id} value={user.id}>{user.profile?.display_name ?? user.email ?? user.id}{user.store?.name_ar ? ` — ${user.store.name_ar}` : ""}</option>)}</select></label><label className="text-sm font-semibold text-[#5f4636]">الباقة<select value={selectedPlanId} onChange={(event) => setSelectedPlanId(event.target.value)} className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"><option value="">اختر الباقة</option>{paidPlans.map((plan) => <option key={plan.id} value={plan.id}>{plan.name_ar} — {plan.price_amount.toFixed(2)} ر.س / {plan.billing_interval === "year" ? "سنة" : "شهر"}</option>)}</select></label><label className="text-sm font-semibold text-[#5f4636]">ملاحظة المراجعة<input value={manualNote} onChange={(event) => setManualNote(event.target.value)} className="mt-2 h-11 w-full rounded-xl border border-[#eadcc9] bg-white px-3" placeholder="مثال: تمت مطابقة الحوالة البنكية" /></label><Button onClick={() => void manualActivate()} className="h-11 bg-[#4f2e1f] hover:bg-[#6b412a]">تفعيل وإشعار</Button></div></section>
    <section className="admin-card p-6"><div className="flex items-center gap-2"><WalletCards className="size-5 text-[#9c5a00]" /><h3 className="text-xl font-bold text-[#342118]">إعدادات الحوالة المحلية</h3></div><div className="mt-5 grid gap-3 md:grid-cols-2"><Input value={transfer.bank_name ?? ""} onChange={(event) => setTransfer({ ...transfer, bank_name: event.target.value })} placeholder="اسم البنك" /><Input value={transfer.beneficiary_name ?? ""} onChange={(event) => setTransfer({ ...transfer, beneficiary_name: event.target.value })} placeholder="اسم المستفيد" /><Input value={transfer.account_number ?? ""} onChange={(event) => setTransfer({ ...transfer, account_number: event.target.value })} placeholder="رقم الحساب" /><Input value={transfer.iban ?? ""} onChange={(event) => setTransfer({ ...transfer, iban: event.target.value })} placeholder="الآيبان" /><Input value={transfer.phone ?? ""} onChange={(event) => setTransfer({ ...transfer, phone: event.target.value })} placeholder="رقم الهاتف" /><Input value={transfer.logo_url ?? ""} onChange={(event) => setTransfer({ ...transfer, logo_url: event.target.value })} placeholder="رابط الشعار الرسمي (اختياري)" /></div><textarea value={transfer.instructions_ar ?? ""} onChange={(event) => setTransfer({ ...transfer, instructions_ar: event.target.value })} className="mt-3 min-h-24 w-full rounded-xl border border-[#eadcc9] bg-white p-3 text-sm" placeholder="تعليمات الحوالة" /><div className="mt-4 flex flex-wrap items-center gap-3"><label className="flex items-center gap-2 text-sm text-[#6f5b4c]"><input checked={transfer.is_active} onChange={(event) => setTransfer({ ...transfer, is_active: event.target.checked })} type="checkbox" />إظهار بيانات الحوالة للتجار</label><Button onClick={() => void saveTransfer()} className="bg-[#4f2e1f] hover:bg-[#6b412a]">حفظ إعدادات الحوالة</Button></div></section>
    <section className="admin-card overflow-hidden"><div className="flex items-center justify-between border-b border-[#eee1d0] px-5 py-5"><div><p className="section-kicker">المراجعة المالية</p><h3 className="mt-1 text-xl font-bold text-[#342118]">طلبات الحوالة</h3></div><Badge variant="outline" className="border-[#e3c28d] text-[#8b5a2b]">{payments.length} طلب</Badge></div>{payments.length === 0 ? <p className="px-5 py-10 text-center text-sm text-[#806b5a]">لا توجد طلبات حوالة حقيقية حاليًا.</p> : <div className="divide-y divide-[#f1e7da]">{payments.map((payment) => <div key={payment.id} className="flex flex-col gap-3 px-5 py-4 lg:flex-row lg:items-center lg:justify-between"><div><p className="font-semibold text-[#432a1e]">{payment.plan?.name_ar ?? payment.payment_type} — {payment.store?.name_ar ?? "بدون متجر"}</p><p className="mt-1 text-xs text-[#806b5a]">{payment.sender_name ?? "مرسل غير محدد"} · {payment.payment_reference ?? "بدون مرجع"} · {formatDate(payment.created_at)}</p></div><div className="flex items-center gap-2"><span className="text-sm font-bold text-[#5f402a]">{payment.final_amount.toFixed(2)} {payment.currency}</span><Badge variant="outline">{statusText(payment.status)}</Badge><Button onClick={() => void openProof(payment)} size="sm" variant="outline" className="border-[#d5ae76] text-[#76502e]">فتح سند الحوالة</Button>{["proof_uploaded", "under_review"].includes(payment.status) && <><Button onClick={() => void reconcile(payment, "confirmed")} size="sm" className="bg-emerald-700 hover:bg-emerald-800">تأكيد وتفعيل</Button><Button onClick={() => void reconcile(payment, "failed")} size="sm" variant="outline" className="border-red-200 text-red-800">رفض</Button></>}</div></div>)}</div>}</section>
    <section className="grid gap-5 xl:grid-cols-2"><div className="admin-card overflow-hidden"><div className="border-b border-[#eee1d0] px-5 py-5"><div className="flex items-center gap-2"><ShieldCheck className="size-5 text-[#9c5a00]" /><h3 className="text-xl font-bold text-[#342118]">الخطط المفعلة</h3></div></div>{subscriptions.length === 0 ? <p className="px-5 py-10 text-center text-sm text-[#806b5a]">لا توجد خطط مفعلة أو معلقة حاليًا.</p> : <div className="divide-y divide-[#f1e7da]">{subscriptions.map((subscription) => <div key={subscription.id} className="flex items-center justify-between gap-3 px-5 py-4"><div><p className="font-semibold text-[#432a1e]">{subscription.plan?.name_ar ?? "خطة"}</p><p className="mt-1 text-xs text-[#806b5a]">{subscription.merchant_id} · حتى {formatDate(subscription.ends_at)}</p></div><div className="flex items-center gap-2"><Badge variant="outline">{statusText(subscription.status)}</Badge>{subscription.status === "active" && <Button onClick={() => void setSubscription(subscription, "suspended")} size="sm" variant="outline" className="border-red-200 text-red-800">إيقاف</Button>}{subscription.status !== "active" && <Button onClick={() => void setSubscription(subscription, "active")} size="sm" className="bg-[#4f2e1f] hover:bg-[#6b412a]">تفعيل</Button>}</div></div>)}</div>}</div><div className="admin-card overflow-hidden"><div className="border-b border-[#eee1d0] px-5 py-5"><div className="flex items-center gap-2"><Sparkles className="size-5 text-[#9c5a00]" /><h3 className="text-xl font-bold text-[#342118]">طلبات التصميم المخصص</h3></div></div>{designRequests.length === 0 ? <p className="px-5 py-10 text-center text-sm text-[#806b5a]">لا توجد طلبات تصميم حقيقية حاليًا.</p> : <div className="divide-y divide-[#f1e7da]">{designRequests.map((request) => <div key={request.id} className="flex flex-col gap-3 px-5 py-4"><div className="flex items-start justify-between gap-3"><div><p className="font-semibold text-[#432a1e]">{request.title}</p><p className="mt-1 text-xs text-[#806b5a]">{request.store?.name_ar ?? "متجر"} · {formatDate(request.created_at)}</p></div><Badge variant="outline">{statusText(request.status)}</Badge></div><div className="flex flex-wrap gap-2"><Button onClick={() => void updateDesign(request, "in_progress")} size="sm" variant="outline" className="border-[#d5ae76] text-[#76502e]">بدء التنفيذ</Button><Button onClick={() => void updateDesign(request, "needs_more_info")} size="sm" variant="outline" className="border-blue-200 text-blue-800">طلب معلومات</Button><Button onClick={() => void updateDesign(request, "completed")} size="sm" className="bg-emerald-700 hover:bg-emerald-800">إكمال الطلب</Button></div></div>)}</div>}</div></section>
  </div>;
}
