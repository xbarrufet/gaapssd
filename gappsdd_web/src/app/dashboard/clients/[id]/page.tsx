import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { getClient, updateClient, getClientGardens, getAllGardeners } from "../actions";
import { GardensList } from "./gardens-list";

export default async function EditClientPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const [client, gardens, gardeners] = await Promise.all([
    getClient(id),
    getClientGardens(id),
    getAllGardeners(),
  ]);

  if (!client) {
    return <p className="p-6 text-muted-foreground">Cliente no encontrado.</p>;
  }

  const updateWithId = updateClient.bind(null, id);

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/clients">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Editar Cliente
          </h1>
          <p className="text-muted-foreground">{client.display_name}</p>
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Datos del cliente</CardTitle>
        </CardHeader>
        <CardContent>
          <form action={updateWithId} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Nombre</Label>
                <Input id="name" name="name" defaultValue={client.display_name} required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="phone">Teléfono</Label>
                <Input id="phone" name="phone" type="tel" defaultValue={client.phone ?? ""} />
              </div>
            </div>
            <div className="flex gap-3 pt-4">
              <Button type="submit">Guardar Cambios</Button>
              <Link href="/dashboard/clients">
                <Button variant="outline">Cancelar</Button>
              </Link>
            </div>
          </form>
        </CardContent>
      </Card>

      <GardensList clientId={id} gardens={gardens} gardeners={gardeners} />
    </div>
  );
}
