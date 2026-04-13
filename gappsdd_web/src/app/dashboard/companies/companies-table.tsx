"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Pencil } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/data-table";

type CompanyRow = {
  id: string;
  name: string;
  slug: string;
  is_active: boolean;
  created_at: string;
};

const columns: ColumnDef<CompanyRow>[] = [
  { accessorKey: "name", header: "Nombre" },
  {
    accessorKey: "slug",
    header: "Slug",
    cell: ({ row }) => (
      <span className="font-mono text-sm text-muted-foreground">
        {row.getValue("slug")}
      </span>
    ),
  },
  {
    accessorKey: "is_active",
    header: "Estado",
    cell: ({ row }) =>
      row.getValue("is_active") ? (
        <Badge variant="default">Activa</Badge>
      ) : (
        <Badge variant="secondary">Inactiva</Badge>
      ),
  },
  {
    accessorKey: "created_at",
    header: "Fecha de alta",
    cell: ({ row }) =>
      new Date(row.getValue("created_at") as string).toLocaleDateString("es-ES"),
  },
  {
    id: "actions",
    header: "",
    cell: ({ row }) => (
      <Link href={`/dashboard/companies/${row.original.id}`}>
        <Button variant="ghost" size="icon">
          <Pencil className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export function CompaniesTable({ companies }: { companies: CompanyRow[] }) {
  return (
    <DataTable
      columns={columns}
      data={companies}
      searchPlaceholder="Buscar empresas..."
    />
  );
}
