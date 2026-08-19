import { useEffect, useMemo, useState } from "react";
import { Box, ImagePlus, Loader2, Plus, Trash2 } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type StoreOption = { id: string; name_ar: string; status: string };
type TaxonomyOption = { id: string; name_ar: string; code?: string | null };
type RegionOption = { id: string; name_ar: string; region_level?: string };

type ProductForm = {
  storeId: string;
  taxonomyId: string;
  nameAr: string;
  nameEn: string;
  description: string;
  productType: string;
  gradeLevel: string;
  price: string;
  currencyCode: string;
  weightLabel: string;
  originCountry: string;
  provinceNameAr: string;
  honeyIdentity: string;
  qualityLabelAr: string;
  processingMethodAr: string;
  processingStatusAr: string;
  packagingLabelAr: string;
  productionDate: string;
  packagedDate: string;
  shelfLifeLabelAr: string;
  availability: string;
  purpose: string;
  harvestLabel: string;
  deliveryOptions: string;
  pickupLocations: string;
  components: string;
  tags: string;
  badges: string;
  forms: string;
  certifications: string;
  regionId: string;
  isFeatured: boolean;
};

const initialForm: ProductForm = {
  storeId: "",
  taxonomyId: "",
  nameAr: "",
  nameEn: "",
  description: "",
  productType: "honey",
  gradeLevel: "",
  price: "",
  currencyCode: "YER",
  weightLabel: "",
  originCountry: "اليمن",
  provinceNameAr: "",
  honeyIdentity: "",
  qualityLabelAr: "",
  processingMethodAr: "",
  processingStatusAr: "",
  packagingLabelAr: "",
  productionDate: "",
  packagedDate: "",
  shelfLifeLabelAr: "",
  availability: "متاح للاستفسار",
  purpose: "",
  harvestLabel: "",
  deliveryOptions: "",
  pickupLocations: "",
  components: "",
  tags: "",
  badges: "",
  forms: "",
  certifications: "",
  regionId: "",
  isFeatured: false,
};

const inputClass = "rounded-xl border-[#eadcc9] bg-white";

function splitList(value: string): string[] {
  return value
    .split(/[,،\n]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function textMetadata(form: ProductForm): Record<string, unknown> {
  const metadata: Record<string, unknown> = {};
  const textFields: Array<[keyof ProductForm, string]> = [
    ["weightLabel", "weight_label"],
    ["originCountry", "origin_country"],
    ["provinceNameAr", "province_name_ar"],
    ["honeyIdentity", "honey_identity"],
    ["qualityLabelAr", "quality_label_ar"],
    ["processingMethodAr", "processing_method_ar"],
    ["processingStatusAr", "processing_status_ar"],
    ["packagingLabelAr", "packaging_label_ar"],
    ["productionDate", "production_date"],
    ["packagedDate", "packaged_date"],
    ["shelfLifeLabelAr", "shelf_life_label_ar"],
    ["availability", "availability"],
    ["purpose", "purpose"],
    ["harvestLabel", "harvest_label"],
  ];
  for (const [source, target] of textFields) {
    const value = form[source];
    if (typeof value === "string" && value.trim()) metadata[target] = value.trim();
  }
  metadata.delivery_options = splitList(form.deliveryOptions);
  metadata.pickup_locations = splitList(form.pickupLocations);
  metadata.components = splitList(form.components);
  metadata.tags = splitList(form.tags);
  metadata.badges = splitList(form.badges);
  metadata.forms = splitList(form.forms);
  metadata.certifications = splitList(form.certifications);
  if (form.regionId) metadata.region_id = form.regionId;
  return metadata;
}

async function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(typeof reader.result === "string" ? reader.result : "");
    reader.onerror = () => reject(reader.error ?? new Error("تعذر قراءة الصورة."));
    reader.readAsDataURL(file);
  });
}

export function ProductCreationPanel({ onCreated, stores }: { onCreated: () => void; stores: StoreOption[] }) {
  const [form, setForm] = useState<ProductForm>(initialForm);
  const [taxonomy, setTaxonomy] = useState<TaxonomyOption[]>([]);
  const [regions, setRegions] = useState<RegionOption[]>([]);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [loadingReferences, setLoadingReferences] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    let active = true;
    void Promise.all([adminApi.taxonomy(), adminApi.regions()])
      .then(([taxonomyResult, regionResult]) => {
        if (!active) return;
        setTaxonomy(taxonomyResult.items as TaxonomyOption[]);
        setRegions(regionResult.items as RegionOption[]);
      })
      .catch((error) => {
        if (active) toast.error(error instanceof Error ? error.message : "تعذر قراءة المراجع.");
      })
      .finally(() => {
        if (active) setLoadingReferences(false);
      });
    return () => {
      active = false;
    };
  }, []);

  const update = <K extends keyof ProductForm>(key: K, value: ProductForm[K]) => {
    setForm((previous) => ({ ...previous, [key]: value }));
  };

  const availableStores = useMemo(() => stores.filter((store) => store.id && store.name_ar), [stores]);

  const uploadImages = async (files: FileList | null) => {
    if (!files?.length) return;
    setUploading(true);
    try {
      const uploaded: string[] = [];
      for (const file of Array.from(files)) {
        if (!file.type.startsWith("image/")) throw new Error("اختر ملفات صور فقط.");
        if (file.size > 10 * 1024 * 1024) throw new Error("حجم كل صورة يجب ألا يتجاوز 10 ميجابايت.");
        const dataUrl = await fileToDataUrl(file);
        const result = await adminApi.uploadPublicImage({ contentType: file.type, base64: dataUrl, purpose: "admin-product" });
        uploaded.push(result.item.publicUrl);
      }
      setImageUrls((previous) => [...previous, ...uploaded]);
      toast.success(`تم رفع ${uploaded.length} صورة إلى Storage Production.`);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر رفع الصور.");
    } finally {
      setUploading(false);
    }
  };

  const create = async (event: React.FormEvent) => {
    event.preventDefault();
    const price = Number(form.price);
    if (!form.storeId || !form.taxonomyId || !form.nameAr.trim()) {
      toast.error("اختر المتجر والتصنيف واكتب اسم المنتج.");
      return;
    }
    if (!Number.isFinite(price) || price < 0) {
      toast.error("أدخل سعرًا صحيحًا.");
      return;
    }
    setSaving(true);
    try {
      await adminApi.createProduct({
        storeId: form.storeId,
        taxonomyId: form.taxonomyId,
        nameAr: form.nameAr,
        nameEn: form.nameEn || null,
        description: form.description || null,
        productType: form.productType,
        gradeLevel: form.gradeLevel ? Number(form.gradeLevel) : null,
        isFeatured: form.isFeatured,
        price,
        currencyCode: form.currencyCode,
        metadata: textMetadata(form),
        imageUrls,
        status: "draft",
      });
      toast.success("تم إنشاء المنتج كمسودة مع بياناته وصوره.");
      setForm(initialForm);
      setImageUrls([]);
      onCreated();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر إنشاء المنتج.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <section className="admin-card overflow-hidden">
      <div className="border-b border-[#eee1d0] px-6 py-5">
        <div className="flex items-start gap-3">
          <div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><Box className="size-5" /></div>
          <div><div className="section-kicker">دورة المنتج</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إضافة منتج مسودة</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">يُحفظ المنتج كمسودة مع بياناته وصوره، ثم يمر بمراجعة الإدارة قبل ظهوره للعملاء.</p></div>
        </div>
      </div>
      <form onSubmit={create} className="space-y-6 p-6">
        <div className="grid gap-4 md:grid-cols-2">
          <label className="text-sm font-semibold text-[#4f2e1f]">المتجر<select value={form.storeId} onChange={(event) => update("storeId", event.target.value)} className={`${inputClass} mt-2 h-10 w-full px-3 text-sm font-normal`}><option value="">اختر متجرًا معتمدًا</option>{availableStores.map((store) => <option key={store.id} value={store.id}>{store.name_ar} — {store.status}</option>)}</select></label>
          <label className="text-sm font-semibold text-[#4f2e1f]">التصنيف<select value={form.taxonomyId} onChange={(event) => update("taxonomyId", event.target.value)} disabled={loadingReferences} className={`${inputClass} mt-2 h-10 w-full px-3 text-sm font-normal`}><option value="">اختر تصنيف العسل</option>{taxonomy.map((item) => <option key={item.id} value={item.id}>{item.name_ar}{item.code ? ` — ${item.code}` : ""}</option>)}</select></label>
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <Input required value={form.nameAr} onChange={(event) => update("nameAr", event.target.value)} placeholder="اسم المنتج بالعربية" className={inputClass} />
          <Input value={form.nameEn} onChange={(event) => update("nameEn", event.target.value)} placeholder="اسم المنتج بالإنجليزية — اختياري" className={inputClass} />
        </div>
        <textarea value={form.description} onChange={(event) => update("description", event.target.value)} placeholder="وصف المنتج ومصدره وقيمته" className={`${inputClass} min-h-24 w-full border px-3 py-2 text-sm outline-none focus:border-[#9c5a00]`} />
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <label className="text-sm font-semibold text-[#4f2e1f]">نوع المنتج<select value={form.productType} onChange={(event) => update("productType", event.target.value)} className={`${inputClass} mt-2 h-10 w-full px-3 text-sm font-normal`}><option value="honey">عسل</option><option value="wax">شمع</option><option value="mix">خلطة نحلية</option><option value="raw">منتج خام</option><option value="gift">هدية</option></select></label>
          <label className="text-sm font-semibold text-[#4f2e1f]">درجة الجودة<select value={form.gradeLevel} onChange={(event) => update("gradeLevel", event.target.value)} className={`${inputClass} mt-2 h-10 w-full px-3 text-sm font-normal`}><option value="">غير محددة</option>{[1, 2, 3, 4, 5].map((level) => <option key={level} value={level}>درجة {level}</option>)}</select></label>
          <Input required dir="ltr" type="number" min="0" step="0.01" value={form.price} onChange={(event) => update("price", event.target.value)} placeholder="السعر" className={inputClass} />
          <Input dir="ltr" value={form.currencyCode} onChange={(event) => update("currencyCode", event.target.value)} placeholder="العملة YER" className={inputClass} />
        </div>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <Input value={form.weightLabel} onChange={(event) => update("weightLabel", event.target.value)} placeholder="الوزن أو الحجم" className={inputClass} />
          <Input value={form.originCountry} onChange={(event) => update("originCountry", event.target.value)} placeholder="بلد المصدر" className={inputClass} />
          <label className="text-sm font-semibold text-[#4f2e1f]">منطقة الإنتاج<select value={form.regionId} onChange={(event) => { const id = event.target.value; update("regionId", id); update("provinceNameAr", regions.find((region) => region.id === id)?.name_ar ?? ""); }} disabled={loadingReferences} className={`${inputClass} mt-2 h-10 w-full px-3 text-sm font-normal`}><option value="">اختر المنطقة</option>{regions.map((region) => <option key={region.id} value={region.id}>{region.name_ar}</option>)}</select></label>
          <Input value={form.provinceNameAr} onChange={(event) => update("provinceNameAr", event.target.value)} placeholder="المحافظة" className={inputClass} />
        </div>
        <div className="grid gap-4 md:grid-cols-3">
          <Input value={form.honeyIdentity} onChange={(event) => update("honeyIdentity", event.target.value)} placeholder="هوية العسل أو السلالة" className={inputClass} />
          <Input value={form.qualityLabelAr} onChange={(event) => update("qualityLabelAr", event.target.value)} placeholder="وصف الجودة أو التوثيق" className={inputClass} />
          <Input value={form.harvestLabel} onChange={(event) => update("harvestLabel", event.target.value)} placeholder="موسم الحصاد" className={inputClass} />
          <Input value={form.processingMethodAr} onChange={(event) => update("processingMethodAr", event.target.value)} placeholder="طريقة المعالجة" className={inputClass} />
          <Input value={form.processingStatusAr} onChange={(event) => update("processingStatusAr", event.target.value)} placeholder="حالة المعالجة" className={inputClass} />
          <Input value={form.packagingLabelAr} onChange={(event) => update("packagingLabelAr", event.target.value)} placeholder="نوع التغليف" className={inputClass} />
          <Input type="date" value={form.productionDate} onChange={(event) => update("productionDate", event.target.value)} className={inputClass} />
          <Input type="date" value={form.packagedDate} onChange={(event) => update("packagedDate", event.target.value)} className={inputClass} />
          <Input value={form.shelfLifeLabelAr} onChange={(event) => update("shelfLifeLabelAr", event.target.value)} placeholder="مدة الصلاحية" className={inputClass} />
        </div>
        <div className="grid gap-4 md:grid-cols-2">
          <textarea value={form.deliveryOptions} onChange={(event) => update("deliveryOptions", event.target.value)} placeholder="خيارات التوصيل — افصل بينها بفاصلة" className={`${inputClass} min-h-20 border px-3 py-2 text-sm outline-none focus:border-[#9c5a00]`} />
          <textarea value={form.pickupLocations} onChange={(event) => update("pickupLocations", event.target.value)} placeholder="نقاط الاستلام — افصل بينها بفاصلة" className={`${inputClass} min-h-20 border px-3 py-2 text-sm outline-none focus:border-[#9c5a00]`} />
          <Input value={form.availability} onChange={(event) => update("availability", event.target.value)} placeholder="حالة التوفر" className={inputClass} />
          <Input value={form.purpose} onChange={(event) => update("purpose", event.target.value)} placeholder="الاستخدام أو الغرض" className={inputClass} />
          <Input value={form.components} onChange={(event) => update("components", event.target.value)} placeholder="المكونات — بفاصلة" className={inputClass} />
          <Input value={form.forms} onChange={(event) => update("forms", event.target.value)} placeholder="الأشكال أو العبوات — بفاصلة" className={inputClass} />
          <Input value={form.tags} onChange={(event) => update("tags", event.target.value)} placeholder="الوسوم — بفاصلة" className={inputClass} />
          <Input value={form.certifications} onChange={(event) => update("certifications", event.target.value)} placeholder="الشهادات — بفاصلة" className={inputClass} />
        </div>
        <div className="rounded-2xl border border-[#eadcc9] bg-[#fffaf3] p-4">
          <div className="flex flex-wrap items-center justify-between gap-3"><div><p className="font-bold text-[#4f2e1f]">صور المنتج</p><p className="mt-1 text-xs leading-6 text-[#806b5a]">ترفع مباشرة إلى Storage Production وتُحفظ مع المنتج.</p></div><label className="inline-flex cursor-pointer items-center gap-2 rounded-xl bg-[#4f2e1f] px-4 py-2 text-sm font-semibold text-white hover:bg-[#6b412a]"><ImagePlus className="size-4" />{uploading ? "جارٍ الرفع..." : "إضافة صور"}<input type="file" accept="image/png,image/jpeg,image/webp,image/gif" multiple className="hidden" disabled={uploading} onChange={(event) => { void uploadImages(event.target.files); event.currentTarget.value = ""; }} /></label></div>
          {imageUrls.length > 0 ? <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">{imageUrls.map((url, index) => <div key={`${url}-${index}`} className="group relative overflow-hidden rounded-xl border border-[#eadcc9] bg-white"><img src={url} alt={`صورة المنتج ${index + 1}`} className="h-28 w-full object-cover" /><button type="button" onClick={() => setImageUrls((previous) => previous.filter((_, imageIndex) => imageIndex !== index))} className="absolute left-2 top-2 grid size-8 place-items-center rounded-lg bg-white/90 text-red-700 opacity-0 shadow transition-opacity group-hover:opacity-100"><Trash2 className="size-4" /></button></div>)}</div> : <p className="mt-4 text-sm text-[#8e7a68]">لم تُرفع صور بعد.</p>}
        </div>
        <label className="flex items-center gap-2 text-sm font-semibold text-[#4f2e1f]"><input type="checkbox" checked={form.isFeatured} onChange={(event) => update("isFeatured", event.target.checked)} />ترشيح المنتج بعد المراجعة كمنتج مميز</label>
        <Button type="submit" disabled={saving || uploading || !form.storeId || !form.taxonomyId} className="w-full bg-[#4f2e1f] hover:bg-[#6b412a]">{saving ? <Loader2 className="ml-2 size-4 animate-spin" /> : <Plus className="ml-2 size-4" />}{saving ? "جارٍ الحفظ..." : "حفظ المنتج كمسودة"}</Button>
      </form>
    </section>
  );
}
