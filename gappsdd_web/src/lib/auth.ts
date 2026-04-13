import { createClient } from "@/lib/supabase/server";
import type { CurrentUser, UserRole } from "@/types";

export async function getCurrentUser(): Promise<CurrentUser | null> {
  const supabase = await createClient();

  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: profile } = await supabase
    .from("user_profiles")
    .select("role, company_id")
    .eq("id", user.id)
    .single();

  if (!profile) return null;

  return {
    id: user.id,
    role: profile.role as UserRole,
    companyId: profile.company_id ?? null,
  };
}

export function isSuperAdmin(user: CurrentUser | null): boolean {
  return user?.role === "SUPER_ADMIN" || user?.role === "ADMIN";
}

export function isCompanyAdmin(user: CurrentUser | null): boolean {
  return user?.role === "COMPANY_ADMIN";
}
