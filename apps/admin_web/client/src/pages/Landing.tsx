// عسلكم — Premium Dark Honey public landing, Arabic-first, RTL, Demo-honest.
import { ArrowLeft, ChevronLeft, Compass, Hexagon, MapPin, ShieldCheck, Store, UsersRound } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { demoCatalog } from "@/data/demoCatalog";

const featuredProducts = demoCatalog.products.filter((product) => product.is_featured).slice(0, 3);
const storeNameById = Object.fromEntries(demoCatalog.stores.map((store) => [store.id, store.name_ar]));

function Logo() {
  return (
    <a className="flex items-center gap-2.5" href="#top">
      <span className="grid size-11 place-items-center rounded-2xl border border-[#4a3523] bg-[#2b1d12] text-[#f5a623] shadow-[0_10px_28px_rgba(0,0,0,.45)]">
        <Hexagon className="size-6" />
      </span>
      <span className="text-2xl font-bold tracking-tight text-[#f7ede2]">عسلكم</span>
    </a>
  );
}

function Benefit({ icon: Icon, title, body }: { icon: typeof ShieldCheck; title: string; body: string }) {
  return (
    <article className="rounded-[1.4rem] border border-[#38291d] bg-gradient-to-br from-[#1a120c] to-[#24180f] p-6 shadow-[0_14px_34px_rgba(0,0,0,.34)]">
      <div className="grid size-11 place-items-center rounded-2xl bg-[#332416] text-[#f5a623]">
        <Icon className="size-5" />
      </div>
      <h3 className="mt-5 text-lg font-bold text-[#f7ede2]">{title}</h3>
      <p className="mt-2 text-sm leading-7 text-[#c9b6a3]">{body}</p>
    </article>
  );
}

export default function Landing() {
  return (
    <main id="top" dir="rtl" className="min-h-screen overflow-x-hidden bg-[#0d0906] text-[#f7ede2]">
      <header className="sticky top-0 z-30 border-b border-[#38291d] bg-[#0d0906]/90 backdrop-blur-xl">
        <div className="mx-auto flex h-20 max-w-7xl items-center justify-between px-5 lg:px-8">
          <Logo />
          <nav className="hidden items-center gap-7 text-sm font-semibold text-[#c9b6a3] md:flex">
            <a href="#discover" className="transition-colors hover:text-[#f5a623]">اكتشف العسل</a>
            <a href="#stores" className="transition-colors hover:text-[#f5a623]">متاجر يمنية</a>
            <a href="#about" className="transition-colors hover:text-[#f5a623]">فكرة عسلكم</a>
          </nav>
          <div className="flex items-center gap-2">
            <Badge variant="outline" className="hidden border-dashed border-[#7a5a2a] bg-[#24180f] text-[#ffc45e] sm:inline-flex">Demo Mode</Badge>
            <Button onClick={() => toast.info("التسجيل التعريفي في Demo Mode فقط")} className="rounded-xl border border-[#7a5a2a] bg-[#332416] text-[#ffc45e] hover:bg-[#2b1d12]">
              انضم كتاجر
            </Button>
          </div>
        </div>
      </header>

      <section className="relative">
        <div className="absolute inset-x-0 top-0 h-[560px] bg-[radial-gradient(circle_at_18%_20%,rgba(245,166,35,.20),transparent_28%),radial-gradient(circle_at_82%_45%,rgba(245,166,35,.10),transparent_27%)]" />
        <div className="relative mx-auto grid max-w-7xl gap-12 px-5 pb-20 pt-14 lg:grid-cols-[1.05fr_.95fr] lg:items-center lg:px-8 lg:pb-28 lg:pt-24">
          <div>
            <Badge variant="outline" className="border-[#7a5a2a] bg-[#24180f] px-3 py-1 text-[#ffc45e]">
              <Hexagon className="ml-1.5 size-3.5" />منصة تجمع النحالين في اليمن
            </Badge>
            <h1 className="mt-6 max-w-3xl text-4xl font-bold leading-[1.24] tracking-tight text-[#f7ede2] md:text-5xl lg:text-6xl">
              عسل يمني أصيل، <span className="text-[#f5a623]">من مصدره</span> إلى اختياراتك.
            </h1>
            <p className="mt-6 max-w-2xl text-base leading-8 text-[#c9b6a3] md:text-lg">
              عسلكم مساحة عربية للاكتشاف والتواصل مع متاجر العسل اليمني. نعرض معلومات المنتج والمصدر بوضوح، ونبدأ اليوم من تجربة Demo صادقة وواضحة.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <Button onClick={() => document.getElementById("discover")?.scrollIntoView({ behavior: "smooth" })}
                className="h-12 rounded-xl bg-[#f5a623] px-5 text-[#2b1a12] shadow-[0_12px_25px_rgba(245,166,35,.22)] hover:bg-[#ffc45e]">
                اكتشف المنتجات<ArrowLeft className="mr-2 size-4" />
              </Button>
              <Button onClick={() => toast.info("دليل المتاجر يعمل من بيانات Demo حالياً")} variant="outline"
                className="h-12 rounded-xl border-[#4a3523] bg-[#1a120c] px-5 text-[#ffc45e] hover:bg-[#24180f]">
                دليل المتاجر
              </Button>
            </div>
            <div className="mt-10 flex flex-wrap gap-6 border-t border-[#38291d] pt-6 text-sm">
              <div>
                <p className="text-2xl font-bold text-[#f5a623]" dir="ltr">{demoCatalog.products.length}</p>
                <p className="mt-1 text-[#c9b6a3]">منتجًا في Demo Catalog</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-[#f5a623]" dir="ltr">{demoCatalog.stores.length}</p>
                <p className="mt-1 text-[#c9b6a3]">متاجر تجريبية</p>
              </div>
              <div>
                <p className="text-2xl font-bold text-[#f5a623]" dir="ltr">{demoCatalog.regions.length}</p>
                <p className="mt-1 text-[#c9b6a3]">مناطق للاستكشاف</p>
              </div>
            </div>
          </div>
          <div className="relative">
            <div className="absolute -left-7 -top-7 grid size-20 place-items-center rounded-[2rem] border border-[#4a3523] bg-[#24180f] shadow-[0_18px_35px_rgba(0,0,0,.4)]">
              <Hexagon className="size-12 text-[#f5a623]" />
            </div>
            <div className="overflow-hidden rounded-[2rem] border border-[#4a3523] bg-[#2b1d12] p-3 shadow-[0_30px_70px_rgba(0,0,0,.5)]">
              <div className="flex h-[370px] w-full items-center justify-center rounded-[1.45rem] bg-[radial-gradient(circle_at_30%_30%,rgba(245,166,35,.35),transparent_30%),linear-gradient(135deg,#332416,#1a120c)]">
                <div className="grid size-40 place-items-center rounded-[3rem] border border-[#f5a623]/30 bg-[#24180f] text-[#f5a623] shadow-[0_20px_50px_rgba(0,0,0,.22)]">
                  <Hexagon className="size-20" />
                </div>
              </div>
            </div>
            <div className="absolute -bottom-5 right-6 max-w-60 rounded-2xl border border-[#38291d] bg-[#1a120c] p-4 shadow-[0_18px_40px_rgba(0,0,0,.45)]">
              <div className="flex items-center gap-2 text-[#f5a623]">
                <ShieldCheck className="size-4" />
                <span className="text-xs font-bold">بيانات واضحة المصدر</span>
              </div>
              <p className="mt-2 text-xs leading-6 text-[#c9b6a3]">تظهر هوية المنتج وتصنيفه ومتجره ضمن تجربة Demo بلا ادعاءات تقييمية مصطنعة.</p>
            </div>
          </div>
        </div>
      </section>

      <section id="about" className="border-y border-[#38291d] bg-[#120c08]">
        <div className="mx-auto grid max-w-7xl gap-6 px-5 py-16 md:grid-cols-3 lg:px-8">
          <Benefit icon={Compass} title="اكتشاف مبني على المصدر" body="تصنيفات واضحة ومناطق يمنية تساعدك على فهم المنتج قبل التواصل مع المتجر." />
          <Benefit icon={UsersRound} title="تواصل أقرب للمتجر" body="تدفق طلب تواصل بسيط وواضح، مع احترام أن Demo لا يرسل رسائل حقيقية." />
          <Benefit icon={ShieldCheck} title="Demo بصدق" body="نصرّح بحالة مصدر البيانات ولا نستبدلها بادعاءات إنتاجية أو مراجعات غير موثقة." />
        </div>
      </section>

      <section id="discover" className="mx-auto max-w-7xl px-5 py-20 lg:px-8">
        <div className="grid gap-10 lg:grid-cols-[.75fr_1.25fr] lg:items-end">
          <div>
            <div className="section-kicker">اختيارات من الكتالوج</div>
            <h2 className="mt-3 text-3xl font-bold leading-tight text-[#f7ede2]">رحلة مذاق تبدأ من الاسم والمصدر.</h2>
            <p className="mt-4 text-sm leading-7 text-[#c9b6a3]">هذه أمثلة عرض من Demo Catalog؛ لا تتضمن أسعارًا أو تقييمات أو وعود شراء.</p>
            <div className="mt-7 grid h-48 grid-cols-3 gap-3 overflow-hidden rounded-[1.6rem] border border-[#38291d] bg-[#1a120c] p-3">
              <div className="grid place-items-center rounded-[1.15rem] bg-[#2b1d12] text-[#f5a623]"><Hexagon className="size-12" /></div>
              <div className="grid place-items-center rounded-[1.15rem] bg-[#f5a623] text-[#2b1a12]"><Hexagon className="size-12" /></div>
              <div className="grid place-items-center rounded-[1.15rem] bg-[#332416] text-[#ffc45e]"><Hexagon className="size-12" /></div>
            </div>
          </div>
          <div className="grid gap-4 md:grid-cols-3">
            {featuredProducts.map((product) => (
              <article key={product.id}
                className="group relative overflow-hidden rounded-[1.5rem] border border-[#38291d] bg-gradient-to-b from-[#1a120c] to-[#24180f] p-5 shadow-[0_12px_26px_rgba(0,0,0,.32)] transition-transform duration-200 hover:-translate-y-1 hover:border-[#7a5a2a]">
                <span className="absolute left-0 top-0 h-16 w-16 rounded-br-[2.6rem] bg-[#332416]" />
                <div className="relative grid size-10 place-items-center rounded-2xl bg-[#2b1d12] text-[#f5a623]"><Hexagon className="size-5" /></div>
                <p className="relative mt-7 text-xs font-bold text-[#f5a623]">{product.category_name_ar}</p>
                <h3 className="relative mt-2 text-lg font-bold leading-7 text-[#f7ede2]">{product.name_ar}</h3>
                <p className="relative mt-3 min-h-14 text-xs leading-6 text-[#c9b6a3]">{product.description}</p>
                <div className="relative mt-5 flex items-center justify-between border-t border-[#38291d] pt-4">
                  <span className="text-[11px] text-[#8f7a66]">{storeNameById[product.store_id]}</span>
                  <button onClick={() => toast.info(`تم استعراض ${product.name_ar} في Demo Mode`)} className="text-[#f5a623] transition-transform hover:-translate-x-1">
                    <ChevronLeft className="size-5" />
                    <span className="sr-only">استعراض المنتج</span>
                  </button>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section id="stores" className="border-y border-[#4a3523] bg-[#2b1d12] py-20 text-[#f7ede2]">
        <div className="mx-auto grid max-w-7xl gap-10 px-5 lg:grid-cols-[.9fr_1.1fr] lg:px-8">
          <div>
            <div className="section-kicker">مسارات يمنية</div>
            <h2 className="mt-3 text-3xl font-bold leading-tight">متاجر من مناطق تعرف نكهة العسل.</h2>
            <p className="mt-4 max-w-md text-sm leading-7 text-[#c9b6a3]">نستعرض في Demo أسماء متاجر ومناطق لتجربة البنية والملاحة؛ لا تمثل هذه الصفحة تأكيدًا لتوفر منتج أو طلب حقيقي.</p>
            <Button onClick={() => toast.info("تصفح المناطق يعمل في Demo Mode فقط")} className="mt-7 rounded-xl bg-[#f5a623] text-[#2b1a12] hover:bg-[#ffc45e]">
              استكشف المناطق<MapPin className="mr-2 size-4" />
            </Button>
          </div>
          <div className="grid gap-3 sm:grid-cols-2">
            {demoCatalog.regions.map((region) => (
              <div key={region.id} className="flex items-center justify-between rounded-2xl border border-[#4a3523] bg-[#1a120c] p-4">
                <div>
                  <p className="font-bold text-[#f7ede2]">{region.name_ar}</p>
                  <p className="mt-1 text-xs text-[#c9b6a3]">رمز المنطقة: <span dir="ltr">{region.code}</span></p>
                </div>
                <MapPin className="size-5 text-[#f5a623]" />
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto max-w-7xl px-5 py-20 lg:px-8">
        <div className="relative overflow-hidden rounded-[2rem] border border-[#38291d] bg-gradient-to-br from-[#1a120c] to-[#24180f] p-8 md:p-11 shadow-[0_24px_60px_rgba(0,0,0,.4)]">
          <div className="absolute -left-16 -top-16 size-52 rounded-full border-[22px] border-[#f5a623]/20" />
          <div className="relative flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
            <div className="max-w-2xl">
              <div className="section-kicker">لأجل سوق أوضح</div>
              <h2 className="mt-3 text-3xl font-bold leading-tight text-[#f7ede2]">هل تبيع العسل اليمني وتريد ظهورًا منظمًا؟</h2>
              <p className="mt-3 text-sm leading-7 text-[#c9b6a3]">ابدأ بتجربة تعريفية. سيبقى جمع البيانات والتشغيل الإنتاجي مؤجلين إلى مصادر الإنتاج المعتمدة.</p>
            </div>
            <Button onClick={() => toast.info("الانضمام للتجار معروض توضيحيًا فقط في Demo Mode")} className="h-12 rounded-xl bg-[#f5a623] px-6 text-[#2b1a12] hover:bg-[#ffc45e]">
              انضم كتاجر<Store className="mr-2 size-4" />
            </Button>
          </div>
        </div>
      </section>

      <footer className="border-t border-[#38291d] bg-[#0d0906]">
        <div className="mx-auto flex max-w-7xl flex-col gap-5 px-5 py-9 sm:flex-row sm:items-center sm:justify-between lg:px-8">
          <Logo />
          <div className="flex items-center gap-3 text-xs text-[#8f7a66]">
            <span>عسلكم — تجربة Demo</span>
            <span className="size-1 rounded-full bg-[#4a3523]" />
            <a href="/" className="font-bold text-[#f5a623]">لوحة الإدارة</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
