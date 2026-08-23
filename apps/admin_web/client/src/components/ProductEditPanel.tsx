import { useEffect, useState } from "react";
import { ImagePlus, Save, Trash2, X } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type ProductImage = { id?: string; image_url: string; sort_order?: number | null };
type ProductRow = {
  id: string;
  store_id: string;
  taxonomy_id?: string | null;
  name_ar: string;
  name_en?: string | null;
  description?: string | null;
  product_type: string;
  grade_level?: number | null;
  status: string;
  is_featured: boolean;
  metadata?: Record<string, unknown> | null;
  product_images?: ProductImage[] | null;
};
type TaxonomyOption = { id: string; name_ar: string; code?: string | null };

const statuses = [
  ["draft", "مسودة"],
  ["pending", "قيد المراجعة"],
  ["active", "نشط"],
  ["paused", "متوقف مؤقتًا"],
  ["rejected", "مرفوض"],
] as const;

function fileToDataUrl(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(typeof reader.result === "string" ? reader.result : "");
    reader.onerror = () => reject(reader.error ?? new Error("تعذر قراءة الصورة."));
    reader.readAsDataURL(file);
  });
}

function initialMetadata(product: ProductRow): Record<string, unknown> {
  return { ...((product.metadata ?? {}) as Record<string, unknown>) };
}

export function ProductEditPanel({
  product,
  onSaved,
  onClose,
}: {
  product: ProductRow;
  onSaved: () => void;
  onClose: () => void;
}) {
  const [taxonomy, setTaxonomy] = useState<TaxonomyOption[]>([]);
  const [taxonomyError, setTaxonomyError] = useState<string | null>(null);
  const [taxonomyRequestKey, setTaxonomyRequestKey] = useState(0);
  const [nameAr, setNameAr] = useState(product.name_ar);
  const [nameEn, setNameEn] = useState(product.name_en ?? "");
  const [description, setDescription] = useState(product.description ?? "");
  const [productType, setProductType] = useState(product.product_type);
  const [gradeLevel, setGradeLevel] = useState(product.grade_level?.toString() ?? "");
  const [taxonomyId, setTaxonomyId] = useState(product.taxonomy_id ?? "");
  const [status, setStatus] = useState(product.status);
  const [price, setPrice] = useState(String(product.metadata?.price ?? ""));
  const [currencyCode, setCurrencyCode] = useState(String(product.metadata?.currency_code ?? "YER"));
  const [metadataText, setMetadataText] = useState(() => JSON.stringify(initialMetadata(product), null, 2));
  const [imageUrls, setImageUrls] = useState<string[]>(() => (product.product_images ?? []).slice().sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0)).map((image) => image.image_url));
  const [imagesChanged, setImagesChanged] = useState(false);
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    let active = true;
    setTaxonomyError(null);
    void adminApi.taxonomy().then((result) => {
      if (active) setTaxonomy(result.items as TaxonomyOption[]);
    }).catch((error) => {
      if (active) setTaxonomyError(error instanceof Error ? error.message : "تعذر قراءة التصنيفات.");
    });
    return () => { active = false; };
  }, [taxonomyRequestKey]);

  const retryTaxonomy = () => setTaxonomyRequestKey((key) => key + 1);

  const uploadImages = async (files: FileList | null) => {
    if (!files?.length) return;
    setUploading(true);
    try {
      const uploaded: string[] = [];
      for (const file of Array.from(files)) {
        if (!file.type.startsWith("image/")) throw new Error("اختر ملفات صور فقط.");
        if (file.size > 10 * 1024 * 1024) throw new Error("حجم كل صورة يجب ألا يتجاوز 10 ميجابايت.");
        const dataUrl = await fileToDataUrl(file);
        const result = await adminApi.uploadPublicImage({ contentType: file.type, base64: dataUrl, purpose: "admin-product-edit" });
        uploaded.push(result.item.publicUrl);
      }
      setImageUrls((previous) => [...previous, ...uploaded]);
      setImagesChanged(true);
      toast.success(`تم رفع ${uploaded.length} صورة.`);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر رفع الصور.");
    } finally {
      setUploading(false);
    }
  };

  const save = async () => {
    if (!nameAr.trim()) { toast.error("اسم المنتج مطلوب."); return; }
    let metadata: Record<string, unknown>;
    try {
      const parsed = JSON.parse(metadataText || "{}");
      if (!parsed || Array.isArray(parsed) || typeof parsed !== "object") throw new Error("metadata يجب أن يكون كائنًا.");
      metadata = parsed as Record<string, unknown>;
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "صيغة metadata غير صحيحة.");
      return;
    }
    const numericPrice = price.trim() ? Number(price) : null;
    if (numericPrice !== null && (!Number.isFinite(numericPrice) || numericPrice < 0)) { toast.error("السعر غير صحيح."); return; }
    setSaving(true);
    try {
      await adminApi.updateProduct(product.id, {
        taxonomyId: taxonomyId || null,
        nameAr: nameAr.trim(),
        nameEn: nameEn.trim() || null,
        description: description.trim() || null,
        productType,
        gradeLevel: gradeLevel.trim() ? Number(gradeLevel) : null,
        status,
        price: numericPrice,
        currencyCode: currencyCode.trim() || null,
        metadata,
        ...(imagesChanged ? { imageUrls } : {}),
      });
      toast.success("تم تحديث المنتج وبياناته.");
      onSaved();
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر تحديث المنتج.");
    } finally {
      setSaving(false);
    }
  };

  return <div className="space-y-5 text-right">
    <div className="flex items-start justify-between gap-3"><div><p className="section-kicker">تعديل المنتج</p><h3 className="mt-1 text-xl font-bold text-[#3f281d]">{product.name_ar}</h3><p className="mt-1 text-xs text-[#806b5a]" dir="ltr">{product.id}</p></div><Button onClick={onClose} variant="ghost" size="icon" aria-label="إغلاق"><X className="size-5" /></Button></div>
    {taxonomyError && <div role="alert" className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"><span>{taxonomyError}</span><Button type="button" variant="outline" onClick={retryTaxonomy} className="border-red-200 text-red-800">إعادة المحاولة</Button></div>}
    <div className="grid gap-3 rounded-2xl border border-[#eadcc9] p-4 md:grid-cols-2"><Input value={nameAr} onChange={(event) => setNameAr(event.target.value)} placeholder="اسم المنتج بالعربية" /><Input value={nameEn} onChange={(event) => setNameEn(event.target.value)} placeholder="اسم المنتج بالإنجليزية" /><textarea value={description} onChange={(event) => setDescription(event.target.value)} className="min-h-24 rounded-xl border border-[#eadcc9] bg-white p-3 text-sm md:col-span-2" placeholder="الوصف" /><select value={taxonomyId} onChange={(event) => setTaxonomyId(event.target.value)} disabled={!!taxonomyError} className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"><option value="">بدون تصنيف</option>{taxonomy.map((item) => <option key={item.id} value={item.id}>{item.name_ar}{item.code ? ` — ${item.code}` : ""}</option>)}</select><select value={status} onChange={(event) => setStatus(event.target.value)} className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm">{statuses.map(([value, label]) => <option key={value} value={value}>{label}</option>)}</select><Input value={productType} onChange={(event) => setProductType(event.target.value)} placeholder="نوع المنتج" /><Input value={gradeLevel} onChange={(event) => setGradeLevel(event.target.value)} type="number" min="0" placeholder="درجة الجودة" /><Input value={price} onChange={(event) => setPrice(event.target.value)} type="number" min="0" step="0.01" placeholder="السعر" /><Input value={currencyCode} onChange={(event) => setCurrencyCode(event.target.value)} placeholder="العملة" /></div>
    <div className="rounded-2xl border border-[#eadcc9] p-4"><div className="flex items-center justify-between gap-3"><p className="font-bold text-[#4f2e1f]">صور المنتج</p><label className="inline-flex cursor-pointer items-center gap-2 rounded-xl border border-[#d5ae76] px-3 py-2 text-xs font-semibold text-[#76502e]"><ImagePlus className="size-4" />{uploading ? "جاري الرفع…" : "إضافة صور"}<input type="file" accept="image/*" multiple className="hidden" disabled={uploading} onChange={(event) => void uploadImages(event.target.files)} /></label></div>{imageUrls.length === 0 ? <p className="mt-3 text-xs text-[#806b5a]">لا توجد صور محفوظة.</p> : <div className="mt-3 grid grid-cols-3 gap-2">{imageUrls.map((url, index) => <div className="relative overflow-hidden rounded-xl border border-[#eadcc9]" key={`${url}-${index}`}><img src={url} alt="صورة المنتج" className="h-24 w-full object-cover" /><Button type="button" onClick={() => { setImageUrls((previous) => previous.filter((_, itemIndex) => itemIndex !== index)); setImagesChanged(true); }} variant="destructive" size="icon" className="absolute left-1 top-1 size-7"><Trash2 className="size-3.5" /></Button></div>)}</div>}</div>
    <div className="rounded-2xl border border-[#eadcc9] p-4"><p className="font-bold text-[#4f2e1f]">البيانات الإضافية (metadata)</p><p className="mt-1 text-xs leading-6 text-[#806b5a]">يُحفظ الكائن كما هو مع دمج السعر والعملة. لا تضع أسرارًا أو مفاتيح هنا.</p><textarea value={metadataText} onChange={(event) => setMetadataText(event.target.value)} dir="ltr" className="mt-3 min-h-48 w-full rounded-xl border border-[#eadcc9] bg-white p-3 font-mono text-xs" /></div>
    <Button disabled={saving || uploading} onClick={() => void save()} className="w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Save className="ml-2 size-4" />{saving ? "جاري الحفظ…" : "حفظ التعديلات"}</Button>
  </div>;
}
