"use server";

import { createClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function getGardeners() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("gardener_profiles")
    .select(`
      *,
      user:user_profiles!gardener_profiles_user_id_fkey(email:display_name, role),
      assignments:garden_assignments(count)
    `)
    .order("created_at", { ascending: false });

  if (error) {
    // Fallback: simpler query without joins
    const { data: simple, error: simpleError } = await supabase
      .from("gardener_profiles")
      .select("*")
      .order("created_at", { ascending: false });
    if (simpleError) throw simpleError;
    return simple;
  }
  return data;
}

export async function getGardener(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("gardener_profiles")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw error;
  return data;
}

export async function updateGardener(id: string, formData: FormData) {
  const displayName = formData.get("name") as string;
  const phone = formData.get("phone") as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from("gardener_profiles")
    .update({ display_name: displayName, phone })
    .eq("id", id);

  if (error) throw error;

  revalidatePath("/dashboard/gardeners");
  redirect("/dashboard/gardeners");
}
