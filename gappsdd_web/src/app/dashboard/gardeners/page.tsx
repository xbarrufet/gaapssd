"use client";

import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Plus, Pencil } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DataTable } from "@/components/data-table";
import { sampleGardeners } from "@/lib/sample-data";
import type { Gardener } from "@/types";

const columns: ColumnDef<Gardener>[] = [
  { accessorKey: "name", header: "Nombre" },
  { accessorKey: "email", header: "Email" },
  { accessorKey: "phone", header: "Teléfono" },
  { accessorKey: "assignedGardens", header: "Jardines" },
  {
    accessorKey: "status",
    header: "Estado",
    cell: ({ row }) => {
      const status = row.getValue("status") as string;
      return (
        <Badge variant={status === "active" ? "default" : "secondary"}>
          {status === "active" ? "Activo" : "Inactivo"}
        </Badge>
      );
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

export default function GardenersPage() {
  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Jardineros
          </h1>
          <p className="text-muted-foreground">
            Gestión de jardineros y sus asignaciones.
          </p>
        </div>
        <Link href="/dashboard/gardeners/new">
          <Button>
            <Plus className="mr-2 h-4 w-4" />
            Nuevo Jardinero
          </Button>
        </Link>
      </div>
      <DataTable
        columns={columns}
        data={sampleGardeners}
        searchPlaceholder="Buscar jardineros..."
      />
    </div>
  );
}
