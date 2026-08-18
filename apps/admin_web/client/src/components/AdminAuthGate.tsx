import { FormEvent, ReactNode, useEffect, useState } from "react";
import { ShieldCheck } from "lucide-react";
import { adminApi, type AdminSessionPayload } from "@/lib/admin-api";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export type AdminAuthContextValue = {
  session: AdminSessionPayload;
  refresh: () => Promise<void>;
  logout: () => Promise<void>;
};

export function AdminAuthGate({ children }: { children: (context: AdminAuthContextValue) => ReactNode }) {
  const [session, setSession] = useState<AdminSessionPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = async () => {
    setLoading(true);
    try {
      setSession(await adminApi.session());
      setError(null);
    } catch (requestError) {
      setSession(null);
      if ((requestError as { status?: number }).status !== 401) {
        setError(requestError instanceof Error ? requestError.message : "تعذر التحقق من جلسة الإدارة.");
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void refresh();
  }, []);

  const logout = async () => {
    await adminApi.logout();
    setSession(null);
  };

  if (loading) {
    return <div className="grid min-h-screen place-items-center bg-[#fbf8f2] text-[#4f2e1f]" dir="rtl"><div className="text-center"><ShieldCheck className="mx-auto size-9 animate-pulse text-[#c77d1a]" /><p className="mt-3 text-sm font-semibold">جارٍ التحقق من هوية الإدارة…</p></div></div>;
  }

  if (!session) return <AdminLogin error={error} onSuccess={(next) => setSession(next)} />;
  if (session.requiresPasswordChange) return <AdminPasswordChange onSuccess={(next) => setSession(next)} onLogout={logout} />;
  return <>{children({ session, refresh, logout })}</>;
}

function AdminPasswordChange({ onSuccess, onLogout }: { onSuccess: (session: AdminSessionPayload) => void; onLogout: () => Promise<void> }) {
  const [password, setPassword] = useState("");
  const [confirmation, setConfirmation] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const submit = async (event: FormEvent) => {
    event.preventDefault();
    if (password.length < 12 || password !== confirmation) { setError("استخدم كلمة مرور من 12 حرفًا على الأقل وتأكد من تطابق الحقلين."); return; }
    setSubmitting(true); setError(null);
    try { onSuccess(await adminApi.changePassword(password)); } catch (requestError) { setError(requestError instanceof Error ? requestError.message : "تعذر تغيير كلمة المرور."); } finally { setSubmitting(false); }
  };
  return <main className="grid min-h-screen place-items-center bg-[#fbf8f2] px-5 py-10" dir="rtl"><section className="w-full max-w-md rounded-[30px] border border-[#eadcc9] bg-white p-7 shadow-[0_24px_70px_rgba(79,46,31,.12)] sm:p-9"><div className="mx-auto grid size-16 place-items-center rounded-2xl bg-[#4f2e1f] text-[#f7c769]"><ShieldCheck className="size-8" /></div><div className="mt-6 text-center"><p className="text-[11px] font-bold tracking-[.18em] text-[#a37747]">FIRST LOGIN SECURITY</p><h1 className="mt-2 text-2xl font-bold text-[#342118]">غيّر كلمة المرور</h1><p className="mt-3 text-sm leading-7 text-[#806b5a]">هذه خطوة إلزامية بعد بيانات Bootstrap. لن تُفتح أدوات الإدارة قبل إكمالها.</p></div><form onSubmit={submit} className="mt-7 space-y-4"><label className="block text-sm font-semibold text-[#4f2e1f]">كلمة المرور الجديدة<Input dir="ltr" type="password" required minLength={12} autoComplete="new-password" value={password} onChange={(event) => setPassword(event.target.value)} className="mt-2 h-11 rounded-xl border-[#eadcc9]" /></label><label className="block text-sm font-semibold text-[#4f2e1f]">تأكيد كلمة المرور<Input dir="ltr" type="password" required minLength={12} autoComplete="new-password" value={confirmation} onChange={(event) => setConfirmation(event.target.value)} className="mt-2 h-11 rounded-xl border-[#eadcc9]" /></label>{error && <p role="alert" className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm leading-6 text-red-800">{error}</p>}<Button type="submit" disabled={submitting} className="h-11 w-full rounded-xl bg-[#4f2e1f] text-white hover:bg-[#6b412a]">{submitting ? "جارٍ الحفظ…" : "حفظ وفتح الإدارة"}</Button><Button type="button" onClick={() => void onLogout()} variant="ghost" className="h-11 w-full text-[#806b5a]">تسجيل الخروج</Button></form></section></main>;
}

function AdminLogin({ error: initialError, onSuccess }: { error: string | null; onSuccess: (session: AdminSessionPayload) => void }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState(initialError);
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      onSuccess(await adminApi.login(email, password));
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "تعذر تسجيل الدخول الإداري.");
    } finally {
      setSubmitting(false);
    }
  };

  return <main className="grid min-h-screen place-items-center bg-[#fbf8f2] px-5 py-10" dir="rtl">
    <section className="w-full max-w-md rounded-[30px] border border-[#eadcc9] bg-white p-7 shadow-[0_24px_70px_rgba(79,46,31,.12)] sm:p-9">
      <div className="mx-auto grid size-16 place-items-center rounded-2xl bg-[#4f2e1f] text-[#f7c769] shadow-[0_14px_30px_rgba(79,46,31,.20)]"><ShieldCheck className="size-8" /></div>
      <div className="mt-6 text-center"><p className="text-[11px] font-bold tracking-[.18em] text-[#a37747]">PRIVATE LOCAL CONSOLE</p><h1 className="mt-2 text-2xl font-bold text-[#342118]">دخول إدارة عسلكم</h1><p className="mt-3 text-sm leading-7 text-[#806b5a]">هذه هوية إدارية مستقلة. لا تستخدم OTP الخاص بتطبيق العميل، ولا تفتح من الواجهة العامة.</p></div>
      <form onSubmit={submit} className="mt-7 space-y-4">
        <label className="block text-sm font-semibold text-[#4f2e1f]">البريد الإداري<Input dir="ltr" type="email" required autoComplete="username" value={email} onChange={(event) => setEmail(event.target.value)} className="mt-2 h-11 rounded-xl border-[#eadcc9]" /></label>
        <label className="block text-sm font-semibold text-[#4f2e1f]">كلمة المرور<Input dir="ltr" type="password" required autoComplete="current-password" value={password} onChange={(event) => setPassword(event.target.value)} className="mt-2 h-11 rounded-xl border-[#eadcc9]" /></label>
        {error && <p role="alert" className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm leading-6 text-red-800">{error}</p>}
        <Button type="submit" disabled={submitting} className="h-11 w-full rounded-xl bg-[#4f2e1f] text-white hover:bg-[#6b412a]">{submitting ? "جارٍ التحقق…" : "الدخول إلى الإدارة"}</Button>
      </form>
      <p className="mt-6 text-center text-xs leading-6 text-[#967f6c]">تعمل هذه اللوحة محليًا على جهاز الإدارة، وتتصل عند الحاجة بمصدر Supabase Production المصرح به.</p>
    </section>
  </main>;
}

export default AdminAuthGate;
