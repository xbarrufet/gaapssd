"use client";

import { Fragment, useState } from "react";
import {
  type ColumnDef,
  flexRender,
  getCoreRowModel,
  getFilteredRowModel,
  getExpandedRowModel,
  useReactTable,
} from "@tanstack/react-table";
import Link from "next/link";
import { ChevronRight, MapPin, Pencil, Trash2, User } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { deleteGarden } from "./actions";

type GardenerRef = {
  id: string;
  display_name: string;
};

type GardenAssignment = {
  id: string;
  gardener_id: string;
  is_active: boolean;
  gardener_profiles: GardenerRef;
};

type Garden = {
  id: string;
  name: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
  garden_assignments?: GardenAssignment[];
};

type ClientProfile = {
  id: string;
  display_name: string;
  phone: string | null;
  created_at: string;
  gardens?: Garden[];
};

function getActiveGardener(garden: Garden): GardenerRef | null {
  const active = garden.garden_assignments?.find((a) => a.is_active);
  return active?.gardener_profiles ?? null;
}

const columns: ColumnDef<ClientProfile>[] = [
  {
    id: "expand",
    header: "",
    cell: ({ row }) => {
      const gardenCount = row.original.gardens?.length ?? 0;
      if (gardenCount === 0) return null;
      return (
        <Button
          variant="ghost"
          size="icon"
          className="h-6 w-6"
          onClick={() => row.toggleExpanded()}
        >
          <ChevronRight
            className={`h-4 w-4 transition-transform ${
              row.getIsExpanded() ? "rotate-90" : ""
            }`}
          />
        </Button>
      );
    },
  },
  { accessorKey: "display_name", header: "Nombre" },
  { accessorKey: "phone", header: "Teléfono" },
  {
    id: "garden_count",
    header: "Jardines",
    cell: ({ row }) => row.original.gardens?.length ?? 0,
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

function GardenRow({ garden, clientId }: { garden: Garden; clientId: string }) {
  const gardener = getActiveGardener(garden);

  async function handleDelete() {
    if (!confirm("¿Eliminar este jardín? Esta acción no se puede deshacer.")) return;
    await deleteGarden(garden.id, clientId);
  }

  return (
    <div className="flex items-start justify-between rounded-lg border p-4">
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <span className="font-medium">{garden.name}</span>
          {garden.latitude != null && (
            <Badge variant="outline" className="text-xs">
              <MapPin className="mr-1 h-3 w-3" />
              GPS
            </Badge>
          )}
        </div>
        <p className="text-sm text-muted-foreground">{garden.address}</p>
        {gardener ? (
          <p className="text-sm flex items-center gap-1 text-primary">
            <User className="h-3 w-3" />
            {gardener.display_name}
          </p>
        ) : (
          <p className="text-xs text-muted-foreground italic">
            Sin jardinero asignado
          </p>
        )}
      </div>
      <div className="flex gap-1">
        <Link href={`/dashboard/clients/${clientId}`}>
          <Button variant="ghost" size="icon">
            <Pencil className="h-4 w-4" />
          </Button>
        </Link>
        <Button variant="ghost" size="icon" onClick={handleDelete}>
          <Trash2 className="h-4 w-4 text-destructive" />
        </Button>
      </div>
    </div>
  );
}

export function ClientsTable({ clients }: { clients: ClientProfile[] }) {
  const [globalFilter, setGlobalFilter] = useState("");

  const table = useReactTable({
    data: clients,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getFilteredRowModel: getFilteredRowModel(),
    getExpandedRowModel: getExpandedRowModel(),
    state: { globalFilter },
    onGlobalFilterChange: setGlobalFilter,
  });

  return (
    <div className="space-y-4">
      <Input
        placeholder="Buscar clientes..."
        value={globalFilter}
        onChange={(e) => setGlobalFilter(e.target.value)}
        className="max-w-sm"
      />
      <div className="rounded-lg border">
        <Table>
          <TableHeader>
            {table.getHeaderGroups().map((headerGroup) => (
              <TableRow key={headerGroup.id}>
                {headerGroup.headers.map((header) => (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                ))}
              </TableRow>
            ))}
          </TableHeader>
          <TableBody>
            {table.getRowModel().rows?.length ? (
              table.getRowModel().rows.map((row) => (
                <Fragment key={row.id}>
                  <TableRow>
                    {row.getVisibleCells().map((cell) => (
                      <TableCell key={cell.id}>
                        {flexRender(
                          cell.column.columnDef.cell,
                          cell.getContext()
                        )}
                      </TableCell>
                    ))}
                  </TableRow>
                  {row.getIsExpanded() && (
                    <TableRow
                      key={`${row.id}-gardens`}
                      className="bg-muted/30 hover:bg-muted/30"
                    >
                      <TableCell colSpan={columns.length} className="p-0">
                        <div className="px-10 py-4 space-y-3">
                          {row.original.gardens?.map((garden) => (
                            <GardenRow
                              key={garden.id}
                              garden={garden}
                              clientId={row.original.id}
                            />
                          ))}
                        </div>
                      </TableCell>
                    </TableRow>
                  )}
                </Fragment>
              ))
            ) : (
              <TableRow>
                <TableCell
                  colSpan={columns.length}
                  className="h-24 text-center"
                >
                  No se encontraron resultados.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  );
}
