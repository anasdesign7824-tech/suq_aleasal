import { useState } from "react";
import { KeyRound, UserPlus } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { adminApi } from "@/lib/admin-api";

export function AdminCreationPanel() {
  const [email, setEmail] = useState("");
  const [roleCode, setRoleCode] = useState("moderator");
  const [temporaryPassword, setTemporaryPassword] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const create = async () => {
    setSaving(true);
    try {
      const response = await adminApi.createAdminUser({ email, roleCode });
      const item = response.item as { email: string; temporaryPassword: string };
      setTemporaryPassword(item.temporaryPassword);
      setEmail("");
      toast.success("تم إنشاء الهوية الإدارية وربطها بالدور.");
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "تعذر إنشاء المدير.");
    } finally { setSaving(false); }
  };
  return <section className="admin-card p-6"><div className="flex items-start gap-3"><div className="grid size-11 place-items-center rounded-2xl bg-[#fff0d6] text-[#9c5a00]"><UserPlus className="size-5" /></div><div><div className="section-kicker">الهوية الإدارية</div><h2 className="mt-1 text-xl font-bold text-[#342118]">إنشاء مدير فرعي</h2><p className="mt-2 text-sm leading-7 text-[#806b5a]">ينفذها المدير العام فقط. كلمة المرور لا تُخزن في قاعدة البيانات وتظهر مرة واحدة.</p></div></div><div className="mt-5 grid gap-3 md:grid-cols-[minmax(0,1fr)_180px_auto]"><Input dir="ltr" type="email" required value={email} onChange={(event) => setEmail(event.target.value)} placeholder="admin@example.com" className="rounded-xl border-[#eadcc9]" /><select value={roleCode} onChange={(event) => setRoleCode(event.target.value)} className="h-10 rounded-xl border border-[#eadcc9] bg-white px-3 text-sm"><option value="admin">مدير تشغيل</option><option value="moderator">مشرف محتوى</option></select><Button disabled={saving || !email.trim()} onClick={() => void create()} className="bg-[#4f2e1f] hover:bg-[#6b412a]"><UserPlus className="ml-2 size-4" />إنشاء</Button></div>{temporaryPassword && <div className="mt-5 rounded-2xl border border-amber-300 bg-amber-50 p-4"><div className="flex items-center gap-2 text-sm font-bold text-amber-900"><KeyRound className="size-4" />بيانات التسليم لمرة واحدة</div><p className="mt-2 text-xs leading-6 text-amber-900">انسخ كلمة المرور وسلّمها للمدير خارج الواجهة، ثم اطلب تغييرها بعد الدخول الأول.</p><div className="mt-3 grid gap-2 rounded-xl bg-white/70 p-3 text-sm" dir="ltr"><code className="select-all font-semibold text-[#4f2e1f]">{temporaryPassword}</code><Button variant="outline" size="sm" onClick={() => { void navigator.clipboard?.writeText(temporaryPassword); toast.success("تم نسخ كلمة المرور."); }} className="border-amber-300 text-amber-900">نسخ</Button></div></div>}</section>;
}
