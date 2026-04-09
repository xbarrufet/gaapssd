"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Plus, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/data-table";
import { sampleUsers } from "@/lib/sample-data";
import type { User } from "@/types";

const roleLabels: Record<User["role"], string> = {
  admin: "Admin",
  gardener: "Jardinero",
  client: "Cliente",
};

const roleVariants: Record<User["role"], "default" | "secondary" | "outline"> =
  {
    admin: "default",
    gardener: "secondary",
    client: "outline",
  };

const columns: ColumnDef<User>[] = [
  { accessorKey: "name", header: "Nombre" },
  { accessorKey: "email", header: "Email" },
  {
    accessorKey: "role",
    header: "Rol",
    cell: ({ row }) => {
      const role = row.getValue("role") as User["role"];
      return <Badge variant={roleVariants[role]}>{roleLabels[role]}</Badge>;
    },
  },
  { accessorKey: "createdAt", header: "Fecha de alta" },
  {
    id: "actions",
    header: "",
    cell: ({ row }) => (
      <Link href={`/dashboard/users/${row.original.id}`}>
        <Button variant="ghost" size="icon">
          <Pencil className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export default function UsersPage() {
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
      <DataTable
        columns={columns}
        data={sampleUsers}
        searchPlaceholder="Buscar usuarios..."
      />
    </div>
  );
}
