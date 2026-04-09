"use client";

import { useState } from "react";
import { Flower2, MapPin, Plus, Pencil, Trash2, User } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { GardenDialog } from "./garden-dialog";
import { deleteGarden } from "../actions";

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
  created_at: string;
  garden_assignments?: GardenAssignment[];
};

function getActiveGardener(garden: Garden): GardenerRef | null {
  const active = garden.garden_assignments?.find((a) => a.is_active);
  return active?.gardener_profiles ?? null;
}

export function GardensList({
  clientId,
  gardens,
  gardeners,
}: {
  clientId: string;
  gardens: Garden[];
  gardeners: GardenerRef[];
}) {
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingGarden, setEditingGarden] = useState<Garden | null>(null);

  function handleAdd() {
    setEditingGarden(null);
    setDialogOpen(true);
  }

  function handleEdit(garden: Garden) {
    setEditingGarden(garden);
    setDialogOpen(true);
  }

  async function handleDelete(gardenId: string) {
    if (!confirm("¿Eliminar este jardín? Esta acción no se puede deshacer.")) return;
    await deleteGarden(gardenId, clientId);
  }

  return (
    <>
      <Card>
        <CardHeader className="flex flex-row items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Flower2 className="h-5 w-5" />
            Jardines ({gardens.length})
          </CardTitle>
          <Button size="sm" onClick={handleAdd}>
            <Plus className="mr-2 h-4 w-4" />
            Añadir Jardín
          </Button>
        </CardHeader>
        <CardContent>
          {gardens.length === 0 ? (
            <p className="text-sm text-muted-foreground py-4 text-center">
              Este cliente no tiene jardines registrados.
            </p>
          ) : (
            <div className="space-y-3">
              {gardens.map((garden) => {
                const gardener = getActiveGardener(garden);
                return (
                  <div
                    key={garden.id}
                    className="flex items-start justify-between rounded-lg border p-4"
                  >
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
                      <p className="text-sm text-muted-foreground">
                        {garden.address}
                      </p>
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
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleEdit(garden)}
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        onClick={() => handleDelete(garden.id)}
                      >
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </CardContent>
      </Card>

      <GardenDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        clientId={clientId}
        garden={editingGarden}
        gardeners={gardeners}
        currentGardenerId={editingGarden ? getActiveGardener(editingGarden)?.id ?? null : null}
      />
    </>
  );
}
