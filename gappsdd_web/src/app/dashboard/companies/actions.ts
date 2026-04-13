"use server";

import { createClient, createAdminClient } from "@/lib/supabase/server";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

export async function getCompanies() {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("companies")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) throw error;
  return data;
}

export async function getCompany(id: string) {
  const supabase = await createClient();
  const { data, error } = await supabase
    .from("companies")
    .select("*")
    .eq("id", id)
    .single();

  if (error) throw error;
  return data;
}

export async function createCompany(formData: FormData) {
  const name = formData.get("name") as string;
  const slug = formData.get("slug") as string;
  const logoUrl = (formData.get("logo_url") as string) || null;

  const adminEmail = formData.get("admin_email") as string;
  const adminName = formData.get("admin_name") as string;
  const adminPassword = formData.get("admin_password") as string;

  const supabase = await createAdminClient();

  // 1. Create the company
  const { data: company, error: companyError } = await supabase
    .from("companies")
    .insert({ name, slug, logo_url: logoUrl })
    .select("id")
    .single();

  if (companyError) throw companyError;

  // 2. Create the company-admin user — trigger sets profile with company_id
  const { error: authError } = await supabase.auth.admin.createUser({
    email: adminEmail,
    password: adminPassword,
    email_confirm: true,
    user_metadata: {
      display_name: adminName,
      role: "COMPANY_ADMIN",
      company_id: company.id,
    },
  });

  if (authError) {
    // Roll back company creation
    await supabase.from("companies").delete().eq("id", company.id);
    throw authError;
  }

  revalidatePath("/dashboard/companies");
  redirect("/dashboard/companies");
}

export async function updateCompany(id: string, formData: FormData) {
  const name = formData.get("name") as string;
  const logoUrl = (formData.get("logo_url") as string) || null;
  const isActive = formData.get("is_active") === "true";

  const supabase = await createClient();
  const { error } = await supabase
    .from("companies")
    .update({ name, logo_url: logoUrl, is_active: isActive })
    .eq("id", id);

  if (error) throw error;

  revalidatePath("/dashboard/companies");
  redirect("/dashboard/companies");
}
