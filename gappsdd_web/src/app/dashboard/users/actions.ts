"use server";

import { createClient, createAdminClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function getUsers() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("user_profiles")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function getUser(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("user_profiles")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw error;
  return data;
}

export async function createUser(formData: FormData) {
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;
  const displayName = formData.get("name") as string;
  const role = formData.get("role") as string;

  // Use admin client to create user in auth
  const supabase = await createAdminClient();
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { display_name: displayName, role: role.toUpperCase() },
  });

  if (authError) throw authError;

  // Profile is auto-created by the trigger, but update the role
  const { error: profileError } = await supabase
    .from("user_profiles")
    .update({ display_name: displayName, role: role.toUpperCase() })
    .eq("id", authData.user.id);

  if (profileError) throw profileError;

  // Create business profile based on role
  if (role === "gardener") {
    await supabase
      .from("gardener_profiles")
      .insert({ user_id: authData.user.id, display_name: displayName });
  } else if (role === "client") {
    await supabase
      .from("client_profiles")
      .insert({ user_id: authData.user.id, display_name: displayName });
  }

  revalidatePath("/dashboard/users");
  redirect("/dashboard/users");
}

export async function updateUser(id: string, formData: FormData) {
  const displayName = formData.get("name") as string;
  const role = formData.get("role") as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from("user_profiles")
    .update({ display_name: displayName, role: role.toUpperCase() })
    .eq("id", id);

  if (error) throw error;

  revalidatePath("/dashboard/users");
  redirect("/dashboard/users");
}

export async function deleteUser(id: string) {
  const supabase = await createAdminClient();
  const { error } = await supabase.auth.admin.deleteUser(id);
  if (error) throw error;

  revalidatePath("/dashboard/users");
}
