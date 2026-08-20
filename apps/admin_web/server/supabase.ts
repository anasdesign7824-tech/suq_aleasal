import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import type { Database } from "../../../packages/contracts_ts/src/database";

function requiredEnv(...names: string[]): string {
  for (const name of names) {
    const value = process.env[name]?.trim();
    if (value) return value;
  }
  throw new Error(`Missing server environment variable: ${names.join(" or ")}`);
}

export function getSupabaseUrl(): string {
  return requiredEnv("ASSALKOM_SUPABASE_URL", "SUPABASE_URL");
}

export function getSupabasePublishableKey(): string {
  return requiredEnv(
    "ASSALKOM_SUPABASE_PUBLISHABLE_KEY",
    "SUPABASE_PUBLISHABLE_KEY",
    "SUPABASE_ANON_KEY",
    "SUPABASE_KEY",
  );
}

export function createPublicSupabaseClient(accessToken?: string): SupabaseClient<Database> {
  return createClient<Database>(getSupabaseUrl(), getSupabasePublishableKey(), {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
    global: accessToken
      ? {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        }
      : undefined,
  });
}

export function createServiceSupabaseClient(): SupabaseClient<Database> {
  const serviceRoleKey = requiredEnv(
    "ASSALKOM_SUPABASE_SERVICE_ROLE_KEY",
    "SUPABASE_SERVICE_ROLE_KEY",
    "service_role",
  );
  return createClient<Database>(getSupabaseUrl(), serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
}
