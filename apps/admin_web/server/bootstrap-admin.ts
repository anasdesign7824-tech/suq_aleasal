import { randomBytes } from "node:crypto";
import { mkdir, chmod, writeFile } from "node:fs/promises";
import path from "node:path";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "../../../packages/contracts_ts/src/database";

const url = (process.env.ASSALKOM_SUPABASE_URL || process.env.SUPABASE_URL || "").trim();
const serviceRoleKey = (process.env.ASSALKOM_SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.service_role || "").trim();
const email = (process.env.ASSALKOM_BOOTSTRAP_ADMIN_EMAIL || "admin@assalkom.local").trim().toLowerCase();

if (!url || !serviceRoleKey) {
  throw new Error("Bootstrap requires ASSALKOM_SUPABASE_URL and ASSALKOM_SUPABASE_SERVICE_ROLE_KEY in the local server environment.");
}

const supabase = createClient<Database>(url, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
});

const credentialsPath = path.resolve(process.cwd(), ".admin-bootstrap", "credentials.txt");

async function main() {
  const state = await supabase.from("admin_bootstrap_state").select("id").eq("id", true).maybeSingle();
  if (state.error) throw state.error;
  if (state.data) throw new Error("Bootstrap is already completed and is intentionally locked.");

  const role = await supabase.from("admin_roles").select("id").eq("code", "super_admin").single();
  if (role.error || !role.data) throw role.error ?? new Error("super_admin role is missing.");

  const membershipRows = await supabase.from("admin_users").select("user_id, role_id, is_active").eq("role_id", role.data.id).eq("is_active", true).limit(1);
  if (membershipRows.error) throw membershipRows.error;
  const existingAdminId = membershipRows.data?.[0]?.user_id;
  const users = await supabase.auth.admin.listUsers({ page: 1, perPage: 1000 });
  if (users.error) throw users.error;
  const existing = existingAdminId ? users.data.users.find((user) => user.id === existingAdminId) : users.data.users.find((user) => user.email?.toLowerCase() === email);
  const password = randomBytes(24).toString("base64url");
  const identity = existing
    ? await supabase.auth.admin.updateUserById(existing.id, { password, email_confirm: true, user_metadata: { name: "مدير عسلكم", must_change_password: true } })
    : await supabase.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { name: "مدير عسلكم", must_change_password: true } });
  if (identity.error || !identity.data.user) throw identity.error ?? new Error("Failed to create Admin Auth Identity.");

  const membership = await supabase.from("admin_users").upsert({
    user_id: identity.data.user.id,
    role_id: role.data.id,
    is_active: true,
    scope: {},
  }).select("user_id").single();
  if (membership.error) {
    if (!existing) await supabase.auth.admin.deleteUser(identity.data.user.id);
    throw membership.error;
  }

  const loginEmail = identity.data.user.email ?? email;
  const bootstrap = await supabase.from("admin_bootstrap_state").insert({
    id: true,
    admin_user_id: identity.data.user.id,
    bootstrapped_by: identity.data.user.id,
  });
  if (bootstrap.error) throw bootstrap.error;

  await mkdir(path.dirname(credentialsPath), { recursive: true });
  await writeFile(credentialsPath, [
    "عسلكم — بيانات الدخول الأولية للوحة الإدارة المحلية",
    "",
    `البريد الإداري: ${loginEmail}`,
    `كلمة المرور المؤقتة: ${password}`,
    "",
    "هذه البيانات لا تُحفظ في جدول admin_users. غيّر كلمة المرور بعد أول دخول، ثم احذف هذا الملف من جهاز الإدارة.",
    "Bootstrap مغلق بعد نجاح العملية ولا يعاد تشغيله من واجهة الإدارة.",
  ].join("\n"), { encoding: "utf8", mode: 0o600 });
  await chmod(credentialsPath, 0o600);

  console.log(JSON.stringify({ ok: true, email: loginEmail, adminUserId: identity.data.user.id, credentialsPath }, null, 2));
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : error);
  process.exitCode = 1;
});
