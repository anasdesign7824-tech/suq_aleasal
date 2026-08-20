import { useEffect, useState } from "react";
import { History, RefreshCw, ShieldCheck, UserCog } from "lucide-react";
import { toast } from "sonner";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { adminApi } from "@/lib/admin-api";

type AdminUser = { user_id: string; email?: string | null; name?: string | null; is_active: boolean; role?: { code: string; name_ar: string } | null; created_at: string };
type AuditLog = { id: string; action: string; entity_type: string; entity_id?: string | null; created_at: string; actor_user_id?: string | null };

export function AdminUsersPanel() {
  const [items, setItems] = useState<AdminUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const load = async () => { setLoading(true); setError(null); try { setItems((await adminApi.adminUsers()).items as AdminUser[]); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة المديرين."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  const toggle = async (item: AdminUser) => { try { await adminApi.updateAdminUser(item.user_id, { isActive: !item.is_active }); toast.success(item.is_active ? "تم تعطيل العضوية." : "تم تفعيل العضوية."); await load(); } catch (requestError) { toast.error(requestError instanceof Error ? requestError.message : "تعذر تحديث العضوية."); } };
  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">الهوية والصلاحيات</div><h2 className="mt-1 text-xl font-bold text-[#342118]">المديرون</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">هوية الإدارة مستقلة عن Customer Auth وOTP، وعضويتها مربوطة بالدور والصلاحيات.</p></div><Button onClick={() => void load()} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button></div>{loading ? <div className="p-8 text-center text-sm text-[#806b5a]"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="p-6 text-sm text-red-800">{error}</div> : <div className="divide-y divide-[#f1e7da]">{items.map((item) => <div key={item.user_id} className="flex flex-wrap items-center gap-3 px-5 py-4"><div className="grid size-10 place-items-center rounded-2xl bg-[#f3e9df] text-[#4f2e1f]"><UserCog className="size-5" /></div><div className="min-w-48 flex-1"><p className="font-semibold text-[#432a1e]">{item.name ?? "مدير عسلكم"}</p><p className="mt-1 text-xs text-[#806b5a]" dir="ltr">{item.email ?? item.user_id}</p></div><Badge variant="outline" className="border-[#e3c28d] text-[#8b5a2b]">{item.role?.name_ar ?? item.role?.code ?? "دون دور"}</Badge><Badge variant="outline" className={item.is_active ? "border-emerald-300 bg-emerald-50 text-emerald-800" : "border-red-300 bg-red-50 text-red-800"}>{item.is_active ? "نشط" : "معطل"}</Badge><Button onClick={() => void toggle(item)} variant="outline" size="sm" className="border-[#eadcc9] text-[#8b5a2b]">{item.is_active ? "تعطيل" : "تفعيل"}</Button></div>)}{items.length === 0 && <div className="p-8 text-center text-sm text-[#806b5a]">لا توجد عضويات إدارة.</div>}</div>}</section>;
}

export function AuditPanel() {
  const [items, setItems] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const load = async () => { setLoading(true); setError(null); try { setItems((await adminApi.auditLogs()).items as AuditLog[]); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر قراءة التدقيق."); } finally { setLoading(false); } };
  useEffect(() => { void load(); }, []);
  return <section className="admin-card overflow-hidden"><div className="flex items-start justify-between border-b border-[#eee1d0] px-5 py-5"><div><div className="section-kicker">المراجعة الأمنية</div><h2 className="mt-1 text-xl font-bold text-[#342118]">سجل التدقيق</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">كل كتابة إدارية ناجحة تسجل actor وentity وaction في Production.</p></div><div className="flex items-center gap-2"><History className="size-5 text-[#9c5a00]" /><Button onClick={() => void load()} variant="ghost" size="icon" className="text-[#8b5a2b]"><RefreshCw className="size-4" /></Button></div></div>{loading ? <div className="p-8 text-center text-sm text-[#806b5a]"><RefreshCw className="mx-auto size-5 animate-spin text-[#c77d1a]" /></div> : error ? <div className="p-6 text-sm text-red-800">{error}</div> : <div className="divide-y divide-[#f1e7da]">{items.length ? items.map((item) => <div key={item.id} className="flex flex-wrap items-center gap-3 px-5 py-4 text-sm"><ShieldCheck className="size-4 text-[#9c5a00]" /><span className="font-semibold text-[#432a1e]">{item.action}</span><span className="text-[#806b5a]">{item.entity_type}</span><span className="mr-auto text-xs text-[#8e7a68]" dir="ltr">{new Date(item.created_at).toLocaleString("ar-YE")}</span></div>) : <div className="p-8 text-center text-sm text-[#806b5a]">لا توجد عمليات مدققة بعد.</div>}</div>}</section>;
}
