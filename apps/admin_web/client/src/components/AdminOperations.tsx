import { FormEvent, useEffect, useState } from "react";
import { Check, ImagePlus, Layers3, Plus, RefreshCw, Save, Tag } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type Banner = { id: string; title_ar: string; body_ar?: string | null; image_url?: string | null; cta_label_ar?: string | null; cta_url?: string | null; is_active: boolean; sort_order: number };
type Taxonomy = { id: string; code: string; name_ar: string; name_en?: string | null; is_active: boolean };
type Category = { id: string; name_ar: string; slug: string; parent_id?: string | null; category_kind: string; is_active: boolean };

type LoadState<T> = { data: T; loading: boolean; error: string | null };

function PanelState({ loading, error, empty, onRefresh }: { loading: boolean; error: string | null; empty: boolean; onRefresh: () => void }) {
  if (loading) return <div className="flex min-h-32 items-center justify-center text-sm text-[#806b5a]"><RefreshCw className="ml-2 size-4 animate-spin text-[#c77d1a]" />جارٍ القراءة…</div>;
  if (error) return <div className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm leading-7 text-red-800">{error}<Button onClick={onRefresh} variant="outline" className="mt-3 border-red-200 text-red-800"><RefreshCw className="ml-2 size-4" />إعادة المحاولة</Button></div>;
  if (empty) return <div className="rounded-2xl border border-dashed border-[#dfc6a9] p-6 text-center text-sm leading-7 text-[#806b5a]">لا توجد بيانات في المصدر الحقيقي بعد.</div>;
  return null;
}

export function BannersPanel() {
  const [state, setState] = useState<LoadState<Banner[]>>({ data: [], loading: true, error: null });
  const [form, setForm] = useState({ titleAr: "", bodyAr: "", imageUrl: "", ctaLabelAr: "استكشف", ctaUrl: "", sortOrder: "0" });
  const [saving, setSaving] = useState(false);
  const load = async () => {
    setState((previous) => ({ ...previous, loading: true, error: null }));
    try { setState({ data: (await adminApi.banners()).items as Banner[], loading: false, error: null }); } catch (error) { setState({ data: [], loading: false, error: error instanceof Error ? error.message : "تعذر قراءة البنرات." }); }
  };
  useEffect(() => { void load(); }, []);
  const create = async (event: FormEvent) => {
    event.preventDefault();
    setSaving(true);
    try { await adminApi.createBanner({ ...form, sortOrder: Number(form.sortOrder), isActive: false }); setForm({ titleAr: "", bodyAr: "", imageUrl: "", ctaLabelAr: "استكشف", ctaUrl: "", sortOrder: "0" }); toast.success("تم حفظ البانر كمسودة."); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ البانر."); } finally { setSaving(false); }
  };
  const publish = async (banner: Banner) => {
    try { await adminApi.updateBanner(banner.id, { isActive: !banner.is_active }); toast.success(banner.is_active ? "تم إيقاف البانر." : "تم نشر البانر."); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر تحديث حالة البانر."); }
  };
  return <section className="space-y-6"><div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]"><div className="admin-card p-6"><div className="flex items-start justify-between"><div><div className="section-kicker">المحتوى المرئي</div><h2 className="mt-1 text-xl font-bold text-[#342118]">البنرات الحية</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">تُقرأ من جدول `banners` وتظهر في تطبيق العميل عبر `customer_banners` بعد النشر.</p></div><ImagePlus className="size-6 text-[#9c5a00]" /></div><div className="mt-6 space-y-3"><PanelState loading={state.loading} error={state.error} empty={!state.data.length} onRefresh={() => void load()} />{state.data.map((banner) => <article key={banner.id} className="rounded-2xl border border-[#eee1d0] bg-[#fffaf3] p-4"><div className="flex items-start gap-3"><div className="grid size-11 shrink-0 place-items-center overflow-hidden rounded-xl bg-[#fff0d6] text-[#9c5a00]">{banner.image_url ? <img src={banner.image_url} alt={banner.title_ar} className="size-full object-cover" /> : <ImagePlus className="size-5" />}</div><div className="min-w-0 flex-1"><div className="flex items-center justify-between gap-3"><h3 className="truncate font-bold text-[#432a1e]">{banner.title_ar}</h3>{banner.is_active ? <Badge className="bg-emerald-600">منشور</Badge> : <Badge variant="outline" className="border-[#d8c7b6] text-[#816b58]">مسودة</Badge>}</div><p className="mt-1 text-xs leading-6 text-[#806b5a]">{banner.body_ar ?? "بدون وصف"}</p></div></div><div className="mt-4 flex justify-end"><Button onClick={() => void publish(banner)} variant="outline" className="border-[#e3c28d] text-[#8b5a2b]"><Check className="ml-2 size-4" />{banner.is_active ? "إيقاف النشر" : "نشر"}</Button></div></article>)}</div></div><form onSubmit={create} className="admin-card p-6"><div className="section-kicker">إضافة محتوى</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إنشاء بانر مسودة</h2><div className="mt-5 space-y-3"><label className="block text-sm font-semibold text-[#4f2e1f]">العنوان<Input required value={form.titleAr} onChange={(event) => setForm({ ...form, titleAr: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">الوصف<Input value={form.bodyAr} onChange={(event) => setForm({ ...form, bodyAr: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">رابط الصورة<Input dir="ltr" value={form.imageUrl} onChange={(event) => setForm({ ...form, imageUrl: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" placeholder="https://…" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">رابط الإجراء<Input dir="ltr" value={form.ctaUrl} onChange={(event) => setForm({ ...form, ctaUrl: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">الترتيب<Input type="number" min="0" value={form.sortOrder} onChange={(event) => setForm({ ...form, sortOrder: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label></div><Button disabled={saving} className="mt-5 w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Save className="ml-2 size-4" />{saving ? "جارٍ الحفظ…" : "حفظ كمسودة"}</Button></form></div></section>;
}

export function TaxonomyPanel() {
  const [taxonomies, setTaxonomies] = useState<Taxonomy[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [categoryForm, setCategoryForm] = useState({ nameAr: "", slug: "", categoryKind: "honey" });
  const [taxonomyForm, setTaxonomyForm] = useState({ nameAr: "", code: "" });
  const load = async () => {
    setLoading(true); setError(null);
    try { const [taxonomy, category] = await Promise.all([adminApi.taxonomy(), adminApi.categories()]); setTaxonomies(taxonomy.items as Taxonomy[]); setCategories(category.items as Category[]); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة التصنيف."); } finally { setLoading(false); }
  };
  useEffect(() => { void load(); }, []);
  const saveCategory = async (event: FormEvent) => { event.preventDefault(); try { await adminApi.upsertCategory({ ...categoryForm }); setCategoryForm({ nameAr: "", slug: "", categoryKind: "honey" }); toast.success("تم حفظ التصنيف."); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ التصنيف."); } };
  const saveTaxonomy = async (event: FormEvent) => { event.preventDefault(); try { await adminApi.upsertTaxonomy({ ...taxonomyForm }); setTaxonomyForm({ nameAr: "", code: "" }); toast.success("تم حفظ تصنيف العسل."); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ تصنيف العسل."); } };
  return <section className="space-y-6"><div className="flex items-center justify-between"><div><div className="section-kicker">المرجع القانوني للبيانات</div><h2 className="mt-1 text-2xl font-bold text-[#342118]">التصنيفات والأنواع</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">مصدر واحد للتصنيفات الهرمية التي يستهلكها التطبيق والإدارة.</p></div><Button onClick={() => void load()} variant="outline" className="border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div>{loading ? <div className="admin-card"><PanelState loading error={null} empty={false} onRefresh={() => void load()} /></div> : error ? <div className="admin-card p-6"><PanelState loading={false} error={error} empty={false} onRefresh={() => void load()} /></div> : <><div className="grid gap-6 xl:grid-cols-2"><div className="admin-card p-6"><div className="flex items-center gap-2"><Layers3 className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">Honey Taxonomy</h3></div><div className="mt-5 space-y-2">{taxonomies.length ? taxonomies.map((item) => <div key={item.id} className="flex items-center justify-between rounded-xl bg-[#fffaf3] px-3 py-2 text-sm"><span className="font-semibold text-[#432a1e]">{item.name_ar}</span><code className="text-xs text-[#8e7a68]">{item.code}</code></div>) : <p className="text-sm text-[#806b5a]">لا توجد أنواع نشطة.</p>}</div><form onSubmit={saveTaxonomy} className="mt-5 grid gap-2 sm:grid-cols-[1fr_1fr_auto]"><Input required value={taxonomyForm.nameAr} onChange={(event) => setTaxonomyForm({ ...taxonomyForm, nameAr: event.target.value })} placeholder="اسم النوع" className="rounded-xl border-[#eadcc9]" /><Input required dir="ltr" value={taxonomyForm.code} onChange={(event) => setTaxonomyForm({ ...taxonomyForm, code: event.target.value })} placeholder="sidr" className="rounded-xl border-[#eadcc9]" /><Button type="submit" size="icon" className="bg-[#4f2e1f] hover:bg-[#6b412a]"><Plus className="size-4" /></Button></form></div><div className="admin-card p-6"><div className="flex items-center gap-2"><Tag className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">التصنيفات الهرمية</h3></div><div className="mt-5 space-y-2">{categories.length ? categories.map((item) => <div key={item.id} className="flex items-center justify-between rounded-xl bg-[#fffaf3] px-3 py-2 text-sm"><span className="font-semibold text-[#432a1e]">{item.name_ar}</span><span className="text-xs text-[#8e7a68]">{item.slug}</span></div>) : <p className="text-sm text-[#806b5a]">لا توجد تصنيفات نشطة.</p>}</div><form onSubmit={saveCategory} className="mt-5 grid gap-2 sm:grid-cols-[1fr_1fr_auto]"><Input required value={categoryForm.nameAr} onChange={(event) => setCategoryForm({ ...categoryForm, nameAr: event.target.value })} placeholder="اسم التصنيف" className="rounded-xl border-[#eadcc9]" /><Input required dir="ltr" value={categoryForm.slug} onChange={(event) => setCategoryForm({ ...categoryForm, slug: event.target.value })} placeholder="honey" className="rounded-xl border-[#eadcc9]" /><Button type="submit" size="icon" className="bg-[#4f2e1f] hover:bg-[#6b412a]"><Plus className="size-4" /></Button></form></div></div></>}</section>;
}
