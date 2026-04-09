"use client";

import { useRef, useState } from "react";
import { Check, ChevronsUpDown, User } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { createGarden, updateGarden } from "../actions";

type GardenerRef = {
  id: string;
  display_name: string;
};

type Garden = {
  id: string;
  name: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
};

export function GardenDialog({
  open,
  onOpenChange,
  clientId,
  garden,
  gardeners,
  currentGardenerId,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  clientId: string;
  garden: Garden | null;
  gardeners: GardenerRef[];
  currentGardenerId: string | null;
}) {
  const formRef = useRef<HTMLFormElement>(null);
  const isEditing = garden !== null;
  const [selectedGardenerId, setSelectedGardenerId] = useState<string | null>(
    currentGardenerId
  );
  const [gardenerSearch, setGardenerSearch] = useState("");
  const [dropdownOpen, setDropdownOpen] = useState(false);

  // Reset state when dialog opens with different garden
  const prevGardenId = useRef<string | null>(null);
  if (garden?.id !== prevGardenId.current) {
    prevGardenId.current = garden?.id ?? null;
    // Can't call setState during render, but we track via ref and update will happen
  }

  const filteredGardeners = gardeners.filter((g) =>
    g.display_name.toLowerCase().includes(gardenerSearch.toLowerCase())
  );

  const selectedGardener = gardeners.find((g) => g.id === selectedGardenerId);

  async function handleSubmit(formData: FormData) {
    if (selectedGardenerId) {
      formData.set("gardener_id", selectedGardenerId);
    }
    if (isEditing) {
      await updateGarden(garden.id, clientId, formData);
    } else {
      await createGarden(clientId, formData);
    }
    onOpenChange(false);
    setSelectedGardenerId(null);
    setGardenerSearch("");
  }

  function handleOpenChange(newOpen: boolean) {
    if (newOpen) {
      setSelectedGardenerId(currentGardenerId);
      setGardenerSearch("");
      setDropdownOpen(false);
    }
    onOpenChange(newOpen);
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>
            {isEditing ? "Editar Jardín" : "Nuevo Jardín"}
          </DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Modifica los datos del jardín."
              : "Añade un nuevo jardín para este cliente."}
          </DialogDescription>
        </DialogHeader>

        <form ref={formRef} action={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="garden-name">Nombre *</Label>
            <Input
              id="garden-name"
              name="name"
              placeholder="Villa Hortensia"
              defaultValue={garden?.name ?? ""}
              required
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="garden-address">Dirección *</Label>
            <Input
              id="garden-address"
              name="address"
              placeholder="Calle de las Rosas 122, Madrid"
              defaultValue={garden?.address ?? ""}
              required
            />
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-2">
              <Label htmlFor="garden-lat">Latitud</Label>
              <Input
                id="garden-lat"
                name="latitude"
                type="number"
                step="any"
                placeholder="40.4168"
                defaultValue={garden?.latitude ?? ""}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="garden-lng">Longitud</Label>
              <Input
                id="garden-lng"
                name="longitude"
                type="number"
                step="any"
                placeholder="-3.7038"
                defaultValue={garden?.longitude ?? ""}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label>Jardinero asignado</Label>
            <div className="relative">
              <Button
                type="button"
                variant="outline"
                className="w-full justify-between font-normal"
                onClick={() => setDropdownOpen(!dropdownOpen)}
              >
                {selectedGardener ? (
                  <span className="flex items-center gap-2">
                    <User className="h-4 w-4 text-muted-foreground" />
                    {selectedGardener.display_name}
                  </span>
                ) : (
                  <span className="text-muted-foreground">
                    Seleccionar jardinero...
                  </span>
                )}
                <ChevronsUpDown className="h-4 w-4 text-muted-foreground" />
              </Button>

              {dropdownOpen && (
                <div className="absolute z-50 mt-1 w-full rounded-md border bg-popover shadow-md">
                  <div className="p-2">
                    <Input
                      placeholder="Buscar por nombre..."
                      value={gardenerSearch}
                      onChange={(e) => setGardenerSearch(e.target.value)}
                      autoFocus
                    />
                  </div>
                  <div className="max-h-48 overflow-y-auto px-1 pb-1">
                    <button
                      type="button"
                      className="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-sm hover:bg-accent"
                      onClick={() => {
                        setSelectedGardenerId(null);
                        setDropdownOpen(false);
                        setGardenerSearch("");
                      }}
                    >
                      <span className="w-4" />
                      <span className="text-muted-foreground italic">
                        Sin asignar
                      </span>
                    </button>
                    {filteredGardeners.map((g) => (
                      <button
                        key={g.id}
                        type="button"
                        className="flex w-full items-center gap-2 rounded-sm px-2 py-1.5 text-sm hover:bg-accent"
                        onClick={() => {
                          setSelectedGardenerId(g.id);
                          setDropdownOpen(false);
                          setGardenerSearch("");
                        }}
                      >
                        <span className="w-4">
                          {selectedGardenerId === g.id && (
                            <Check className="h-4 w-4 text-primary" />
                          )}
                        </span>
                        {g.display_name}
                      </button>
                    ))}
                    {filteredGardeners.length === 0 && (
                      <p className="px-2 py-3 text-center text-sm text-muted-foreground">
                        No se encontraron jardineros.
                      </p>
                    )}
                  </div>
                </div>
              )}
            </div>
          </div>

          <DialogFooter>
            <Button
              type="button"
              variant="outline"
              onClick={() => onOpenChange(false)}
            >
              Cancelar
            </Button>
            <Button type="submit">
              {isEditing ? "Guardar" : "Crear Jardín"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
