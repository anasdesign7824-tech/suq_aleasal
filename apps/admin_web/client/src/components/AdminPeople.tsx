import { useEffect, useState } from "react";
import { BellRing, BarChart3, Mail, RefreshCw, Send, Users } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

type UserRow = { id: string; email?: string | null; last_seen_at?: string | null; profile?: { display_name?: string; role?: string; is_active?: boolean } | null };
type NotificationRow = { id: string; user_id: string; title_ar: string; body_ar?: string | null; read_at?: string | null; created_at: string };

export function UsersPanel() {
  const [items, setItems] = useState<UserRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const load = async () => { setLoading(true); setError(null); try { setItems((await adminApi.users()).items as UserRow[]); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة المستخدمين."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">Customer Directory</div><h2 className="mt-1 text-xl font-bold text-[#342118]">المستخدمون</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">قراءة من users وprofiles وAuth. لا تمنح هذه الشاشة صلاحيات إدارية تلقائيًا.</p></div><Button onClick={() => void load()} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button></div>{loading ? <div className="p-8 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="p-6 text-sm text-red-800">{error}</div> : items.length === 0 ? <div className="p-8 text-center text-sm leading-7 text-[#806b5a]">لا يوجد مستخدمون في المصدر الحقيقي بعد.</div> : <div className="divide-y divide-[#f1e7da]">{items.map((user) => <div key={user.id} className="flex flex-wrap items-center gap-3 px-5 py-4"><div className="grid size-10 place-items-center rounded-2xl bg-[#f3e9df] text-[#4f2e1f]"><Users className="size-5" /></div><div className="min-w-48 flex-1"><p className="font-semibold text-[#432a1e]">{user.profile?.display_name ?? "مستخدم عسلكم"}</p><p className="mt-1 text-xs text-[#806b5a]" dir="ltr">{user.email ?? user.id}</p></div><Badge variant="outline" className="border-[#e3c28d] text-[#8b5a2b]">{user.profile?.role ?? "customer"}</Badge><span className="text-xs text-[#8e7a68]">{user.last_seen_at ? new Date(user.last_seen_at).toLocaleDateString("ar-YE") : "لم يسجل نشاطًا"}</span></div>)}</div>}</section>;
}

export function NotificationsPanel() {
  const [items, setItems] = useState<NotificationRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ userId: "", titleAr: "", bodyAr: "" });
  const [saving, setSaving] = useState(false);
  const load = async () => { setLoading(true); try { setItems((await adminApi.notifications()).items as NotificationRow[]); } catch (requestError) { toast.error(requestError instanceof Error ? requestError.message : "تعذر قراءة الإشعارات."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  const send = async () => { setSaving(true); try { await adminApi.sendNotification({ userId: form.userId, titleAr: form.titleAr, bodyAr: form.bodyAr }); toast.success("تم إنشاء الإشعار."); setForm({ userId: "", titleAr: "", bodyAr: "" }); await load(); } catch (error) { toast.error(error instanceof Error ? error.message : "تعذر إنشاء الإشعار."); } finally { setSaving(false); } };
  return <section className="space-y-6"><div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]"><div className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">Communication</div><h2 className="mt-1 text-xl font-bold text-[#342118]">الإشعارات</h2></div><BellRing className="size-5 text-[#9c5a00]" /></div>{loading ? <div className="p-8 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : items.length === 0 ? <div className="p-8 text-center text-sm leading-7 text-[#806b5a]">لا توجد إشعارات حقيقية بعد.</div> : <div className="divide-y divide-[#f1e7da]">{items.map((item) => <div key={item.id} className="flex gap-3 px-5 py-4"><Mail className="mt-1 size-4 text-[#9c5a00]" /><div><p className="font-semibold text-[#432a1e]">{item.title_ar}</p><p className="mt-1 text-sm text-[#806b5a]">{item.body_ar ?? "بدون نص"}</p><p className="mt-1 text-xs text-[#8e7a68]" dir="ltr">{item.user_id}</p></div></div>)}</div>}</div><div className="admin-card p-6"><div className="section-kicker">إرسال داخلي</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إشعار لمستخدم</h2><div className="mt-5 space-y-3"><Input dir="ltr" value={form.userId} onChange={(event) => setForm({ ...form, userId: event.target.value })} placeholder="معرف المستخدم UUID" className="rounded-xl border-[#eadcc9]" /><Input value={form.titleAr} onChange={(event) => setForm({ ...form, titleAr: event.target.value })} placeholder="عنوان الإشعار" className="rounded-xl border-[#eadcc9]" /><Input value={form.bodyAr} onChange={(event) => setForm({ ...form, bodyAr: event.target.value })} placeholder="النص" className="rounded-xl border-[#eadcc9]" /></div><Button disabled={saving} onClick={() => void send()} className="mt-5 w-full bg-[#4f2e1f] hover:bg-[#6b412a]"><Send className="ml-2 size-4" />{saving ? "جارٍ الإرسال…" : "إنشاء الإشعار"}</Button></div></div></section>;
}

export function AnalyticsPanel() {
  const [data, setData] = useState<{ counts: Record<string, number>; operational: Record<string, number>; generatedAt: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const load = async () => { setLoading(true); setError(null); try { setData(await adminApi.analytics()); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة التحليلات."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  return <section className="space-y-6"><div className="flex items-center justify-between"><div><div className="section-kicker">Operational Analytics</div><h2 className="mt-1 text-2xl font-bold text-[#342118]">الإحصاءات التشغيلية</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">مؤشرات مشتقة من جداول Production الحالية فقط؛ لا توجد أرقام تقديرية.</p></div><Button onClick={() => void load()} variant="outline" className="border-[#eadcc9] text-[#8b5a2b]"><RefreshCw className="ml-2 size-4" />تحديث</Button></div>{loading ? <div className="admin-card p-10 text-center"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="admin-card p-6 text-sm text-red-800">{error}</div> : <><div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{Object.entries(data?.operational ?? {}).map(([key, value]) => <article key={key} className="admin-card p-5"><div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><BarChart3 className="size-5" /></div><p className="mt-5 text-3xl font-bold text-[#342118]">{value}</p><p className="mt-1 text-sm font-semibold text-[#4f2e1f]" dir="ltr">{key}</p></article>)}</div><div className="admin-card p-6 text-sm text-[#806b5a]">آخر قراءة: <span dir="ltr">{data?.generatedAt}</span></div></>}</section>;
}
