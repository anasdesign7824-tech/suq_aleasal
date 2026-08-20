import { ChangeEvent, useEffect, useState } from "react";
import { Activity, BarChart3, BellRing, ChevronLeft, ChevronRight, Clock3, Globe2, Mail, MapPin, RefreshCw, Send, ShieldCheck, Store, Trash2, Users } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type UserRow = {
  id: string;
  email?: string | null;
  phone?: string | null;
  created_at?: string | null;
  last_seen_at?: string | null;
  authCreatedAt?: string | null;
  lastSignInAt?: string | null;
  lastActiveAt?: string | null;
  emailConfirmedAt?: string | null;
  profile?: { display_name?: string; phone?: string | null; role?: string; is_active?: boolean } | null;
  merchantApplication?: { status?: string; location?: string | null; review_note?: string | null; submitted_at?: string | null; reviewed_at?: string | null } | null;
  store?: { id?: string; name_ar?: string; status?: string; is_verified?: boolean; updated_at?: string | null } | null;
  networkTelemetry?: { ipAddress?: string | null; noteAr?: string };
};
type NotificationRow = { id: string; user_id: string; title_ar: string; body_ar?: string | null; read_at?: string | null; created_at: string };

function formatDate(value?: string | null): string {
  if (!value) return "غير مسجل";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "غير صالح" : date.toLocaleString("ar-YE", { dateStyle: "medium", timeStyle: "short" });
}

function roleLabel(value?: string): string {
  return value === "merchant" ? "تاجر" : value === "admin" ? "مدير" : "عميل";
}

function applicationLabel(value?: string): string {
  return value === "approved" ? "مفعّل" : value === "under_review" ? "قيد المراجعة" : value === "needs_more_info" ? "يحتاج معلومات" : value === "rejected" ? "مرفوض" : value === "submitted" ? "تم الإرسال" : "لا يوجد طلب";
}

export function UsersPanel() {
  const [items, setItems] = useState<UserRow[]>([]);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const pageSize = 20;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [removingUserId, setRemovingUserId] = useState<string | null>(null);
  const load = async (requestedPage = page) => { setLoading(true); setError(null); try { const result = await adminApi.users({ page: requestedPage, pageSize }); setItems(result.items as UserRow[]); setPage(result.page); setTotal(result.total); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة المستخدمين."); } finally { setLoading(false); } };
  const removeUser = async (user: UserRow) => {
    if (!window.confirm(`حذف المستخدم ${user.email ?? user.id} نهائيًا؟ ستُحذف بياناته التابعة حسب قيود Production.`)) return;
    setRemovingUserId(user.id);
    try { await adminApi.deleteUser(user.id); toast.success("تم حذف المستخدم."); await load(items.length === 1 && page > 1 ? page - 1 : page); }
    catch (requestError) { toast.error(requestError instanceof Error ? requestError.message : "تعذر حذف المستخدم."); }
    finally { setRemovingUserId(null); }
  };
  useEffect(() => { void load(1); }, []);
  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">دليل الحسابات</div><h2 className="mt-1 text-xl font-bold text-[#342118]">المستخدمون والتدقيق التشغيلي</h2><p className="mt-2 max-w-3xl text-sm leading-7 text-[#806b5a]">عرض مباشر من users وprofiles وSupabase Auth وطلبات التجار والمتاجر. لا تُعرض معلومات غير مسجلة، وعنوان IP يبقى غير متاح لأن مخطط Production الحالي لا يجمعه.</p></div><Button onClick={() => void load(page)} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button></div>{loading ? <div className="p-8 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="p-6 text-sm text-red-800">{error}</div> : items.length === 0 ? <div className="p-8 text-center text-sm leading-7 text-[#806b5a]">لا يوجد مستخدمون في المصدر الحقيقي بعد.</div> : <div className="divide-y divide-[#f1e7da]">{items.map((user) => { const application = user.merchantApplication; const store = user.store; return <article key={user.id} className="p-5"><div className="flex flex-wrap items-start gap-4"><div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-[#f3e9df] text-[#4f2e1f]"><Users className="size-5" /></div><div className="min-w-56 flex-1"><div className="flex flex-wrap items-center gap-2"><h3 className="font-bold text-[#432a1e]">{user.profile?.display_name ?? "مستخدم عسلكم"}</h3><Badge variant="outline" className="border-[#e3c28d] text-[#8b5a2b]">{roleLabel(user.profile?.role)}</Badge><Badge variant="outline" className={user.profile?.is_active === false ? "border-red-200 bg-red-50 text-red-800" : "border-emerald-200 bg-emerald-50 text-emerald-800"}>{user.profile?.is_active === false ? "معطّل" : "نشط"}</Badge></div><p className="mt-1 text-xs text-[#806b5a]" dir="ltr">{user.email ?? "بريد غير متاح"}</p><p className="mt-1 text-[11px] text-[#a18d7a]" dir="ltr">ID: {user.id}</p></div><div className="rounded-2xl bg-[#fff7e9] px-3 py-2 text-right"><p className="text-[11px] text-[#8e7a68]">حالة التاجر</p><p className="mt-1 text-sm font-bold text-[#4f2e1f]">{applicationLabel(application?.status)}</p></div></div><div className="mt-5 grid gap-3 md:grid-cols-2 xl:grid-cols-4"><div className="rounded-2xl border border-[#eee1d0] bg-white/70 p-3"><div className="flex items-center gap-2 text-xs font-bold text-[#4f2e1f]"><Clock3 className="size-4 text-[#9c5a00]" />إنشاء الهوية</div><p className="mt-2 text-xs text-[#806b5a]" dir="ltr">{formatDate(user.authCreatedAt ?? user.created_at)}</p></div><div className="rounded-2xl border border-[#eee1d0] bg-white/70 p-3"><div className="flex items-center gap-2 text-xs font-bold text-[#4f2e1f]"><Activity className="size-4 text-[#9c5a00]" />آخر دخول</div><p className="mt-2 text-xs text-[#806b5a]" dir="ltr">{formatDate(user.lastSignInAt)}</p></div><div className="rounded-2xl border border-[#eee1d0] bg-white/70 p-3"><div className="flex items-center gap-2 text-xs font-bold text-[#4f2e1f]"><RefreshCw className="size-4 text-[#9c5a00]" />آخر نشاط مسجل</div><p className="mt-2 text-xs text-[#806b5a]" dir="ltr">{formatDate(user.last_seen_at ?? user.lastActiveAt)}</p></div><div className="rounded-2xl border border-[#eee1d0] bg-white/70 p-3"><div className="flex items-center gap-2 text-xs font-bold text-[#4f2e1f]"><ShieldCheck className="size-4 text-[#9c5a00]" />تأكيد البريد</div><p className="mt-2 text-xs text-[#806b5a]" dir="ltr">{formatDate(user.emailConfirmedAt)}</p></div></div><div className="mt-3 grid gap-3 md:grid-cols-2 xl:grid-cols-4"><div className="rounded-2xl bg-[#faf6f0] p-3"><p className="text-[11px] font-bold text-[#4f2e1f]">الهاتف</p><p className="mt-2 text-xs text-[#806b5a]" dir="ltr">{user.phone ?? user.profile?.phone ?? "غير مسجل"}</p></div><div className="rounded-2xl bg-[#faf6f0] p-3"><div className="flex items-center gap-2 text-[11px] font-bold text-[#4f2e1f]"><MapPin className="size-3.5 text-[#9c5a00]" />الموقع</div><p className="mt-2 text-xs text-[#806b5a]">{application?.location ?? "غير مسجل"}</p></div><div className="rounded-2xl bg-[#faf6f0] p-3"><div className="flex items-center gap-2 text-[11px] font-bold text-[#4f2e1f]"><Store className="size-3.5 text-[#9c5a00]" />المتجر</div><p className="mt-2 text-xs text-[#806b5a]">{store?.name_ar ?? "لا يوجد متجر"}{store ? ` — ${store.status === "active" ? "نشط" : store.status ?? "غير محدد"}` : ""}</p></div><div className="rounded-2xl bg-[#faf6f0] p-3"><div className="flex items-center gap-2 text-[11px] font-bold text-[#4f2e1f]"><Globe2 className="size-3.5 text-[#9c5a00]" />IP والشبكة</div><p className="mt-2 text-xs text-[#806b5a]">{user.networkTelemetry?.ipAddress ?? "غير مسجل"}</p></div></div>{application?.review_note && <div className="mt-3 rounded-2xl border border-blue-100 bg-blue-50/60 p-3 text-xs leading-6 text-blue-900"><span className="font-bold">ملاحظة مراجعة التاجر:</span> {application.review_note}</div>}<div className="mt-3 flex flex-wrap gap-3 text-[11px] text-[#9a8571]"><span>إرسال الطلب: <b dir="ltr">{formatDate(application?.submitted_at)}</b></span><span>مراجعة الطلب: <b dir="ltr">{formatDate(application?.reviewed_at)}</b></span><span>{user.networkTelemetry?.noteAr ?? "بيانات الشبكة حسب ما هو مسجل فعليًا."}</span></div><div className="mt-4 flex justify-end"><Button onClick={() => void removeUser(user)} disabled={removingUserId === user.id} variant="outline" className="border-red-200 text-red-800"><Trash2 className="ml-2 size-4" />{removingUserId === user.id ? "جارٍ الحذف…" : "حذف المستخدم"}</Button></div></article>; })}</div>}{total > pageSize && <div className="flex flex-wrap items-center justify-between gap-3 border-t border-[#eee1d0] px-5 py-4 text-sm text-[#806b5a]"><span>عرض {((page - 1) * pageSize) + 1}–{Math.min(page * pageSize, total)} من أصل {total} مستخدم</span><div className="flex items-center gap-2"><Button disabled={page <= 1 || loading} onClick={() => void load(page - 1)} variant="outline" className="border-[#eadcc9] text-[#6f4b2d]"><ChevronRight className="ml-1 size-4" />السابق</Button><span className="rounded-lg bg-[#fff7e9] px-3 py-2 font-semibold text-[#4f2e1f]">صفحة {page}</span><Button disabled={page * pageSize >= total || loading} onClick={() => void load(page + 1)} variant="outline" className="border-[#eadcc9] text-[#6f4b2d]">التالي<ChevronLeft className="mr-1 size-4" /></Button></div></div>}</section>;
}

export function NotificationsPanel() {
  const [items, setItems] = useState<NotificationRow[]>([]);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ targetMode: "user" as "user" | "broadcast", userId: "", titleAr: "", bodyAr: "", imageUrl: "" });
  const [saving, setSaving] = useState(false);
  const [uploading, setUploading] = useState(false);
  const load = async () => { setLoading(true); try { setItems((await adminApi.notifications()).items as NotificationRow[]); } catch (requestError) { toast.error(requestError instanceof Error ? requestError.message : "تعذر قراءة الإشعارات."); } finally { setLoading(false); } };
  useEffect(() => { void load(); void adminApi.users().then((result) => setUsers(result.items as UserRow[])).catch(() => undefined); }, []);
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
      const uploaded = await adminApi.uploadPublicImage({ contentType: file.type, base64, purpose: "notifications" });
      setForm((previous) => ({ ...previous, imageUrl: uploaded.item.publicUrl }));
      toast.success("تم رفع الصورة.");
    } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر رفع الصورة."); }
    finally { setUploading(false); }
  };
  const send = async () => { setSaving(true); try { await adminApi.sendNotification({ broadcast: form.targetMode === "broadcast", userId: form.targetMode === "user" ? form.userId : null, titleAr: form.titleAr, bodyAr: form.bodyAr, imageUrl: form.imageUrl || null }); toast.success(form.targetMode === "broadcast" ? "تم إرسال الإشعار العام للمستخدمين الحاليين." : "تم إنشاء الإشعار للمستخدم."); setForm({ targetMode: form.targetMode, userId: "", titleAr: "", bodyAr: "", imageUrl: "" }); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر إنشاء الإشعار."); } finally { setSaving(false); } };
  return <section className="space-y-6"><div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]"><div className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">التواصل</div><h2 className="mt-1 text-xl font-bold text-[#342118]">الإشعارات</h2></div><BellRing className="size-5 text-[#9c5a00]" /></div>{loading ? <div className="p-8 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : items.length === 0 ? <div className="p-8 text-center text-sm leading-7 text-[#806b5a]">لا توجد إشعارات حقيقية بعد.</div> : <div className="divide-y divide-[#f1e7da]">{items.map((item) => <div key={item.id} className="flex gap-3 px-5 py-4"><Mail className="mt-1 size-4 text-[#9c5a00]" /><div><p className="font-semibold text-[#432a1e]">{item.title_ar}</p><p className="mt-1 text-sm text-[#806b5a]">{item.body_ar ?? "بدون نص"}</p><p className="mt-1 text-xs text-[#8e7a68]" dir="ltr">{item.user_id}</p></div></div>)}</div>}</div><div className="admin-card p-6"><div className="section-kicker">إرسال داخلي</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إشعار لمستخدم أو للجميع</h2><div className="mt-5 space-y-3"><div className="grid grid-cols-2 gap-2"><Button type="button" variant={form.targetMode === "user" ? "default" : "outline"} onClick={() => setForm({ ...form, targetMode: "user" })}>مستخدم واحد</Button><Button type="button" variant={form.targetMode === "broadcast" ? "default" : "outline"} onClick={() => setForm({ ...form, targetMode: "broadcast" })}>إشعار عام</Button></div>{form.targetMode === "user" && <label className="block text-sm font-semibold text-[#4f2e1f]">المستخدم المستهدف<select required value={form.userId} onChange={(event) => setForm({ ...form, userId: event.target.value })} className="mt-2 h-10 w-full rounded-xl border border-[#eadcc9] bg-white px-3 text-sm font-normal"><option value="">اختر مستخدمًا من الحسابات الحالية</option>{users.map((user) => <option key={user.id} value={user.id}>{user.profile?.display_name ?? user.email ?? user.id} — {user.email ?? "بريد غير متاح"}</option>)}</select></label>}<Input value={form.titleAr} onChange={(event) => setForm({ ...form, titleAr: event.target.value })} placeholder="عنوان الإشعار" className="rounded-xl border-[#eadcc9]" /><Input value={form.bodyAr} onChange={(event) => setForm({ ...form, bodyAr: event.target.value })} placeholder="النص" className="rounded-xl border-[#eadcc9]" /><label className="block text-sm font-semibold text-[#4f2e1f]">صورة اختيارية<Input type="file" accept="image/png,image/jpeg,image/webp,image/gif" onChange={uploadImage} disabled={uploading} className="mt-2 rounded-xl border-[#eadcc9]" />{form.imageUrl && <img src={form.imageUrl} alt="معاينة صورة الإشعار" className="mt-3 h-24 w-full rounded-xl object-cover" />}</label></div><Button disabled={saving || uploading} onClick={() => void send()} className="mt-5 w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Send className="ml-2 size-4" />{saving ? "جارٍ الإرسال…" : form.targetMode === "broadcast" ? "إرسال للجميع" : "إنشاء الإشعار"}</Button></div></div></section>;
}

const operationalLabels: Record<string, string> = { activeStores: "المتاجر النشطة", publishedProducts: "المنتجات المنشورة", openRequests: "طلبات التواصل المفتوحة", unreadNotifications: "الإشعارات غير المقروءة" };

export function AnalyticsPanel() {
  const [data, setData] = useState<{ counts: Record<string, number>; operational: Record<string, number>; generatedAt: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const load = async () => { setLoading(true); setError(null); try { setData(await adminApi.analytics()); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة التحليلات."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  return <section className="space-y-6"><div className="flex items-center justify-between"><div><div className="section-kicker">التحليل التشغيلي</div><h2 className="mt-1 text-2xl font-bold text-[#342118]">الإحصاءات التشغيلية</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">مؤشرات مشتقة من جداول Production الحالية فقط؛ لا توجد أرقام تقديرية.</p></div><Button onClick={() => void load()} variant="outline" className="border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div>{loading ? <div className="admin-card p-10 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="admin-card p-6 text-sm text-red-800">{error}</div> : <><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{Object.entries(data?.operational ?? {}).map(([key, value]) => <article key={key} className="admin-card p-5"><div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><BarChart3 className="size-5" /></div><p className="mt-5 text-3xl font-bold text-[#342118]">{value}</p><p className="mt-1 text-sm font-semibold text-[#4f2e1f]">{operationalLabels[key] ?? key}</p></article>)}</div><div className="admin-card p-6 text-sm text-[#806b5a]">آخر قراءة: <span dir="ltr">{data?.generatedAt}</span></div></>}</section>;
}
