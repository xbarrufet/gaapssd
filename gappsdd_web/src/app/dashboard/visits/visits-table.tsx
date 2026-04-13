"use client";

import { useState } from "react";
import { type ColumnDef } from "@tanstack/react-table";
import Link from "next/link";
import { Eye } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { DataTable } from "@/components/data-table";
import type { Visit } from "@/types";

function formatDuration(startedAt: string, endedAt: string | null): string {
  if (!endedAt) return "En curso";
  const diffMs = new Date(endedAt).getTime() - new Date(startedAt).getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  return remaining > 0 ? `${hours}h ${remaining}min` : `${hours}h`;
}

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

const columns: ColumnDef<Visit>[] = [
  {
    id: "gardener",
    header: "Jardinero",
    accessorFn: (row) => row.gardener_profiles?.display_name ?? "—",
  },
  {
    id: "garden",
    header: "Jardín",
    accessorFn: (row) => row.gardens?.name ?? "—",
  },
  {
    id: "status",
    header: "Estado",
    cell: ({ row }) =>
      row.original.status === "ACTIVE" ? (
        <Badge variant="default" className="bg-green-600 text-white">
          Activa
        </Badge>
      ) : (
        <Badge variant="secondary">Cerrada</Badge>
      ),
  },
  {
    id: "verification_status",
    header: "Verificación",
    cell: ({ row }) =>
      row.original.verification_status === "VERIFIED" ? (
        <Badge variant="outline" className="border-green-600 text-green-700">
          Verificada
        </Badge>
      ) : (
        <Badge variant="outline" className="text-muted-foreground">
          No verificada
        </Badge>
      ),
  },
  {
    id: "initiation_method",
    header: "Método",
    cell: ({ row }) =>
      row.original.initiation_method === "QR_SCAN" ? "QR" : "Manual",
  },
  {
    id: "started_at",
    header: "Inicio",
    accessorFn: (row) => formatDateTime(row.started_at),
  },
  {
    id: "duration",
    header: "Duración",
    cell: ({ row }) =>
      formatDuration(row.original.started_at, row.original.ended_at),
  },
  {
    id: "actions",
    header: "",
    cell: ({ row }) => (
      <Link href={`/dashboard/visits/${row.original.id}`}>
        <Button variant="ghost" size="icon">
          <Eye className="h-4 w-4" />
        </Button>
      </Link>
    ),
  },
];

type StatusFilter = "all" | "ACTIVE" | "CLOSED";

export function VisitsTable({ visits }: { visits: Visit[] }) {
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");

  const filtered =
    statusFilter === "all"
      ? visits
      : visits.filter((v) => v.status === statusFilter);

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <Select
          value={statusFilter}
          onValueChange={(v) => setStatusFilter(v as StatusFilter)}
        >
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Estado" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="all">Todas</SelectItem>
            <SelectItem value="ACTIVE">Activas</SelectItem>
            <SelectItem value="CLOSED">Cerradas</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <DataTable
        columns={columns}
        data={filtered}
        searchPlaceholder="Buscar por jardinero o jardín..."
      />
    </div>
  );
}
