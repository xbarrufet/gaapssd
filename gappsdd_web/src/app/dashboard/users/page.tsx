import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Plus, Pencil } from "lucide-react";
import { redirect } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { getUsers } from "./actions";
import { UsersTable } from "./users-table";
import { getCurrentUser, isSuperAdmin } from "@/lib/auth";

const roleLabels: Record<string, string> = {
  SUPER_ADMIN: "Super Admin",
  COMPANY_ADMIN: "Admin Empresa",
  ADMIN: "Admin",
  GARDENER: "Jardinero",
  CLIENT: "Cliente",
  MANAGER: "Gestor",
};

const roleVariants: Record<string, "default" | "secondary" | "outline"> = {
  SUPER_ADMIN: "default",
  COMPANY_ADMIN: "default",
  ADMIN: "default",
  GARDENER: "secondary",
  CLIENT: "outline",
  MANAGER: "secondary",
};

export default async function UsersPage() {
  const user = await getCurrentUser();
  if (!isSuperAdmin(user)) redirect("/dashboard");

  const users = await getUsers();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Usuarios
          </h1>
          <p className="text-muted-foreground">
            Gestión de todos los usuarios de la plataforma.
          </p>
        </div>
        <Link href="/dashboard/users/new">
          <Button>
            <Plus className="mr-2 h-4 w-4" />
            Nuevo Usuario
          </Button>
        </Link>
      </div>
      <UsersTable users={users} />
    </div>
  );
}
