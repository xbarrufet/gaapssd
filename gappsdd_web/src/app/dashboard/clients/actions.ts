"use server";

import { createClient, createAdminClient } from "@/lib/supabase/server";
import { getCurrentUser } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function getClients() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("client_profiles")
    .select("*, gardens(id, name, address, latitude, longitude, garden_assignments(id, gardener_id, is_active, gardener_profiles(id, display_name)))")
    .order("created_at", { ascending: false });

  if (error) {
    const { data: simple, error: simpleError } = await supabase
      .from("client_profiles")
      .select("*")
      .order("created_at", { ascending: false });
    if (simpleError) throw simpleError;
    return simple;
  }
  return data;
}

export async function getClient(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("client_profiles")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw error;
  return data;
}

export async function getClientGardens(clientId: string) {
  const supabase = await createClient();
  const user = await getCurrentUser();

  let query = supabase
    .from("gardens")
    .select("*, garden_assignments(id, gardener_id, is_active, gardener_profiles(id, display_name))")
    .eq("client_id", clientId)
    .order("created_at", { ascending: false });

  // RLS handles company isolation; no explicit filter needed
  const { data, error } = await query;
  if (error) throw error;
  return data;
}

export async function getAllGardeners() {
  const supabase = await createClient();
  // RLS automatically filters to company scope for COMPANY_ADMIN
  const { data, error } = await supabase
    .from("gardener_profiles")
    .select("id, display_name")
    .order("display_name");

  if (error) throw error;
  return data;
}

export async function createClientUser(formData: FormData) {
  const email = formData.get("email") as string;
  const displayName = formData.get("name") as string;
  const phone = (formData.get("phone") as string) || null;
  const password = formData.get("password") as string;

  // Clients are global — no company_id
  const supabase = await createAdminClient();
  const { data: authData, error: authError } = await supabase.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
    user_metadata: { display_name: displayName, role: "CLIENT" },
  });

  if (authError) throw authError;

  // Ensure client_profile exists (trigger creates user_profiles; client_profile is separate)
  const { error: profileError } = await supabase
    .from("client_profiles")
    .insert({ user_id: authData.user.id, display_name: displayName, phone });

  if (profileError) throw profileError;

  revalidatePath("/dashboard/clients");
  redirect("/dashboard/clients");
}

export async function createGarden(clientId: string, formData: FormData) {
  const name = formData.get("name") as string;
  const address = formData.get("address") as string;
  const latStr = formData.get("latitude") as string;
  const lngStr = formData.get("longitude") as string;
  const gardenerId = formData.get("gardener_id") as string;

  const user = await getCurrentUser();
  if (!user?.companyId) throw new Error("No se puede crear un jardín sin empresa asignada.");

  const supabase = await createClient();
  const { data: garden, error } = await supabase.from("gardens").insert({
    client_id: clientId,
    company_id: user.companyId,
    name,
    address,
    latitude: latStr ? parseFloat(latStr) : null,
    longitude: lngStr ? parseFloat(lngStr) : null,
  }).select("id").single();

  if (error) throw error;

  if (gardenerId) {
    await supabase.from("garden_assignments").insert({
      garden_id: garden.id,
      gardener_id: gardenerId,
      is_active: true,
    });
  }

  revalidatePath(`/dashboard/clients/${clientId}`);
}

export async function updateGarden(gardenId: string, clientId: string, formData: FormData) {
  const name = formData.get("name") as string;
  const address = formData.get("address") as string;
  const latStr = formData.get("latitude") as string;
  const lngStr = formData.get("longitude") as string;
  const gardenerId = formData.get("gardener_id") as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from("gardens")
    .update({
      name,
      address,
      latitude: latStr ? parseFloat(latStr) : null,
      longitude: lngStr ? parseFloat(lngStr) : null,
    })
    .eq("id", gardenId);

  if (error) throw error;

  if (gardenerId) {
    await supabase
      .from("garden_assignments")
      .update({ is_active: false, valid_to: new Date().toISOString() })
      .eq("garden_id", gardenId)
      .eq("is_active", true);

    await supabase.from("garden_assignments").insert({
      garden_id: gardenId,
      gardener_id: gardenerId,
      is_active: true,
    });
  }

  revalidatePath(`/dashboard/clients/${clientId}`);
}

export async function deleteGarden(gardenId: string, clientId: string) {
  const supabase = await createClient();
  const { error } = await supabase.from("gardens").delete().eq("id", gardenId);

  if (error) throw error;

  revalidatePath(`/dashboard/clients/${clientId}`);
}

export async function updateClient(id: string, formData: FormData) {
  const displayName = formData.get("name") as string;
  const phone = formData.get("phone") as string;

  const supabase = await createClient();
  const { error } = await supabase
    .from("client_profiles")
    .update({ display_name: displayName, phone })
    .eq("id", id);

  if (error) throw error;

  revalidatePath("/dashboard/clients");
  redirect("/dashboard/clients");
}
