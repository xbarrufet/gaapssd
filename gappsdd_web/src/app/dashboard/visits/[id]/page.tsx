import Link from "next/link";
import Image from "next/image";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { createClient } from "@/lib/supabase/server";
import { getVisit, getVisitPhotos } from "../actions";

function formatDateTime(iso: string): string {
  return new Date(iso).toLocaleString("es-ES", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function formatDuration(startedAt: string, endedAt: string | null): string {
  if (!endedAt) return "En curso";
  const diffMs = new Date(endedAt).getTime() - new Date(startedAt).getTime();
  const minutes = Math.floor(diffMs / 60000);
  if (minutes < 60) return `${minutes} min`;
  const hours = Math.floor(minutes / 60);
  const remaining = minutes % 60;
  return remaining > 0 ? `${hours}h ${remaining}min` : `${hours}h`;
}

export default async function VisitDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const [visit, photos] = await Promise.all([getVisit(id), getVisitPhotos(id)]);

  if (!visit) {
    return <p className="p-6 text-muted-foreground">Visita no encontrada.</p>;
  }

  const supabase = await createClient();
  const photoUrls = photos.map((p) => ({
    url: supabase.storage.from("visit-photos").getPublicUrl(p.storage_path)
      .data.publicUrl,
    label: p.label,
    id: p.id,
  }));

  const hasObservations =
    visit.title || visit.description || visit.public_comment;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/visits">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div className="flex-1">
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            {visit.title || "Visita sin título"}
          </h1>
          <p className="text-muted-foreground">
            {visit.gardens?.name ?? "Jardín desconocido"}
          </p>
        </div>
        <div className="flex items-center gap-2">
          {visit.status === "ACTIVE" ? (
            <Badge className="bg-green-600 text-white">Activa</Badge>
          ) : (
            <Badge variant="secondary">Cerrada</Badge>
          )}
          {visit.verification_status === "VERIFIED" ? (
            <Badge variant="outline" className="border-green-600 text-green-700">
              Verificada
            </Badge>
          ) : (
            <Badge variant="outline" className="text-muted-foreground">
              No verificada
            </Badge>
          )}
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Detalles</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3 text-sm sm:grid-cols-2">
          <div>
            <p className="text-muted-foreground">Jardinero</p>
            <p className="font-medium">
              {visit.gardener_profiles?.display_name ?? "—"}
            </p>
          </div>
          <div>
            <p className="text-muted-foreground">Jardín</p>
            <p className="font-medium">{visit.gardens?.name ?? "—"}</p>
          </div>
          <div>
            <p className="text-muted-foreground">Dirección</p>
            <p className="font-medium">{visit.gardens?.address ?? "—"}</p>
          </div>
          <div>
            <p className="text-muted-foreground">Método de inicio</p>
            <p className="font-medium">
              {visit.initiation_method === "QR_SCAN" ? "Escaneo QR" : "Manual"}
            </p>
          </div>
          <div>
            <p className="text-muted-foreground">Inicio</p>
            <p className="font-medium">{formatDateTime(visit.started_at)}</p>
          </div>
          <div>
            <p className="text-muted-foreground">Fin</p>
            <p className="font-medium">
              {visit.ended_at ? formatDateTime(visit.ended_at) : "—"}
            </p>
          </div>
          <div>
            <p className="text-muted-foreground">Duración</p>
            <p className="font-medium">
              {formatDuration(visit.started_at, visit.ended_at)}
            </p>
          </div>
        </CardContent>
      </Card>

      {hasObservations && (
        <Card className="max-w-2xl">
          <CardHeader>
            <CardTitle>Observaciones</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            {visit.description && (
              <div>
                <p className="text-muted-foreground">Descripción</p>
                <p className="whitespace-pre-wrap">{visit.description}</p>
              </div>
            )}
            {visit.public_comment && (
              <div>
                <p className="text-muted-foreground">Comentario para el cliente</p>
                <p className="whitespace-pre-wrap">{visit.public_comment}</p>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {photoUrls.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>Fotografías ({photoUrls.length})</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
              {photoUrls.map((photo) => (
                <div key={photo.id} className="space-y-1">
                  <div className="relative aspect-square overflow-hidden rounded-lg border">
                    <Image
                      src={photo.url}
                      alt={photo.label || "Fotografía de visita"}
                      fill
                      className="object-cover"
                      sizes="(max-width: 640px) 50vw, (max-width: 1024px) 33vw, 25vw"
                    />
                  </div>
                  {photo.label && (
                    <p className="text-center text-xs text-muted-foreground">
                      {photo.label}
                    </p>
                  )}
                </div>
              ))}
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
