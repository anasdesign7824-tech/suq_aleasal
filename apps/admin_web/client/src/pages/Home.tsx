// Design: دار العسل التحريرية — RTL operational dashboard; ivory workspace, deep-brown rail, honey-gold decisions.
import { useMemo, useState } from "react";
import {
  Bell,
  Box,
  ChevronLeft,
  ClipboardList,
  Filter,
  Handshake,
  Hexagon,
  LayoutDashboard,
  Menu,
  MoreHorizontal,
  PackageCheck,
  Search,
  ShieldCheck,
  Sparkles,
  Store,
  Users,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet, SheetContent, SheetHeader, SheetTitle } from "@/components/ui/sheet";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { demoCatalog } from "@/data/demoCatalog";

type ViewKey = "overview" | "products" | "stores" | "requests";
type RequestRow = (typeof demoCatalog.requests)[number];

const logoUrl = "/manus-storage/assalkom-logo-internal_7a2821c9.svg";
const heroUrl = "/manus-storage/assalkom-admin-hero_0ba2eb71.png";
const requestsUrl = "/manus-storage/assalkom-admin-requests_9be5108b.png";
const adminSymbolUrl = "/manus-storage/assalkom-admin-symbol_52b64a4e.png";

const navItems: Array<{ key: ViewKey; label: string; icon: typeof LayoutDashboard }> = [
  { key: "overview", label: "نظرة عامة", icon: LayoutDashboard },
  { key: "products", label: "الكتالوج", icon: Box },
  { key: "stores", label: "المتاجر", icon: Store },
  { key: "requests", label: "طلبات التواصل", icon: ClipboardList },
];

const requestStatus = {
  open: { label: "جديد", className: "border-amber-300 bg-amber-50 text-amber-800" },
  answered: { label: "تم الرد", className: "border-emerald-300 bg-emerald-50 text-emerald-800" },
} as const;

const metricCards = [
  { label: "منتجات الكتالوج", value: demoCatalog.products.length.toString(), note: "مصدرها Honey Master", icon: PackageCheck, tone: "gold" },
  { label: "متاجر Demo", value: demoCatalog.stores.length.toString(), note: "قابلة للمراجعة", icon: Store, tone: "brown" },
  { label: "طلبات تحتاج متابعة", value: demoCatalog.requests.filter((request) => request.status === "open").length.toString(), note: "قرار واحد مطلوب", icon: Handshake, tone: "cream" },
  { label: "مناطق موثقة", value: demoCatalog.regions.length.toString(), note: "للتصفية والاستكشاف", icon: Hexagon, tone: "olive" },
] as const;

function AssalkomLogo() {
  return (
    <div className="flex items-center gap-3">
      <img className="h-12 w-12 rounded-2xl bg-[#fffaf0] object-contain p-1 shadow-[0_8px_22px_rgba(243,156,18,.20)]" src={logoUrl} alt="شعار عسلكم" />
      <div>
        <p className="text-xl font-bold tracking-tight text-[#fffaf0]">عسلكم</p>
        <p className="mt-0.5 text-[10px] font-medium tracking-[.22em] text-[#f8d59c]">SOUQ AL ASSAL</p>
      </div>
    </div>
  );
}

function MetricCard({ metric }: { metric: (typeof metricCards)[number] }) {
  const Icon = metric.icon;
  const tone = {
    gold: "bg-[#fff0d6] text-[#9c5a00]",
    brown: "bg-[#f3e9df] text-[#4f2e1f]",
    cream: "bg-[#f6f0e8] text-[#87623c]",
    olive: "bg-[#eaf0e6] text-[#4f7a45]",
  }[metric.tone];
  return (
    <article className="admin-card group min-w-0 p-5">
      <div className="flex items-start justify-between gap-3">
        <div className={`grid h-11 w-11 place-items-center rounded-2xl ${tone}`}><Icon size={20} /></div>
        <span className="rounded-full border border-[#efe2d0] px-2.5 py-1 text-[10px] font-semibold text-[#866f5c]">Demo</span>
      </div>
      <p className="mt-6 text-3xl font-bold text-[#342118]" dir="ltr">{metric.value}</p>
      <p className="mt-1.5 text-sm font-semibold text-[#4f2e1f]">{metric.label}</p>
      <p className="mt-1 text-xs text-[#8e7a68]">{metric.note}</p>
    </article>
  );
}

function ProductTable({ compact = false }: { compact?: boolean }) {
  const [query, setQuery] = useState("");
  const [category, setCategory] = useState("الكل");
  const storeNames = useMemo(() => Object.fromEntries(demoCatalog.stores.map((store) => [store.id, store.name_ar])), []);
  const categories = useMemo(() => ["الكل", ...Array.from(new Set(demoCatalog.products.map((product) => product.category_name_ar)))], []);
  const products = useMemo(() => demoCatalog.products
    .filter((product) => category === "الكل" || product.category_name_ar === category)
    .filter((product) => product.name_ar.includes(query.trim()))
    .slice(0, compact ? 5 : 12), [category, compact, query]);

  return (
    <section className="admin-card overflow-hidden">
      <div className="flex flex-col gap-4 border-b border-[#eee1d0] px-5 py-5 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <div className="section-kicker">الكتالوج</div>
          <h2 className="mt-1 text-xl font-bold text-[#342118]">{compact ? "آخر المنتجات المتاحة" : "إدارة الكتالوج"}</h2>
        </div>
        <div className="flex flex-col gap-2 sm:flex-row">
          <div className="relative"><Search className="absolute right-3 top-1/2 size-4 -translate-y-1/2 text-[#9a897d]" /><Input value={query} onChange={(event) => setQuery(event.target.value)} className="h-10 w-full rounded-xl border-[#eadcc9] pr-9 sm:w-52" placeholder="ابحث باسم المنتج" /></div>
          <select value={category} onChange={(event) => setCategory(event.target.value)} className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm text-[#5d4737] outline-none focus:ring-2 focus:ring-[#f3c26c]">
            {categories.map((item) => <option key={item}>{item}</option>)}
          </select>
        </div>
      </div>
      <div className="overflow-x-auto">
        <Table>
          <TableHeader><TableRow className="border-[#eee1d0] hover:bg-transparent"><TableHead className="text-right text-[#806755]">المنتج</TableHead><TableHead className="text-right text-[#806755]">الفئة</TableHead><TableHead className="text-right text-[#806755]">المتجر</TableHead><TableHead className="text-right text-[#806755]">الحالة</TableHead><TableHead className="text-left text-[#806755]">إجراء</TableHead></TableRow></TableHeader>
          <TableBody>
            {products.map((product) => <TableRow className="border-[#f2e8dc]" key={product.id}>
              <TableCell className="min-w-48 py-4"><div className="flex items-center gap-3"><div className="grid size-9 place-items-center rounded-xl bg-[#fff0d6]"><Hexagon className="size-4 text-[#9c5a00]" /></div><span className="font-semibold text-[#432a1e]">{product.name_ar}</span></div></TableCell>
              <TableCell className="text-sm text-[#705a49]">{product.category_name_ar}</TableCell>
              <TableCell className="text-sm text-[#705a49]">{storeNames[product.store_id]}</TableCell>
              <TableCell><Badge variant="outline" className="border-emerald-300 bg-emerald-50 text-emerald-800">نشط</Badge></TableCell>
              <TableCell className="text-left"><Button onClick={() => toast.info(`يتم استعراض ${product.name_ar} في Demo Mode`)} variant="ghost" size="icon" className="text-[#8b5a2b]"><MoreHorizontal className="size-5" /><span className="sr-only">استعراض المنتج</span></Button></TableCell>
            </TableRow>)}
          </TableBody>
        </Table>
      </div>
      {!compact && <div className="border-t border-[#eee1d0] px-5 py-4 text-xs text-[#8e7a68]">تظهر بيانات Demo فقط. لا تُنفّذ أي تغييرات إنتاجية من هذه الواجهة.</div>}
    </section>
  );
}

function RequestsPanel({ onSelect }: { onSelect: (request: RequestRow) => void }) {
  return (
    <section className="admin-card overflow-hidden">
      <div className="flex items-start justify-between gap-4 border-b border-[#eee1d0] px-5 py-5">
        <div><div className="section-kicker">متابعة</div><h2 className="mt-1 text-xl font-bold text-[#342118]">طلبات التواصل</h2></div>
        <img src={requestsUrl} alt="رمز تواصل تجريدي" className="h-14 w-14 rounded-2xl bg-[#fff8ed] object-cover" />
      </div>
      <div className="divide-y divide-[#f1e7da]">
        {demoCatalog.requests.map((request) => {
          const status = requestStatus[request.status as keyof typeof requestStatus];
          return <button className="group flex w-full items-center gap-3 px-5 py-4 text-right transition-colors hover:bg-[#fffaf3]" key={request.id} onClick={() => onSelect(request)}>
            <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-[#f4ece1] text-[#8b5a2b]"><Handshake className="size-4" /></div>
            <div className="min-w-0 flex-1"><p className="truncate text-sm font-semibold text-[#432a1e]">{request.subject}</p><p className="mt-0.5 truncate text-xs text-[#8e7a68]">{request.body}</p></div>
            <Badge variant="outline" className={status.className}>{status.label}</Badge>
            <ChevronLeft className="size-4 text-[#b39e8c] transition-transform group-hover:-translate-x-0.5" />
          </button>;
        })}
      </div>
    </section>
  );
}

function Overview({ onSelectRequest }: { onSelectRequest: (request: RequestRow) => void }) {
  return <>
    <section className="relative overflow-hidden rounded-[28px] border border-[#eadcc9] bg-[#5b3623] px-6 py-6 text-white shadow-[0_20px_55px_rgba(79,46,31,.16)] lg:px-8">
      <img src={heroUrl} alt="خلفية عسلية مجردة" className="absolute inset-y-0 left-0 h-full w-1/2 object-cover opacity-35 mix-blend-screen" />
      <div className="relative grid gap-6 lg:grid-cols-[minmax(0,1fr)_260px] lg:items-end">
        <div className="max-w-2xl"><div className="flex items-center gap-2 text-[#ffe4b0]"><Sparkles className="size-4" /><span className="text-xs font-semibold">موجز التشغيل اليومي</span></div>
          <h1 className="mt-3 text-3xl font-bold leading-tight lg:text-[34px]">قرار واحد يحتاج متابعتك اليوم.</h1>
          <p className="mt-2 max-w-xl text-sm leading-7 text-[#f8e6cb]">هناك طلب تواصل جديد بانتظار الاستعراض، بينما يبقى الكتالوج والمتاجر في حالة Demo مستقرة.</p>
          <div className="mt-5 flex flex-wrap gap-3"><Button onClick={() => toast.info("مصدر الإنتاج غير مفعّل في Demo Mode")} className="bg-[#f39c12] text-[#4f2e1f] shadow-none hover:bg-[#ffb340]"><ShieldCheck className="ml-2 size-4" />مراجعة حالة المصدر</Button><Button onClick={() => toast.info("تمت محاكاة تصدير التقرير التجريبي")} variant="outline" className="border-[#d7a768] bg-transparent text-white hover:bg-white/10 hover:text-white">تصدير موجز اليوم</Button></div>
        </div>
        <div className="rounded-2xl border border-white/10 bg-white/[.08] p-4 backdrop-blur-sm"><p className="text-[10px] font-bold tracking-[.15em] text-[#ffe4b0]">صحة مساحة العمل</p><div className="mt-3 space-y-3"><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">مصدر البيانات</span><span className="font-bold text-[#ffe4b0]">Demo محلي</span></div><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">طلبات جديدة</span><span className="font-bold text-white">1</span></div><div className="flex items-center justify-between text-xs"><span className="text-[#f5e3cb]">ربط الإنتاج</span><span className="font-bold text-[#f2c777]">مؤجل</span></div></div></div>
      </div>
    </section>
    <section className="mt-4 flex flex-wrap items-center gap-2 rounded-2xl border border-[#eee1d0] bg-white/70 px-4 py-3 text-xs text-[#725b48]"><span className="font-bold text-[#4f2e1f]">الحالة التشغيلية:</span><Badge variant="outline" className="border-dashed border-[#dca044] bg-[#fff7e8] text-[#8d5812]">Demo Mode</Badge><span className="h-1 w-1 rounded-full bg-[#d6bd9e]" /><span>لا يوجد اتصال مصدر إنتاج</span><span className="h-1 w-1 rounded-full bg-[#d6bd9e]" /><span className="font-semibold text-[#8b5a2b]">طلب جديد واحد</span></section>
    <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{metricCards.map((metric) => <MetricCard key={metric.label} metric={metric} />)}</section>
    <section className="mt-6 grid gap-6 xl:grid-cols-[minmax(330px,.8fr)_minmax(0,1.45fr)]"><RequestsPanel onSelect={onSelectRequest} /><ProductTable compact /></section>
  </>;
}

export default function Home() {
  const [activeView, setActiveView] = useState<ViewKey>("overview");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [selectedRequest, setSelectedRequest] = useState<RequestRow | null>(null);
  const titles: Record<ViewKey, { eyebrow: string; title: string; subtitle: string }> = {
    overview: { eyebrow: "لوحة التشغيل", title: "صباح الخير، فريق عسلكم", subtitle: "إليك لقطة واضحة عن حالة Demo اليوم." },
    products: { eyebrow: "بيانات العرض", title: "الكتالوج التجريبي", subtitle: "استعراض بيانات Honey Master دون مصدر إنتاج." },
    stores: { eyebrow: "شبكة التجار", title: "المتاجر التجريبية", subtitle: "ثلاث واجهات متجر لتدقيق بنية العرض وتجربة الإدارة." },
    requests: { eyebrow: "العلاقة مع العملاء", title: "طلبات التواصل", subtitle: "طلبات Demo فقط؛ لا يتم إرسال أي رسالة حقيقية." },
  };
  const heading = titles[activeView];

  const navigation = <nav className="mt-8 space-y-1.5"><p className="mb-3 px-3 text-[10px] font-bold tracking-[.16em] text-[#cba983]">المساحة التشغيلية</p>{navItems.map(({ key, label, icon: Icon }) => <button key={key} onClick={() => { setActiveView(key); setSidebarOpen(false); }} className={`flex w-full items-center gap-3 rounded-2xl px-3.5 py-3 text-right text-sm font-semibold transition-all ${activeView === key ? "bg-[#f39c12] text-[#4f2e1f] shadow-[0_10px_25px_rgba(243,156,18,.18)]" : "text-[#ead8c6] hover:bg-white/10 hover:text-white"}`}><Icon className="size-[18px]" />{label}{key === "requests" && <span className="mr-auto grid size-5 place-items-center rounded-full bg-white/15 text-[10px]">{demoCatalog.requests.filter((request) => request.status === "open").length}</span>}</button>)}</nav>;

  return (
    <main className="min-h-screen bg-[#fbf8f2]" dir="rtl">
      <aside className="fixed inset-y-0 right-0 z-30 w-72 flex-col bg-[#4f2e1f] px-5 py-7 shadow-[-18px_0_45px_rgba(79,46,31,.10)] max-lg:hidden flex">
        <AssalkomLogo />
        <div className="mt-6 flex items-center gap-3 rounded-2xl border border-white/10 bg-white/[.05] p-3"><img src={adminSymbolUrl} alt="رمز لوحة عسلكم" className="size-10 rounded-xl bg-[#f9e7c7] object-contain p-1" /><div><p className="text-xs font-bold text-white">دار إدارة العسل</p><p className="mt-0.5 text-[10px] text-[#d6b994]">مركز القرار والتدقيق</p></div></div>
        {navigation}
        <div className="mt-auto rounded-3xl border border-white/10 bg-white/[.06] p-4"><div className="flex items-center gap-2 text-[#ffe4b0]"><ShieldCheck className="size-4" /><span className="text-xs font-bold">Demo Mode</span></div><p className="mt-2 text-xs leading-6 text-[#ebdaca]">المصدر الحالي محلي تجريبي. لا يوجد اتصال فعلي بـ Supabase هنا.</p></div>
      </aside>
      <div className="min-h-screen lg:mr-72">
        <header className="sticky top-0 z-20 flex items-center justify-between border-b border-[#eee1d0] bg-[#fbf8f2]/90 px-5 py-4 backdrop-blur-xl lg:px-8">
          <div className="flex items-center gap-3"><Button onClick={() => setSidebarOpen(true)} variant="ghost" size="icon" className="lg:hidden"><Menu className="size-5" /></Button><div><p className="text-[11px] font-bold tracking-[.18em] text-[#a37747]">{heading.eyebrow}</p><h2 className="mt-0.5 text-base font-bold text-[#3f281d]">{heading.title}</h2></div></div>
          <div className="flex items-center gap-2"><Badge variant="outline" className="hidden border-dashed border-[#dea242] bg-[#fff6e7] text-[#8d5812] sm:inline-flex">Demo Mode</Badge><Button onClick={() => toast.info("لا توجد إشعارات إنتاجية في Demo Mode")} variant="ghost" size="icon" className="relative"><Bell className="size-5 text-[#6f5b4c]" /><span className="absolute left-2 top-2 size-1.5 rounded-full bg-[#f39c12]" /></Button><div className="grid size-9 place-items-center rounded-2xl bg-[#f2e8dd] text-sm font-bold text-[#704424]">ع</div></div>
        </header>
        <div className="px-5 py-7 lg:px-8 lg:py-8">
          <div className="mb-6 max-w-2xl"><div className="section-kicker">{heading.eyebrow}</div><p className="mt-2 text-sm leading-7 text-[#806b5a]">{heading.subtitle}</p></div>
          {activeView === "overview" && <Overview onSelectRequest={setSelectedRequest} />}
          {activeView === "products" && <ProductTable />}
          {activeView === "stores" && <section className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">{demoCatalog.stores.map((store, index) => <article className="admin-card relative overflow-hidden p-6" key={store.id}><div className="absolute left-0 top-0 h-20 w-20 rounded-br-[42px] bg-[#fff0d6]" /><div className="relative flex items-start justify-between"><div className="grid size-12 place-items-center rounded-2xl bg-[#4f2e1f] text-[#f7c769]"><Store className="size-5" /></div><Badge variant="outline" className={store.is_verified ? "border-emerald-300 bg-emerald-50 text-emerald-800" : "border-[#d8c7b6] bg-[#faf6f0] text-[#816b58]"}>{store.is_verified ? "موثق" : "قيد Demo"}</Badge></div><h3 className="relative mt-8 text-lg font-bold text-[#3f281d]">{store.name_ar}</h3><p className="relative mt-2 min-h-12 text-sm leading-6 text-[#806b5a]">{store.description}</p><div className="relative mt-5 flex items-center justify-between border-t border-[#f1e6da] pt-4"><span className="text-xs text-[#876f5c]">{demoCatalog.products.filter((product) => product.store_id === store.id).length} منتجات في Demo</span><Button onClick={() => toast.info(`تم استعراض ${store.name_ar} في Demo Mode`)} variant="ghost" size="sm" className="text-[#8b5a2b]">استعراض<ChevronLeft className="mr-1 size-4" /></Button></div></article>)}</section>}
          {activeView === "requests" && <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_340px]"><RequestsPanel onSelect={setSelectedRequest} /><aside className="admin-card p-6"><Filter className="size-5 text-[#9c5a00]" /><h3 className="mt-4 text-lg font-bold text-[#3f281d]">حدود Demo</h3><p className="mt-2 text-sm leading-7 text-[#806b5a]">يمكنك استعراض الحالات وفتح التفاصيل فقط. لن تُرسل رسائل ولن يتغير مصدر البيانات من هذه الواجهة.</p><Button onClick={() => toast.info("مصدر الإنتاج يُربط فقط في مرحلته المعتمدة")} variant="outline" className="mt-5 w-full border-[#e3c28d] text-[#8b5a2b]">تعرف على مصدر البيانات</Button></aside></section>}
        </div>
      </div>
      <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}><SheetContent side="right" className="w-72 border-0 bg-[#4f2e1f] p-5 text-white"><SheetHeader className="sr-only"><SheetTitle>التنقل</SheetTitle></SheetHeader><div className="flex items-center justify-between"><AssalkomLogo /><Button onClick={() => setSidebarOpen(false)} variant="ghost" size="icon" className="text-white hover:bg-white/10 hover:text-white"><X className="size-5" /></Button></div>{navigation}</SheetContent></Sheet>
      <Sheet open={selectedRequest !== null} onOpenChange={(open) => !open && setSelectedRequest(null)}><SheetContent side="left" className="w-full overflow-y-auto sm:max-w-md"><SheetHeader><SheetTitle className="text-right text-xl text-[#3f281d]">تفاصيل طلب التواصل</SheetTitle></SheetHeader>{selectedRequest && <div className="mt-7 space-y-5 text-right"><div className="rounded-3xl bg-[#fff7e9] p-5"><div className="flex items-center justify-between"><span className="text-xs text-[#8d725a]">الحالة</span><Badge variant="outline" className={requestStatus[selectedRequest.status as keyof typeof requestStatus].className}>{requestStatus[selectedRequest.status as keyof typeof requestStatus].label}</Badge></div><h3 className="mt-4 text-lg font-bold text-[#3f281d]">{selectedRequest.subject}</h3><p className="mt-3 text-sm leading-7 text-[#6f5b4c]">{selectedRequest.body}</p></div><div className="rounded-2xl border border-dashed border-[#dfc6a9] p-4 text-sm leading-7 text-[#806b5a]">هذا طلب Demo. تم تعطيل أي إجراء يرسل رسالة أو يغير حالة إنتاجية.</div><Button onClick={() => toast.info("الإجراءات الإنتاجية غير مفعلة في Demo Mode")} className="w-full bg-[#4f2e1f] hover:bg-[#6b412a]">إرسال رد تجريبي</Button></div>}</SheetContent></Sheet>
    </main>
  );
}
