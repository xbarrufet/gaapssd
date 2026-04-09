"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/data-table";

type GardenerProfile = {
  id: string;
  display_name: string;
  phone: string | null;
  created_at: string;
};

const columns: ColumnDef<GardenerProfile>[] = [
  { accessorKey: "display_name", header: "Nombre" },
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
      <Link href={`/dashboard/gardeners/${row.original.id}`}>
        <Button variant="ghost" size="icon">
          <Pencil className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export function GardenersTable({ gardeners }: { gardeners: GardenerProfile[] }) {
  return (
    <DataTable
      columns={columns}
      data={gardeners}
      searchPlaceholder="Buscar jardineros..."
    />
  );
}
