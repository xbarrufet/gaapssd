"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/data-table";

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

type UserProfile = {
  id: string;
  display_name: string;
  role: string;
  phone: string | null;
  is_active: boolean;
  created_at: string;
};

const columns: ColumnDef<UserProfile>[] = [
  { accessorKey: "display_name", header: "Nombre" },
  {
    accessorKey: "role",
    header: "Rol",
    cell: ({ row }) => {
      const role = row.getValue("role") as string;
      return (
        <Badge variant={roleVariants[role] ?? "outline"}>
          {roleLabels[role] ?? role}
        </Badge>
      );
    },
  },
  { accessorKey: "phone", header: "Teléfono" },
  {
    accessorKey: "created_at",
    header: "Fecha de alta",
    cell: ({ row }) => {
      const date = new Date(row.getValue("created_at") as string);
      return date.toLocaleDateString("es-ES");
    },
  },
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

export function UsersTable({ users }: { users: UserProfile[] }) {
  return (
    <DataTable
      columns={columns}
      data={users}
      searchPlaceholder="Buscar usuarios..."
    />
  );
}
