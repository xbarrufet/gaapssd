"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { DataTable } from "@/components/data-table";

type ClientProfile = {
  id: string;
  display_name: string;
  phone: string | null;
  created_at: string;
  gardens?: { count: number }[];
};

const columns: ColumnDef<ClientProfile>[] = [
  { accessorKey: "display_name", header: "Nombre" },
  { accessorKey: "phone", header: "Teléfono" },
  {
    id: "garden_count",
    header: "Jardines",
    cell: ({ row }) => {
      const gardens = row.original.gardens;
      const count = gardens?.[0]?.count ?? 0;
      return count;
    },
  },
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
      <Link href={`/dashboard/clients/${row.original.id}`}>
        <Button variant="ghost" size="icon">
          <Pencil className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

export function ClientsTable({ clients }: { clients: ClientProfile[] }) {
  return (
    <DataTable
      columns={columns}
      data={clients}
      searchPlaceholder="Buscar clientes..."
    />
  );
}
