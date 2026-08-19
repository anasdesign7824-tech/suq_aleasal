import { useEffect, useMemo, useState } from "react";
import {
  Bell,
  Box,
  ChevronLeft,
  ClipboardList,
  Download,
  Filter,
  Handshake,
  Hexagon,
  ImagePlus,
  Layers3,
  LayoutDashboard,
  History,
  UserCog,
  Users,
  BellRing,
  Trash2,
  BarChart3,
  Menu,
  MoreHorizontal,
  PackageCheck,
  RefreshCw,
  Search,
  ShieldCheck,
  Sparkles,
  Store,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { adminApi, type AdminSessionPayload } from "@/lib/admin-api";
import { BannersPanel, TaxonomyPanel } from "@/components/AdminOperations";
import { AdminUsersPanel, AuditPanel } from "@/components/AdminGovernance";
import { AdminCreationPanel } from "@/components/AdminCreationPanel";
import { ProductCreationPanel } from "@/components/ProductCreationPanel";
import { AnalyticsPanel, NotificationsPanel, UsersPanel } from "@/components/AdminPeople";
import { MerchantApplicationsPanel } from "@/components/AdminMerchantApplications";

type ViewKey = "overview" | "products" | "stores" | "requests" | "merchant-applications" | "banners" | "taxonomy" | "admins" | "audit" | "users" | "notifications" | "analytics";
type ProductRow = { id: string; store_id: string; taxonomy_id?: string | null; name_ar: string; name_en?: string | null; description?: string | null; product_type: string; status: string; is_featured: boolean; metadata?: Record<string, unknown> };
type StoreRow = { id: string; merchant_id?: string | null; name_ar: string; description?: string | null; status: string; is_verified: boolean; region_id?: string | null; logo_url?: string | null; cover_url?: string | null };
type RequestRow = { id: string; subject: string; body?: string | null; status: string; created_at: string };
type MerchantApplicationRow = { id: string; user_id: string; display_name: string; experience?: string | null; location?: string | null; phone?: string | null; specialties?: unknown; certificate_note?: string | null; status: string; review_note?: string | null; submitted_at: string };
type LoadState<T> = { data: T | null; loading: boolean; error: string | null };

const navItems: Array<{ key: ViewKey; label: string; icon: typeof LayoutDashboard }> = [
  { key: "overview", label: "نظرة عامة", icon: LayoutDashboard },
  { key: "products", label: "الكتالوج", icon: Box },
  { key: "stores", label: "المتاجر", icon: Store },
  { key: "requests", label: "طلبات التواصل", icon: ClipboardList },
  { key: "merchant-applications", label: "طلبات التجار", icon: Handshake },
  { key: "banners", label: "البنرات", icon: ImagePlus },
  { key: "taxonomy", label: "التصنيفات", icon: Layers3 },
  { key: "admins", label: "المديرون", icon: UserCog },
  { key: "audit", label: "سجل التدقيق", icon: History },
  { key: "users", label: "المستخدمون", icon: Users },
  { key: "notifications", label: "الإشعارات", icon: BellRing },
  { key: "analytics", label: "الإحصاءات", icon: BarChart3 },
];

const statusLabels: Record<string, { label: string; className: string }> = {
  open: { label: "جديد", className: "border-amber-300 bg-amber-50 text-amber-800" },
  answered: { label: "تم الرد", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  in_progress: { label: "قيد المتابعة", className: "border-blue-300 bg-blue-50 text-blue-800" },
  closed: { label: "مغلق", className: "border-slate-300 bg-slate-50 text-slate-700" },
  active: { label: "نشط", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  pending: { label: "قيد المراجعة", className: "border-amber-300 bg-amber-50 text-amber-800" },
  approved: { label: "معتمد", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
  needs_more_info: { label: "يحتاج معلومات", className: "border-blue-300 bg-blue-50 text-blue-800" },
  rejected: { label: "مرفوض", className: "border-red-300 bg-red-50 text-red-800" },
  suspended: { label: "موقوف", className: "border-red-300 bg-red-50 text-red-800" },
  draft: { label: "مسودة", className: "border-slate-300 bg-slate-50 text-slate-700" },
};

function AssalkomLogo() {
  return <div className="flex items-center gap-3"><div className="grid size-12 place-items-center rounded-2xl bg-[#fffaf0] text-[#9c5a00] shadow-[0_8px_22px_rgba(243,156,18,.20)]"><Hexagon className="size-7" /></div><div><p className="text-xl font-bold tracking-tight text-[#fffaf0]">عسلكم</p><p className="mt-0.5 text-[10px] font-medium tracking-[.22em] text-[#f8d59c]">SOUQ AL ASSAL</p></div></div>;
}

function statusBadge(status: string) {
  const style = statusLabels[status] ?? { label: status, className: "border-[#d8c7b6] bg-[#faf6f0] text-[#816b58]" };
  return <Badge variant="outline" className={style.className}>{style.label}</Badge>;
}

function EmptyState({ title, description, onRefresh }: { title: string; description: string; onRefresh?: () => void }) {
  return <div className="flex min-h-48 flex-col items-center justify-center px-6 py-10 text-center"><div className="grid size-12 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><Hexagon className="size-5" /></div><h3 className="mt-4 text-base font-bold text-[#4f2e1f]">{title}</h3><p className="mt-1 max-w-md text-sm leading-7 text-[#806b5a]">{description}</p>{onRefresh && <Button variant="outline" onClick={onRefresh} className="mt-4 border-[#e3c28d] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button>}</div>;
}

function LoadingState() {
  return <div className="flex min-h-48 items-center justify-center px-6 py-10 text-sm font-semibold text-[#806b5a]"><RefreshCw className="ml-2 size-4 animate-spin text-[#c77d1a]" />جارٍ قراءة المصدر الحقيقي…</div>;
}

function ErrorState({ message, onRefresh }: { message: string; onRefresh: () => void }) {
  return <div className="flex min-h-48 flex-col items-center justify-center px-6 py-10 text-center"><div className="grid size-12 place-items-center rounded-2xl bg-red-50 text-red-700"><ShieldCheck className="size-5" /></div><h3 className="mt-4 text-base font-bold text-[#4f2e1f]">تعذر قراءة المصدر</h3><p className="mt-1 max-w-md text-sm leading-7 text-[#806b5a]">{message}</p><Button variant="outline" onClick={onRefresh} className="mt-4 border-red-200 text-red-800"><RefreshCw className="ml-2 size-4" />إعادة المحاولة</Button></div>;
}

function MetricCard({ label, value, note, icon: Icon, tone }: { label: string; value: number | string; note: string; icon: typeof PackageCheck; tone: string }) {
  const toneClass = { gold: "bg-[#fff0d6] text-[#9c5a00]", brown: "bg-[#f3e9df] text-[#4f2e1f]", cream: "bg-[#f6f0e8] text-[#87623c]", olive: "bg-[#eaf0e6] text-[#4f7a45]" }[tone] ?? "bg-[#fff0d6] text-[#9c5a00]";
  return <article className="admin-card group min-w-0 p-5"><div className="flex items-start justify-between gap-3"><div className={`grid h-11 w-11 place-items-center rounded-2xl ${toneClass}`}><Icon size={20} /></div><span className="rounded-full border border-[#b7dfc2] bg-[#effaf1] px-2.5 py-1 text-[10px] font-semibold text-[#26733d]">Production</span></div><p className="mt-6 text-3xl font-bold text-[#342118]" dir="ltr">{value}</p><p className="mt-1.5 text-sm font-semibold text-[#4f2e1f]">{label}</p><p className="mt-1 text-xs text-[#8e7a68]">{note}</p></article>;
}

function ProductTable({ state, onRefresh, onDelete, onSelect, compact = false }: { state: LoadState<ProductRow[]>; onRefresh: () => void; onDelete?: (id: string) => Promise<void>; onSelect?: (product: ProductRow) => void; compact?: boolean }) {
  const [query, setQuery] = useState("");
  const products = useMemo(() => (state.data ?? []).filter((product) => product.name_ar.includes(query.trim())).slice(0, compact ? 5 : 50), [compact, query, state.data]);
  return <section className="admin-card overflow-hidden"><div className="flex flex-col gap-4 border-b border-[#eee1d0] px-5 py-5 lg:flex-row lg:items-center lg:justify-between"><div><div className="section-kicker">الكتالوج</div><h2 className="mt-1 text-xl font-bold text-[#342118]">{compact ? "آخر المنتجات المنشورة" : "إدارة الكتالوج"}</h2></div><div className="flex flex-col gap-2 sm:flex-row"><div className="relative"><Search className="absolute right-3 top-1/2 size-4 -translate-y-1/2 text-[#9a897d]" /><Input value={query} onChange={(event) => setQuery(event.target.value)} className="h-10 w-full rounded-xl border-[#eadcc9] pr-9 sm:w-52" placeholder="ابحث باسم المنتج" /></div><Button variant="outline" onClick={onRefresh} className="h-10 border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div></div>{state.loading ? <LoadingState /> : state.error ? <ErrorState message={state.error} onRefresh={onRefresh} /> : products.length === 0 ? <EmptyState title="لا توجد منتجات منشورة" description="ستظهر المنتجات هنا تلقائيًا بعد إدخالها ومراجعتها من الإدارة أو المتجر المصرح." onRefresh={onRefresh} /> : <div className="overflow-x-auto"><Table><TableHeader><TableRow className="border-[#eee1d0] hover:bg-transparent"><TableHead className="text-right text-[#806755]">المنتج</TableHead><TableHead className="text-right text-[#806755]">النوع</TableHead><TableHead className="text-right text-[#806755]">الحالة</TableHead><TableHead className="text-left text-[#806755]">إجراء</TableHead></TableRow></TableHeader><TableBody>{products.map((product) => <TableRow className="border-[#f2e8dc]" key={product.id}><TableCell className="min-w-48 py-4"><div className="flex items-center gap-3"><div className="grid size-9 place-items-center rounded-xl bg-[#fff0d6]"><Hexagon className="size-4 text-[#9c5a00]" /></div><span className="font-semibold text-[#432a1e]">{product.name_ar}</span></div></TableCell><TableCell className="text-sm text-[#705a49]">{product.product_type}</TableCell><TableCell>{statusBadge(product.status)}</TableCell><TableCell className="text-left"><div className="flex items-center justify-end gap-1">{onSelect && <Button onClick={() => onSelect(product)} variant="ghost" size="icon" className="text-[#8b5a2b]"><MoreHorizontal className="size-5" /><span className="sr-only">استعراض تفاصيل المنتج</span></Button>}{onDelete && <Button onClick={() => void onDelete(product.id)} variant="ghost" size="icon" className="text-red-800"><Trash2 className="size-4" /><span className="sr-only">حذف المنتج</span></Button>}</div></TableCell></TableRow>)}</TableBody></Table></div>}</section>;
}

function RequestsPanel({ state, onSelect, onRefresh }: { state: LoadState<RequestRow[]>; onSelect: (request: RequestRow) => void; onRefresh: () => void }) {
  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between gap-4 border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">متابعة</div><h2 className="mt-1 text-xl font-bold text-[#342118]">طلبات التواصل</h2></div><div className="flex items-center gap-2"><Button onClick={onRefresh} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button><div className="grid size-14 place-items-center rounded-2xl bg-[#fff8ed] text-[#9c5a00]"><Handshake className="size-6" /></div></div></div>{state.loading ? <LoadingState /> : state.error ? <ErrorState message={state.error} onRefresh={onRefresh} /> : (state.data ?? []).length === 0 ? <EmptyState title="لا توجد طلبات تواصل" description="ستظهر الطلبات هنا عندما يرسل العملاء طلبات حقيقية من التطبيق." onRefresh={onRefresh} /> : <div className="divide-y divide-[#f1e7da]">{(state.data ?? []).map((request) => <button className="group flex w-full items-center gap-3 px-5 py-4 text-right transition-colors hover:bg-[#fffaf3]" key={request.id} onClick={() => onSelect(request)}><div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-[#f4ece1] text-[#8b5a2b]"><Handshake className="size-4" /></div><div className="min-w-0 flex-1"><p className="truncate text-sm font-semibold text-[#432a1e]">{request.subject}</p><p className="mt-0.5 truncate text-xs text-[#8e7a68]">{request.body ?? "بدون وصف"}</p></div>{statusBadge(request.status)}<ChevronLeft className="size-4 text-[#b39e8c] transition-transform group-hover:-translate-x-0.5" /></button>)}</div>}</section>;
}

function StoresPanel({ state, onRefresh, onModerate, onDelete, onSelect }: { state: LoadState<StoreRow[]>; onRefresh: () => void; onModerate: (id: string, action: "approve" | "reject" | "suspend" | "reactivate") => Promise<void>; onDelete: (id: string) => Promise<void>; onSelect?: (store: StoreRow) => void }) {
  return <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">{state.loading ? <div className="admin-card md:col-span-2 xl:col-span-3"><LoadingState /></div> : state.error ? <div className="admin-card md:col-span-2 xl:col-span-3"><ErrorState message={state.error} onRefresh={onRefresh} /></div> : (state.data ?? []).length === 0 ? <div className="admin-card md:col-span-2 xl:col-span-3"><EmptyState title="لا توجد متاجر في Production" description="قاعدة البيانات الحالية لا تحتوي متاجر. ستظهر المتاجر هنا بعد إنشاء طلب حقيقي واعتماده." onRefresh={onRefresh} /></div> : (state.data ?? []).map((store) => <article className="admin-card relative overflow-hidden p-6" key={store.id}><div className="absolute left-0 top-0 h-20 w-20 rounded-br-[42px] bg-[#fff0d6]" /><div className="relative flex items-start justify-between"><div className="grid size-12 place-items-center rounded-2xl bg-[#4f2e1f] text-[#f7c769]"><Store className="size-5" /></div>{statusBadge(store.status)}</div><h3 className="relative mt-8 text-lg font-bold text-[#3f281d]">{store.name_ar}</h3><p className="relative mt-2 min-h-12 text-sm leading-6 text-[#806b5a]">{store.description ?? "لا يوجد وصف للمتجر."}</p><div className="relative mt-5 flex items-center justify-between border-t border-[#f1e6da] pt-4"><span className="text-xs text-[#876f5c]">{store.is_verified ? "متجر موثق" : "يحتاج مراجعة"}</span><div className="flex items-center gap-1">{onSelect && <Button onClick={() => onSelect(store)} variant="ghost" size="sm" className="text-[#8b5a2b]">استعراض التفاصيل<ChevronLeft className="mr-1 size-4" /></Button>}{store.status === "pending" && <Button onClick={() => void onModerate(store.id, "approve")} variant="outline" size="sm" className="border-emerald-200 text-emerald-800">اعتماد</Button>}{store.status === "active" && <Button onClick={() => void onModerate(store.id, "suspend")} variant="outline" size="sm" className="border-red-200 text-red-800">إيقاف</Button>}<Button onClick={() => void onDelete(store.id)} variant="outline" size="sm" className="border-red-200 text-red-800"><Trash2 className="ml-1 size-3.5" />حذف</Button></div></div></article>)}</section>;
}

function downloadSnapshot(snapshot: { counts: Record<string, number>; generatedAt: string }) {
  const rows = [["metric", "value"], ...Object.entries(snapshot.counts), ["generated_at", snapshot.generatedAt]];
  const csv = rows.map((row) => row.map((value) => `"${String(value).replaceAll('"', '""')}"`).join(",")).join("\n");
  const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "assalkom-production-overview.csv";
  anchor.click();
  URL.revokeObjectURL(url);
}

export default function Home({ session, onLogout }: { session: AdminSessionPayload; onLogout: () => Promise<void> }) {
  const [activeView, setActiveView] = useState<ViewKey>("overview");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<RequestRow | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<ProductRow | null>(null);
  const [selectedStore, setSelectedStore] = useState<StoreRow | null>(null);
  const [replyBody, setReplyBody] = useState("");
  const [overview, setOverview] = useState<LoadState<{ counts: Record<string, number>; generatedAt: string }>>({ data: null, loading: true, error: null });
  const [products, setProducts] = useState<LoadState<ProductRow[]>>({ data: null, loading: true, error: null });
  const [stores, setStores] = useState<LoadState<StoreRow[]>>({ data: null, loading: true, error: null });
  const [requests, setRequests] = useState<LoadState<RequestRow[]>>({ data: null, loading: true, error: null });
  const [merchantApplications, setMerchantApplications] = useState<LoadState<MerchantApplicationRow[]>>({ data: null, loading: true, error: null });

  const load = async <T,>(loader: () => Promise<T>, setter: (state: LoadState<T> | ((previous: LoadState<T>) => LoadState<T>)) => void) => {
    setter((previous: LoadState<T>) => ({ ...previous, loading: true, error: null }));
    try {
      setter({ data: await loader(), loading: false, error: null });
    } catch (error) {
      setter({ data: null, loading: false, error: error instanceof Error ? error.message : "تعذر قراءة المصدر." });
    }
  };

  const refreshOverview = () => void load(adminApi.overview, setOverview);
  const refreshProducts = () => void load(async () => (await adminApi.products({ page: 1, pageSize: 50 })).items as ProductRow[], setProducts);
  const refreshStores = () => void load(async () => (await adminApi.stores({ page: 1, pageSize: 50 })).items as StoreRow[], setStores);
  const refreshRequests = () => void load(async () => (await adminApi.requests({ page: 1, pageSize: 50 })).items as RequestRow[], setRequests);
  const refreshMerchantApplications = () => void load(async () => (await adminApi.merchantApplications({ page: 1, pageSize: 50 })).items as MerchantApplicationRow[], setMerchantApplications);
  const moderateStore = async (id: string, action: "approve" | "reject" | "suspend" | "reactivate") => { try { await adminApi.moderateStore(id, action); toast.success("تم تحديث حالة المتجر."); refreshStores(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تحديث المتجر."); } };
  const deleteStore = async (id: string) => { if (!window.confirm("حذف المتجر نهائيًا؟ ستُحذف المنتجات التابعة له وفق قيود Production.")) return; try { await adminApi.deleteStore(id); toast.success("تم حذف المتجر."); refreshStores(); refreshProducts(); refreshOverview(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حذف المتجر."); } };
  const deleteProduct = async (id: string) => { if (!window.confirm("حذف المنتج نهائيًا؟")) return; try { await adminApi.deleteProduct(id); toast.success("تم حذف المنتج."); refreshProducts(); refreshOverview(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حذف المنتج."); } };
  const answerSelectedRequest = async (event: React.FormEvent) => { event.preventDefault(); if (!selectedRequest || !replyBody.trim()) return; try { await adminApi.answerRequest(selectedRequest.id, replyBody); toast.success("تم إرسال الرد وتحديث حالة الطلب."); setReplyBody(""); setSelectedRequest(null); refreshRequests(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر إرسال الرد."); } };

  useEffect(() => { refreshOverview(); refreshProducts(); refreshStores(); refreshRequests(); refreshMerchantApplications(); }, []);

  const titles: Record<ViewKey, { eyebrow: string; title: string; subtitle: string }> = {
    overview: { eyebrow: "لوحة التشغيل", title: "صباح الخير، فريق عسلكم", subtitle: "إليك لقطة مباشرة من مصدر Supabase Production." },
    products: { eyebrow: "بيانات الإنتاج", title: "إدارة الكتالوج", subtitle: "بيانات المنتجات الحقيقية مع حالات الفراغ والمراجعة." },
    stores: { eyebrow: "شبكة التجار", title: "المتاجر الإنتاجية", subtitle: "المتاجر التي وصلت من المصدر الحقيقي وحالات اعتمادها." },
    requests: { eyebrow: "العلاقة مع العملاء", title: "طلبات التواصل", subtitle: "الطلبات الحقيقية التي تحتاج متابعة من الإدارة." },
    "merchant-applications": { eyebrow: "دورة التاجر", title: "طلبات التجار", subtitle: "طلبات حقيقية من تطبيق العميل، مع قرار مراجعة محفوظ في Production وسجل التدقيق." },
    banners: { eyebrow: "المحتوى المرئي", title: "البنرات الحية", subtitle: "إدارة البانرات التي يقرأها تطبيق العميل من المصدر الحقيقي." },
    taxonomy: { eyebrow: "المرجع القانوني", title: "التصنيفات والأنواع", subtitle: "مصدر التصنيف الهرمي المشترك بين التطبيق والإدارة." },
    admins: { eyebrow: "الهوية والصلاحيات", title: "المديرون", subtitle: "إدارة عضويات Admin Identity وأدوارها دون المرور بمسار العميل." },
    audit: { eyebrow: "المراجعة الأمنية", title: "سجل التدقيق", subtitle: "سجل قابل للمراجعة لكل عملية إدارية على المصدر الحقيقي." },
    users: { eyebrow: "دليل الحسابات", title: "المستخدمون", subtitle: "قراءة الحسابات والملفات من المصدر الحقيقي دون منح صلاحيات إدارة." },
    notifications: { eyebrow: "التواصل", title: "الإشعارات", subtitle: "إشعارات مرتبطة بالمستخدمين الحقيقيين داخل التطبيق." },
    analytics: { eyebrow: "التحليل التشغيلي", title: "الإحصاءات التشغيلية", subtitle: "مؤشرات مشتقة من جداول Production دون بيانات تقديرية." },
  };
  const heading = titles[activeView];
  const navigation = <nav className="mt-8 min-h-0 flex-1 space-y-1.5 overflow-y-auto overscroll-contain pr-1"><p className="mb-3 px-3 text-[10px] font-bold tracking-[.16em] text-[#cba983]">المساحة التشغيلية</p>{navItems.map(({ key, label, icon: Icon }) => <button key={key} onClick={() => { setActiveView(key); setSidebarOpen(false); }} className={`flex w-full items-center gap-3 rounded-2xl px-3.5 py-3 text-right text-sm font-semibold transition-all ${activeView === key ? "bg-[#f39c12] text-[#4f2e1f] shadow-[0_10px_25px_rgba(243,156,18,.18)]" : "text-[#ead8c6] hover:bg-white/10 hover:text-white"}`}><Icon className="size-[18px]" />{label}{key === "requests" && (requests.data ?? []).length > 0 && <span className="mr-auto grid size-5 place-items-center rounded-full bg-white/15 text-[10px]">{requests.data?.length}</span>}</button>)}</nav>;
  const counts = overview.data?.counts ?? {};

  return <main className="min-h-screen bg-[#fbf8f2]" dir="rtl"><aside className="fixed inset-y-0 right-0 z-30 hidden w-72 flex-col bg-[#4f2e1f] px-5 py-7 shadow-[-18px_0_45px_rgba(79,46,31,.10)] lg:flex"><AssalkomLogo /><div className="mt-6 flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[.05] p-3"><div className="grid size-10 place-items-center rounded-xl bg-[#f9e7c7] text-[#9c5a00]"><ShieldCheck className="size-5" /></div><div><p className="text-xs font-bold text-white">دار إدارة العسل</p><p className="mt-0.5 text-[10px] text-[#d6b994]">مركز القرار والتدقيق</p></div></div>{navigation}<div className="mt-auto rounded-3xl border border-white/10 bg-white/[.06] p-4"><div className="flex items-center gap-2 text-[#ffe4b0]"><ShieldCheck className="size-4" /><span className="text-xs font-bold">Supabase Production</span></div><p className="mt-2 text-xs leading-6 text-[#ebdaca]">المصدر الحي متصل عبر الخادم المحلي المصرح.</p></div></aside><div className="min-h-screen lg:mr-72"><header className="sticky top-0 z-20 flex items-center justify-between border-b border-[#eee1d0] bg-[#fbf8f2]/90 px-5 py-4 backdrop-blur-xl lg:px-8"><div className="flex items-center gap-3"><Button onClick={() => setSidebarOpen(true)} variant="ghost" size="icon" className="lg:hidden"><Menu className="size-5" /></Button><div><p className="text-[11px] font-bold tracking-[.18em] text-[#a37747]">{heading.eyebrow}</p><h2 className="mt-0.5 text-base font-bold text-[#3f281d]">{heading.title}</h2></div></div><div className="flex items-center gap-2"><Badge variant="outline" className="hidden border-dashed border-[#b7dfc2] bg-[#effaf1] text-[#26733d] sm:inline-flex">Production</Badge><Button onClick={() => void onLogout()} variant="ghost" size="sm" className="text-[#6f5b4c]">خروج</Button><Button onClick={() => setActiveView("notifications")} variant="ghost" size="icon" className="relative"><Bell className="size-5 text-[#6f5b4c]" /></Button><div className="grid size-9 place-items-center rounded-2xl bg-[#f2e8dd] text-sm font-bold text-[#704424]">{(session.user.email ?? "ع").slice(0, 1).toUpperCase()}</div></div></header><div className="px-5 py-7 lg:px-8 lg:py-8"><div className="mb-6 max-w-2xl"><div className="section-kicker">{heading.eyebrow}</div><p className="mt-2 text-sm leading-7 text-[#806b5a]">{heading.subtitle}</p></div>{activeView === "overview" && <><section className="relative overflow-hidden rounded-[28px] border border-[#eadcc9] bg-[#5b3623] px-6 py-6 text-white shadow-[0_20px_55px_rgba(79,46,31,.16)] lg:px-8"><div aria-hidden="true" className="absolute inset-y-0 left-0 h-full w-1/2 bg-[radial-gradient(circle_at_30%_30%,rgba(243,156,18,.45),transparent_32%),linear-gradient(135deg,rgba(243,156,18,.25),transparent)] opacity-70" /><div className="relative grid gap-6 lg:grid-cols-[minmax(0,1fr)_260px] lg:items-end"><div className="max-w-2xl"><div className="flex items-center gap-2 text-[#ffe4b0]"><Sparkles className="size-4" /><span className="text-xs font-semibold">موجز التشغيل اليومي</span></div><h1 className="mt-3 text-3xl font-bold leading-tight lg:text-[34px]">قرار واحد يحتاج متابعتك اليوم.</h1><p className="mt-2 max-w-xl text-sm leading-7 text-[#f8e6cb]">البيانات المعروضة هنا تأتي من Supabase Production عبر الخادم المحلي، ولا تستخدم بيانات Demo.</p><div className="mt-5 flex flex-wrap gap-3"><Button onClick={refreshOverview} className="bg-[#f39c12] text-[#4f2e1f] shadow-none hover:bg-[#ffb340]"><RefreshCw className="ml-2 size-4" />تحديث المصدر</Button><Button onClick={() => overview.data && downloadSnapshot(overview.data)} variant="outline" className="border-[#d7a768] bg-transparent text-white hover:bg-white/10 hover:text-white"><Download className="ml-2 size-4" />تصدير الموجز</Button></div></div><div className="rounded-2xl border border-white/10 bg-white/[.08] p-4 backdrop-blur-sm"><p className="text-[10px] font-bold tracking-[.15em] text-[#ffe4b0]">صحة مساحة العمل</p><div className="mt-3 space-y-3"><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">مصدر البيانات</span><span className="font-bold text-[#ffe4b0]">Production</span></div><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">المدير</span><span className="max-w-32 truncate font-bold text-white" dir="ltr">{session.user.email}</span></div><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">الدور</span><span className="font-bold text-[#f2c777]">{session.role.nameAr}</span></div></div></div></div></section><section className="mt-4 flex flex-wrap items-center gap-2 rounded-2xl border border-[#b7dfc2] bg-[#effaf1] px-4 py-3 text-xs text-[#26733d]"><span className="font-bold">الحالة التشغيلية:</span><Badge variant="outline" className="border-[#8bca9b] bg-white/60 text-[#26733d]">Supabase Production</Badge><span className="h-1 w-1 rounded-full bg-[#8bca9b]" /><span>لا توجد بيانات Demo في هذا المسار</span></section><section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4"><MetricCard label="المستخدمون" value={overview.loading ? "—" : counts.users ?? 0} note="من جدول الهوية التشغيلية" icon={PackageCheck} tone="gold" /><MetricCard label="المنتجات" value={overview.loading ? "—" : counts.products ?? 0} note="من المصدر الحقيقي" icon={Box} tone="brown" /><MetricCard label="المتاجر" value={overview.loading ? "—" : counts.stores ?? 0} note="بعد الاعتماد والنشر" icon={Store} tone="cream" /><MetricCard label="المناطق المرجعية" value={overview.loading ? "—" : counts.regions ?? 0} note="للتصفية الجغرافية" icon={Hexagon} tone="olive" /></section><section className="mt-6 grid gap-6 xl:grid-cols-[minmax(330px,.8fr)_minmax(0,1.45fr)]"><RequestsPanel state={requests} onSelect={setSelectedRequest} onRefresh={refreshRequests} /><ProductTable state={products} onRefresh={refreshProducts} onDelete={deleteProduct} onSelect={setSelectedProduct} compact /></section></>}{activeView === "products" && <div className="space-y-6"><ProductCreationPanel stores={stores.data ?? []} onCreated={() => { refreshProducts(); refreshOverview(); }} /><ProductTable state={products} onRefresh={refreshProducts} onDelete={deleteProduct} onSelect={setSelectedProduct} /></div>}
{activeView === "stores" && <StoresPanel state={stores} onRefresh={refreshStores} onModerate={moderateStore} onDelete={deleteStore} onSelect={setSelectedStore} />}{activeView === "merchant-applications" && <MerchantApplicationsPanel state={merchantApplications} onRefresh={refreshMerchantApplications} onReviewed={refreshMerchantApplications} />}{activeView === "banners" && <BannersPanel />}{activeView === "taxonomy" && <TaxonomyPanel />}{activeView === "admins" && <div className="space-y-6"><AdminCreationPanel /><AdminUsersPanel /></div>}{activeView === "audit" && <AuditPanel />}{activeView === "users" && <UsersPanel />}{activeView === "notifications" && <NotificationsPanel />}{activeView === "analytics" && <AnalyticsPanel />}{activeView === "requests" && <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_340px]"><RequestsPanel state={requests} onSelect={setSelectedRequest} onRefresh={refreshRequests} /><aside className="admin-card p-6"><Filter className="size-5 text-[#9c5a00]" /><h3 className="mt-4 text-lg font-bold text-[#3f281d]">حالة المصدر</h3><p className="mt-2 text-sm leading-7 text-[#806b5a]">هذه لوحة خاصة محلية. أي إجراء إداري يمر عبر الخادم المحلي ثم يتحقق من الصلاحية قبل الكتابة في Supabase.</p><Button onClick={refreshRequests} variant="outline" className="mt-5 w-full border-[#e3c28d] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث الطلبات</Button></aside></section>}</div></div><Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}><SheetContent side="right" className="w-72 border-0 bg-[#4f2e1f] p-5 text-white"><SheetHeader className="sr-only"><SheetTitle>التنقل</SheetTitle></SheetHeader><div className="flex items-center justify-between"><AssalkomLogo /><Button onClick={() => setSidebarOpen(false)} variant="ghost" size="icon" className="text-white hover:bg-white/10 hover:text-white"><X className="size-5" /></Button></div>{navigation}</SheetContent></Sheet><Sheet open={selectedRequest !== null} onOpenChange={(open) => !open && setSelectedRequest(null)}><SheetContent side="left" className="w-full overflow-y-auto sm:max-w-md"><SheetHeader><SheetTitle className="text-right text-xl text-[#3f281d]">تفاصيل طلب التواصل</SheetTitle></SheetHeader>{selectedRequest && <div className="mt-7 space-y-5 text-right"><div className="rounded-3xl bg-[#fff7e9] p-5"><div className="flex items-center justify-between"><span className="text-xs text-[#8d725a]">الحالة</span>{statusBadge(selectedRequest.status)}</div><h3 className="mt-4 text-lg font-bold text-[#3f281d]">{selectedRequest.subject}</h3><p className="mt-3 text-sm leading-7 text-[#6f5b4c]">{selectedRequest.body ?? "بدون وصف"}</p></div><form onSubmit={answerSelectedRequest} className="rounded-2xl border border-[#dfc6a9] p-4"><p className="text-sm font-semibold text-[#4f2e1f]">إرسال رد حقيقي</p><Input required value={replyBody} onChange={(event) => setReplyBody(event.target.value)} className="mt-3 rounded-xl border-[#eadcc9]" placeholder="اكتب الرد هنا" /><Button type="submit" className="mt-3 w-full bg-[#4f2e1f] hover:bg-[#6b412a]">إرسال الرد</Button></form></div>}</SheetContent></Sheet><Sheet open={selectedProduct !== null} onOpenChange={(open) => !open && setSelectedProduct(null)}><SheetContent side="left" className="w-full overflow-y-auto sm:max-w-lg"><SheetHeader><SheetTitle className="text-right text-xl text-[#3f281d]">تفاصيل المنتج</SheetTitle></SheetHeader>{selectedProduct && <div className="mt-7 space-y-5 text-right"><div className="rounded-3xl bg-[#fff7e9] p-5"><div className="flex items-center justify-between gap-3"><div><p className="text-xs text-[#8d725a]">اسم المنتج</p><h3 className="mt-1 text-xl font-bold text-[#3f281d]">{selectedProduct.name_ar}</h3></div>{statusBadge(selectedProduct.status)}</div><p className="mt-4 text-sm leading-7 text-[#6f5b4c]">{selectedProduct.description ?? "لا يوجد وصف مسجل."}</p></div><div className="grid gap-3 rounded-2xl border border-[#eadcc9] p-4 text-sm"><p><span className="font-semibold text-[#4f2e1f]">المعرف:</span> <span dir="ltr">{selectedProduct.id}</span></p><p><span className="font-semibold text-[#4f2e1f]">متجر المنتج:</span> <span dir="ltr">{selectedProduct.store_id}</span></p><p><span className="font-semibold text-[#4f2e1f]">النوع:</span> {selectedProduct.product_type}</p><p><span className="font-semibold text-[#4f2e1f]">منتج مميز:</span> {selectedProduct.is_featured ? "نعم" : "لا"}</p></div><div className="rounded-2xl border border-[#eadcc9] p-4"><p className="font-bold text-[#4f2e1f]">بيانات المنتج التفصيلية</p><div className="mt-3 space-y-2 text-sm text-[#6f5b4c]">{Object.entries(selectedProduct.metadata ?? {}).length === 0 ? <p>لا توجد بيانات إضافية.</p> : Object.entries(selectedProduct.metadata ?? {}).slice(0, 20).map(([key, value]) => <div className="flex items-start justify-between gap-4 border-b border-[#f1e7da] py-2" key={key}><span className="font-semibold">{key}</span><span className="max-w-[65%] break-words text-left" dir="auto">{typeof value === "string" ? value : JSON.stringify(value)}</span></div>)}</div></div></div>}</SheetContent></Sheet><Sheet open={selectedStore !== null} onOpenChange={(open) => !open && setSelectedStore(null)}><SheetContent side="left" className="w-full overflow-y-auto sm:max-w-lg"><SheetHeader><SheetTitle className="text-right text-xl text-[#3f281d]">تفاصيل المتجر</SheetTitle></SheetHeader>{selectedStore && <div className="mt-7 space-y-5 text-right"><div className="overflow-hidden rounded-3xl border border-[#eadcc9] bg-[#fff7e9]">{selectedStore.cover_url ? <img src={selectedStore.cover_url} alt="غلاف المتجر" className="h-36 w-full object-cover" /> : <div className="h-24 bg-gradient-to-l from-[#4f2e1f] to-[#9c5a00]" />}<div className="p-5"><div className="flex items-center justify-between gap-3"><h3 className="text-xl font-bold text-[#3f281d]">{selectedStore.name_ar}</h3>{statusBadge(selectedStore.status)}</div><p className="mt-3 text-sm leading-7 text-[#6f5b4c]">{selectedStore.description ?? "لا يوجد وصف مسجل."}</p></div></div><div className="grid gap-3 rounded-2xl border border-[#eadcc9] p-4 text-sm text-[#6f5b4c]"><p><span className="font-semibold text-[#4f2e1f]">الحالة:</span> {selectedStore.is_verified ? "موثق" : "غير موثق"}</p><p><span className="font-semibold text-[#4f2e1f]">معرف المتجر:</span> <span dir="ltr">{selectedStore.id}</span></p><p><span className="font-semibold text-[#4f2e1f]">معرف التاجر:</span> <span dir="ltr">{selectedStore.merchant_id ?? "غير متوفر"}</span></p><p><span className="font-semibold text-[#4f2e1f]">معرف المنطقة:</span> <span dir="ltr">{selectedStore.region_id ?? "غير محدد"}</span></p><p><span className="font-semibold text-[#4f2e1f]">الهاتف:</span> غير معروض في قائمة المتاجر الحالية</p></div></div>}</SheetContent></Sheet></main>;
}
