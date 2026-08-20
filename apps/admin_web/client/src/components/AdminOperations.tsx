import { ChangeEvent, FormEvent, useEffect, useState } from "react";
import { Check, ImagePlus, Layers3, MapPin, Plus, RefreshCw, Save, Tag, Trash2, Truck } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";
import { AdminSafeImage } from "@/components/AdminVisuals";

type Banner = { id: string; title_ar: string; body_ar?: string | null; image_url?: string | null; cta_label_ar?: string | null; cta_url?: string | null; is_active: boolean; sort_order: number };
type Taxonomy = { id: string; code: string; name_ar: string; name_en?: string | null; is_active: boolean };
type Category = { id: string; name_ar: string; slug: string; parent_id?: string | null; category_kind: string; is_active: boolean };

type LoadState<T> = { data: T; loading: boolean; error: string | null };
const inputClass = "rounded-xl border-[#eadcc9] bg-white";

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
  const [uploading, setUploading] = useState(false);
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
  const uploadImage = async (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    if (file.size > 10 * 1024 * 1024) { toast.error("حجم الصورة يتجاوز 10 ميجابايت."); return; }
    setUploading(true);
    try {
      const base64 = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onerror = () => reject(new Error("تعذر قراءة الملف المحلي."));
        reader.onload = () => resolve(String(reader.result ?? ""));
        reader.readAsDataURL(file);
      });
      const uploaded = await adminApi.uploadPublicImage({ contentType: file.type, base64, purpose: "banners" });
      setForm((previous) => ({ ...previous, imageUrl: uploaded.item.publicUrl }));
      toast.success("تم رفع صورة البانر وربطها بالمسودة.");
    } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر رفع صورة البانر."); }
    finally { setUploading(false); }
  };
  const remove = async (banner: Banner) => {
    if (!window.confirm(`حذف البانر «${banner.title_ar}» نهائيًا؟`)) return;
    try { await adminApi.deleteBanner(banner.id); toast.success("تم حذف البانر."); await load(); }
    catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حذف البانر."); }
  };
  return <section className="space-y-6"><div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]"><div className="admin-card p-6"><div className="flex items-start justify-between"><div><div className="section-kicker">المحتوى المرئي</div><h2 className="mt-1 text-xl font-bold text-[#342118]">البنرات الحية</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">تُقرأ من جدول `banners` وتظهر في تطبيق العميل عبر `customer_banners` بعد النشر.</p></div><ImagePlus className="size-6 text-[#9c5a00]" /></div><div className="mt-6 space-y-3"><PanelState loading={state.loading} error={state.error} empty={!state.data.length} onRefresh={() => void load()} />{state.data.map((banner) => <article key={banner.id} className="rounded-2xl border border-[#eee1d0] bg-[#fffaf3] p-4"><div className="flex items-start gap-3"><div className="grid size-11 shrink-0 place-items-center overflow-hidden rounded-xl bg-[#fff0d6] text-[#9c5a00]">{banner.image_url ? <AdminSafeImage src={banner.image_url} alt={banner.title_ar} /> : <ImagePlus className="size-5" />}</div><div className="min-w-0 flex-1"><div className="flex items-center justify-between gap-3"><h3 className="truncate font-bold text-[#432a1e]">{banner.title_ar}</h3>{banner.is_active ? <Badge className="bg-emerald-600">منشور</Badge> : <Badge variant="outline" className="border-[#d8c7b6] text-[#816b58]">مسودة</Badge>}</div><p className="mt-1 text-xs leading-6 text-[#806b5a]">{banner.body_ar ?? "بدون وصف"}</p></div></div><div className="mt-4 flex justify-end gap-2"><Button onClick={() => void publish(banner)} variant="outline" className="border-[#e3c28d] text-[#8b5a2b]"><Check className="ml-2 size-4" />{banner.is_active ? "إيقاف النشر" : "نشر"}</Button><Button onClick={() => void remove(banner)} variant="outline" className="border-red-200 text-red-800"><Trash2 className="ml-2 size-4" />حذف</Button></div></article>)}</div></div><form onSubmit={create} className="admin-card p-6"><div className="section-kicker">إضافة محتوى</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إنشاء بانر مسودة</h2><div className="mt-5 space-y-3"><label className="block text-sm font-semibold text-[#4f2e1f]">العنوان<Input required value={form.titleAr} onChange={(event) => setForm({ ...form, titleAr: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">الوصف<Input value={form.bodyAr} onChange={(event) => setForm({ ...form, bodyAr: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">صورة البانر (رفع محلي)<Input type="file" accept="image/png,image/jpeg,image/webp,image/gif" onChange={uploadImage} disabled={uploading} className="mt-2 rounded-xl border-[#eadcc9] file:ml-3 file:rounded-lg file:border-0 file:bg-[#fff0d6] file:px-3 file:py-1 file:text-xs file:font-semibold file:text-[#8b5a2b]" />{uploading && <span className="mt-1 block text-xs text-[#806b5a]">جارٍ رفع الصورة…</span>}{form.imageUrl && <div className="mt-3 h-28 overflow-hidden rounded-xl border border-[#eadcc9] bg-white"><AdminSafeImage src={form.imageUrl} alt="معاينة صورة البانر" /></div>}</label><label className="block text-sm font-semibold text-[#4f2e1f]">نص زر الإجراء<Input value={form.ctaLabelAr} onChange={(event) => setForm({ ...form, ctaLabelAr: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">رابط الإجراء<Input dir="ltr" value={form.ctaUrl} onChange={(event) => setForm({ ...form, ctaUrl: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">الترتيب<Input type="number" min="0" value={form.sortOrder} onChange={(event) => setForm({ ...form, sortOrder: event.target.value })} className="mt-2 rounded-xl border-[#eadcc9]" /></label></div><Button disabled={saving} className="mt-5 w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Save className="ml-2 size-4" />{saving ? "جارٍ الحفظ…" : "حفظ كمسودة"}</Button></form></div></section>;
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
  return <section className="space-y-6"><div className="flex items-center justify-between"><div><div className="section-kicker">المرجع القانوني للبيانات</div><h2 className="mt-1 text-2xl font-bold text-[#342118]">التصنيفات والأنواع</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">مصدر واحد للتصنيفات الهرمية التي يستهلكها التطبيق والإدارة.</p></div><Button onClick={() => void load()} variant="outline" className="border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div>{loading ? <div className="admin-card"><PanelState loading error={null} empty={false} onRefresh={() => void load()} /></div> : error ? <div className="admin-card p-6"><PanelState loading={false} error={error} empty={false} onRefresh={() => void load()} /></div> : <><div className="grid gap-6 xl:grid-cols-2"><div className="admin-card p-6"><div className="flex items-center gap-2"><Layers3 className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">تصنيف العسل المرجعي</h3></div><div className="mt-5 space-y-2">{taxonomies.length ? taxonomies.map((item) => <div key={item.id} className="flex items-center justify-between rounded-xl bg-[#fffaf3] px-3 py-2 text-sm"><span className="font-semibold text-[#432a1e]">{item.name_ar}</span><code className="text-xs text-[#8e7a68]">{item.code}</code></div>) : <p className="text-sm text-[#806b5a]">لا توجد أنواع نشطة.</p>}</div><form onSubmit={saveTaxonomy} className="mt-5 grid gap-2 sm:grid-cols-[1fr_1fr_auto]"><Input required value={taxonomyForm.nameAr} onChange={(event) => setTaxonomyForm({ ...taxonomyForm, nameAr: event.target.value })} placeholder="اسم النوع" className="rounded-xl border-[#eadcc9]" /><Input required dir="ltr" value={taxonomyForm.code} onChange={(event) => setTaxonomyForm({ ...taxonomyForm, code: event.target.value })} placeholder="sidr" className="rounded-xl border-[#eadcc9]" /><Button type="submit" size="icon" className="bg-[#4f2e1f] hover:bg-[#6b412a]"><Plus className="size-4" /></Button></form></div><div className="admin-card p-6"><div className="flex items-center gap-2"><Tag className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">التصنيفات الهرمية</h3></div><div className="mt-5 space-y-2">{categories.length ? categories.map((item) => <div key={item.id} className="flex items-center justify-between rounded-xl bg-[#fffaf3] px-3 py-2 text-sm"><span className="font-semibold text-[#432a1e]">{item.name_ar}</span><span className="text-xs text-[#8e7a68]">{item.slug}</span></div>) : <p className="text-sm text-[#806b5a]">لا توجد تصنيفات نشطة.</p>}</div><form onSubmit={saveCategory} className="mt-5 grid gap-2 sm:grid-cols-[1fr_1fr_auto]"><Input required value={categoryForm.nameAr} onChange={(event) => setCategoryForm({ ...categoryForm, nameAr: event.target.value })} placeholder="اسم التصنيف" className="rounded-xl border-[#eadcc9]" /><Input required dir="ltr" value={categoryForm.slug} onChange={(event) => setCategoryForm({ ...categoryForm, slug: event.target.value })} placeholder="honey" className="rounded-xl border-[#eadcc9]" /><Button type="submit" size="icon" className="bg-[#4f2e1f] hover:bg-[#6b412a]"><Plus className="size-4" /></Button></form></div></div></>}</section>;
}


type LogisticsStore = { id: string; name_ar: string; status: string };
type LogisticsMethod = { id: string; code: string; name_ar: string; description?: string | null };
type LogisticsRegion = { id: string; parent_region_id?: string | null; name_ar: string; region_level?: "governorate" | "district" | string };
type DeliveryOption = { id: string; delivery_method_id: string; region_id?: string | null; fee_amount?: number | null; currency: string; estimated_days?: number | null; is_active: boolean };
type PickupLocation = { id: string; region_id?: string | null; name_ar: string; address?: string | null; phone?: string | null; geo_lat?: number | null; geo_lng?: number | null; is_active: boolean };

function regionName(regions: LogisticsRegion[], id?: string | null) {
  return id ? regions.find((region) => region.id === id)?.name_ar ?? "منطقة غير معروفة" : "جميع المناطق";
}

export function LogisticsPanel({ stores }: { stores: LogisticsStore[] }) {
  const [storeId, setStoreId] = useState("");
  const [methods, setMethods] = useState<LogisticsMethod[]>([]);
  const [regions, setRegions] = useState<LogisticsRegion[]>([]);
  const [deliveryOptions, setDeliveryOptions] = useState<DeliveryOption[]>([]);
  const [pickupLocations, setPickupLocations] = useState<PickupLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingStore, setLoadingStore] = useState(false);
  const [saving, setSaving] = useState(false);
  const [deliveryForm, setDeliveryForm] = useState({ methodId: "", governorateId: "", districtId: "", fee: "", currency: "YER", days: "" });
  const [pickupForm, setPickupForm] = useState({ nameAr: "", address: "", phone: "", governorateId: "", districtId: "" });

  useEffect(() => {
    if (!storeId && stores[0]?.id) setStoreId(stores[0].id);
  }, [storeId, stores]);

  useEffect(() => {
    let active = true;
    void Promise.all([adminApi.deliveryMethods(), adminApi.regions()])
      .then(([methodResult, regionResult]) => {
        if (!active) return;
        setMethods(methodResult.items as LogisticsMethod[]);
        setRegions(regionResult.items as LogisticsRegion[]);
        setDeliveryForm((previous) => ({ ...previous, methodId: previous.methodId || (methodResult.items[0] as LogisticsMethod | undefined)?.id || "" }));
      })
      .catch((error) => toast.error(error instanceof Error ? error.message : "تعذر قراءة مراجع التوصيل."))
      .finally(() => { if (active) setLoading(false); });
    return () => { active = false; };
  }, []);

  const loadStore = async () => {
    if (!storeId) {
      setDeliveryOptions([]);
      setPickupLocations([]);
      return;
    }
    setLoadingStore(true);
    try {
      const result = await adminApi.storeLogistics(storeId);
      setDeliveryOptions(result.deliveryOptions as DeliveryOption[]);
      setPickupLocations(result.pickupLocations as PickupLocation[]);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر قراءة إعدادات التوصيل.");
    } finally {
      setLoadingStore(false);
    }
  };

  useEffect(() => { void loadStore(); }, [storeId]);

  const governorates = regions.filter((region) => region.region_level === "governorate" || !region.parent_region_id);
  const deliveryDistricts = regions.filter((region) => region.parent_region_id === deliveryForm.governorateId);
  const pickupDistricts = regions.filter((region) => region.parent_region_id === pickupForm.governorateId);
  const methodName = (id: string) => methods.find((method) => method.id === id)?.name_ar ?? "طريقة غير معروفة";

  const saveDelivery = async (event: FormEvent) => {
    event.preventDefault();
    if (!storeId || !deliveryForm.methodId) { toast.error("اختر المتجر وطريقة التوصيل."); return; }
    setSaving(true);
    try {
      await adminApi.upsertDeliveryOption({ storeId, deliveryMethodId: deliveryForm.methodId, regionId: deliveryForm.districtId || deliveryForm.governorateId || null, feeAmount: deliveryForm.fee || null, currency: deliveryForm.currency, estimatedDays: deliveryForm.days || null });
      toast.success("تم حفظ خيار التوصيل في Production.");
      setDeliveryForm((previous) => ({ ...previous, fee: "", days: "", districtId: "" }));
      await loadStore();
    } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ خيار التوصيل."); }
    finally { setSaving(false); }
  };

  const savePickup = async (event: FormEvent) => {
    event.preventDefault();
    if (!storeId || !pickupForm.nameAr.trim()) { toast.error("اكتب اسم نقطة الاستلام واختر المتجر."); return; }
    setSaving(true);
    try {
      await adminApi.upsertPickupLocation({ storeId, nameAr: pickupForm.nameAr, address: pickupForm.address || null, phone: pickupForm.phone || null, regionId: pickupForm.districtId || pickupForm.governorateId || null });
      toast.success("تم حفظ نقطة الاستلام في Production.");
      setPickupForm({ nameAr: "", address: "", phone: "", governorateId: "", districtId: "" });
      await loadStore();
    } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حفظ نقطة الاستلام."); }
    finally { setSaving(false); }
  };

  const removeDelivery = async (id: string) => {
    if (!window.confirm("حذف خيار التوصيل نهائيًا؟")) return;
    try { await adminApi.deleteDeliveryOption(id); toast.success("تم حذف خيار التوصيل."); await loadStore(); }
    catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حذف خيار التوصيل."); }
  };

  const removePickup = async (id: string) => {
    if (!window.confirm("حذف نقطة الاستلام نهائيًا؟")) return;
    try { await adminApi.deletePickupLocation(id); toast.success("تم حذف نقطة الاستلام."); await loadStore(); }
    catch (error) { toast.error(error instanceof Error ? error.message : "تعذر حذف نقطة الاستلام."); }
  };

  if (loading) return <section className="admin-card p-6"><PanelState loading error={null} empty={false} onRefresh={() => undefined} /></section>;

  return <section className="space-y-6">
    <div className="admin-card p-6">
      <div className="flex flex-wrap items-start justify-between gap-4"><div><div className="section-kicker">تشغيل المتجر</div><h2 className="mt-1 text-2xl font-bold text-[#342118]">التوصيل ونقاط الاستلام</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">تُحفظ الخيارات في الجداول المشتركة التي يقرأها تطبيق العميل، ولا تُخزّن كحقول نصية منفصلة داخل المنتج.</p></div><Truck className="size-7 text-[#9c5a00]" /></div>
      <label className="mt-6 block text-sm font-semibold text-[#4f2e1f]">المتجر<select value={storeId} onChange={(event) => setStoreId(event.target.value)} className={`${inputClass} mt-2 h-11 w-full px-3 text-sm font-normal`}><option value="">اختر متجرًا</option>{stores.map((store) => <option key={store.id} value={store.id}>{store.name_ar} — {store.status}</option>)}</select></label>
    </div>
    {loadingStore ? <div className="admin-card"><PanelState loading error={null} empty={false} onRefresh={() => void loadStore()} /></div> : !storeId ? <div className="admin-card"><PanelState loading={false} error={null} empty onRefresh={() => undefined} /></div> : <div className="grid gap-6 xl:grid-cols-2">
      <div className="admin-card p-6"><div className="flex items-center gap-2"><Truck className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">خيارات التوصيل</h3></div><div className="mt-4 space-y-2">{deliveryOptions.length ? deliveryOptions.map((option) => <div key={option.id} className="flex items-start justify-between gap-3 rounded-2xl bg-[#fffaf3] p-3"><div><p className="font-semibold text-[#432a1e]">{methodName(option.delivery_method_id)}</p><p className="mt-1 text-xs text-[#806b5a]">النطاق: {regionName(regions, option.region_id)}{option.fee_amount !== null && option.fee_amount !== undefined ? ` — ${option.fee_amount} ${option.currency}` : " — الرسوم عند التواصل"}{option.estimated_days !== null && option.estimated_days !== undefined ? ` — ${option.estimated_days} يوم` : ""}</p></div><Button onClick={() => void removeDelivery(option.id)} variant="ghost" size="icon" className="text-red-800"><Trash2 className="size-4" /><span className="sr-only">حذف خيار التوصيل</span></Button></div>) : <p className="rounded-xl border border-dashed border-[#dfc6a9] p-4 text-sm text-[#806b5a]">لا توجد خيارات توصيل لهذا المتجر.</p>}</div><form onSubmit={saveDelivery} className="mt-5 space-y-3 border-t border-[#eee1d0] pt-5"><select required value={deliveryForm.methodId} onChange={(event) => setDeliveryForm({ ...deliveryForm, methodId: event.target.value })} className={`${inputClass} h-10 w-full px-3 text-sm`}><option value="">اختر طريقة التوصيل</option>{methods.map((method) => <option key={method.id} value={method.id}>{method.name_ar}</option>)}</select><div className="grid gap-3 sm:grid-cols-2"><select value={deliveryForm.governorateId} onChange={(event) => setDeliveryForm({ ...deliveryForm, governorateId: event.target.value, districtId: "" })} className={`${inputClass} h-10 w-full px-3 text-sm`}><option value="">كل المحافظات</option>{governorates.map((region) => <option key={region.id} value={region.id}>{region.name_ar}</option>)}</select><select value={deliveryForm.districtId} onChange={(event) => setDeliveryForm({ ...deliveryForm, districtId: event.target.value })} disabled={!deliveryForm.governorateId} className={`${inputClass} h-10 w-full px-3 text-sm`}><option value="">كل المديريات</option>{deliveryDistricts.map((region) => <option key={region.id} value={region.id}>{region.name_ar}</option>)}</select></div><div className="grid gap-3 sm:grid-cols-3"><Input type="number" min="0" step="0.01" value={deliveryForm.fee} onChange={(event) => setDeliveryForm({ ...deliveryForm, fee: event.target.value })} placeholder="الرسوم" className={inputClass} /><Input value={deliveryForm.currency} onChange={(event) => setDeliveryForm({ ...deliveryForm, currency: event.target.value })} placeholder="العملة" className={inputClass} /><Input type="number" min="0" step="1" value={deliveryForm.days} onChange={(event) => setDeliveryForm({ ...deliveryForm, days: event.target.value })} placeholder="المدة بالأيام" className={inputClass} /></div><Button disabled={saving} type="submit" className="w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Save className="ml-2 size-4" />حفظ خيار التوصيل</Button></form></div>
      <div className="admin-card p-6"><div className="flex items-center gap-2"><MapPin className="size-5 text-[#9c5a00]" /><h3 className="font-bold text-[#4f2e1f]">نقاط الاستلام</h3></div><div className="mt-4 space-y-2">{pickupLocations.length ? pickupLocations.map((location) => <div key={location.id} className="flex items-start justify-between gap-3 rounded-2xl bg-[#fffaf3] p-3"><div><p className="font-semibold text-[#432a1e]">{location.name_ar}</p><p className="mt-1 text-xs text-[#806b5a]">{regionName(regions, location.region_id)}{location.address ? ` — ${location.address}` : ""}{location.phone ? ` — ${location.phone}` : ""}</p></div><Button onClick={() => void removePickup(location.id)} variant="ghost" size="icon" className="text-red-800"><Trash2 className="size-4" /><span className="sr-only">حذف نقطة الاستلام</span></Button></div>) : <p className="rounded-xl border border-dashed border-[#dfc6a9] p-4 text-sm text-[#806b5a]">لا توجد نقاط استلام لهذا المتجر.</p>}</div><form onSubmit={savePickup} className="mt-5 space-y-3 border-t border-[#eee1d0] pt-5"><Input required value={pickupForm.nameAr} onChange={(event) => setPickupForm({ ...pickupForm, nameAr: event.target.value })} placeholder="اسم نقطة الاستلام" className={inputClass} /><div className="grid gap-3 sm:grid-cols-2"><select value={pickupForm.governorateId} onChange={(event) => setPickupForm({ ...pickupForm, governorateId: event.target.value, districtId: "" })} className={`${inputClass} h-10 w-full px-3 text-sm`}><option value="">اختر المحافظة</option>{governorates.map((region) => <option key={region.id} value={region.id}>{region.name_ar}</option>)}</select><select value={pickupForm.districtId} onChange={(event) => setPickupForm({ ...pickupForm, districtId: event.target.value })} disabled={!pickupForm.governorateId} className={`${inputClass} h-10 w-full px-3 text-sm`}><option value="">اختر المديرية</option>{pickupDistricts.map((region) => <option key={region.id} value={region.id}>{region.name_ar}</option>)}</select></div><Input value={pickupForm.address} onChange={(event) => setPickupForm({ ...pickupForm, address: event.target.value })} placeholder="العنوان التفصيلي" className={inputClass} /><Input value={pickupForm.phone} onChange={(event) => setPickupForm({ ...pickupForm, phone: event.target.value })} placeholder="رقم التواصل" className={inputClass} /><Button disabled={saving} type="submit" className="w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Save className="ml-2 size-4" />حفظ نقطة الاستلام</Button></form></div>
    </div>}
  </section>;
}
