import { useState } from "react";
import { Box, Plus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

export function ProductCreationPanel({ onCreated }: { onCreated: () => void }) {
  const [form, setForm] = useState({ storeId: "", nameAr: "", productType: "honey", price: "", currencyCode: "YER" });
  const [saving, setSaving] = useState(false);
  const create = async () => {
    setSaving(true);
    try { await adminApi.createProduct({ storeId: form.storeId, nameAr: form.nameAr, productType: form.productType, price: form.price ? Number(form.price) : null, currencyCode: form.currencyCode, status: "draft" }); toast.success("تم إنشاء المنتج كمسودة."); setForm({ storeId: "", nameAr: "", productType: "honey", price: "", currencyCode: "YER" }); onCreated(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر إنشاء المنتج."); } finally { setSaving(false); }
  };
  return <section className="admin-card p-6"><div className="flex items-start gap-3"><div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><Box className="size-5" /></div><div><div className="section-kicker">Product Lifecycle</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إضافة منتج مسودة</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">لا يُنشر المنتج مباشرة. يُحفظ مسودة ثم يمر بدورة المراجعة والنشر.</p></div></div><div className="mt-5 grid gap-3 md:grid-cols-[1.1fr_1.2fr_1fr_120px_120px_auto]"><Input dir="ltr" required value={form.storeId} onChange={(event) => setForm({ ...form, storeId: event.target.value })} placeholder="Store UUID" className="rounded-xl border-[#eadcc9]" /><Input required value={form.nameAr} onChange={(event) => setForm({ ...form, nameAr: event.target.value })} placeholder="اسم المنتج" className="rounded-xl border-[#eadcc9]" /><Input value={form.productType} onChange={(event) => setForm({ ...form, productType: event.target.value })} placeholder="honey" className="rounded-xl border-[#eadcc9]" /><Input dir="ltr" type="number" min="0" value={form.price} onChange={(event) => setForm({ ...form, price: event.target.value })} placeholder="السعر" className="rounded-xl border-[#eadcc9]" /><Input dir="ltr" value={form.currencyCode} onChange={(event) => setForm({ ...form, currencyCode: event.target.value })} placeholder="YER" className="rounded-xl border-[#eadcc9]" /><Button disabled={saving || !form.storeId.trim() || !form.nameAr.trim()} onClick={() => void create()} className="bg-[#4f2e1f] hover:bg-[#6b412a]"><Plus className="ml-2 size-4" />حفظ</Button></div></section>;
}
