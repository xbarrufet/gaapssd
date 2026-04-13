"use server";

import { createClient } from "@/lib/supabase/server";

export async function getVisits() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("visits")
    .select("*, gardener_profiles(id, display_name), gardens(id, name, address)")
    .order("started_at", { ascending: false });

  if (error) throw error;
  return data ?? [];
}

export async function getVisit(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("visits")
    .select("*, gardener_profiles(id, display_name), gardens(id, name, address)")
    .eq("id", id)
    .single();

  if (error) throw error;
  return data;
}

export async function getVisitPhotos(visitId: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("visit_photos")
    .select("*")
    .eq("visit_id", visitId)
    .order("created_at", { ascending: true });

  if (error) throw error;
  return data ?? [];
}
