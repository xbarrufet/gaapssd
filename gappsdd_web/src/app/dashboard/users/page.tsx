import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Plus, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { getUsers } from "./actions";
import { UsersTable } from "./users-table";

const roleLabels: Record<string, string> = {
  ADMIN: "Admin",
  GARDENER: "Jardinero",
  CLIENT: "Cliente",
  MANAGER: "Gestor",
};

const roleVariants: Record<string, "default" | "secondary" | "outline"> = {
  ADMIN: "default",
  GARDENER: "secondary",
  CLIENT: "outline",
  MANAGER: "secondary",
};

export default async function UsersPage() {
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
