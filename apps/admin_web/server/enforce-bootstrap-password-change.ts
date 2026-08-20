import { createServiceSupabaseClient } from "./supabase";

async function main() {
  const service = createServiceSupabaseClient();
  const memberships = await service.from("admin_users").select("user_id").eq("is_active", true).limit(1);
  if (memberships.error) throw memberships.error;
  const userId = memberships.data?.[0]?.user_id;
  if (!userId) throw new Error("No active Admin Identity found.");
  const identity = await service.auth.admin.getUserById(userId);
  if (identity.error || !identity.data.user) throw identity.error ?? new Error("Admin Identity not found.");
  const current = identity.data.user.user_metadata ?? {};
  const result = await service.auth.admin.updateUserById(userId, { user_metadata: { ...current, must_change_password: true } });
  if (result.error) throw result.error;
  console.log(JSON.stringify({ ok: true, userId, email: result.data.user?.email }, null, 2));
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
