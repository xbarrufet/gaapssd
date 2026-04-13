import Link from "next/link";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getCompanies } from "./actions";
import { CompaniesTable } from "./companies-table";
import { getCurrentUser, isSuperAdmin } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function CompaniesPage() {
  const user = await getCurrentUser();
  if (!isSuperAdmin(user)) redirect("/dashboard");

  const companies = await getCompanies();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Empresas
          </h1>
          <p className="text-muted-foreground">
            Gestión de empresas de jardinería en la plataforma.
          </p>
        </div>
        <Link href="/dashboard/companies/new">
          <Button>
            <Plus className="mr-2 h-4 w-4" />
            Nueva Empresa
          </Button>
        </Link>
      </div>
      <CompaniesTable companies={companies} />
    </div>
  );
}
