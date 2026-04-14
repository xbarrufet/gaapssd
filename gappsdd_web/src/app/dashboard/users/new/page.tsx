"use client";

import Link from "next/link";
import { useSearchParams } from "next/navigation";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { createUser } from "../actions";

const roleMeta: Record<string, { label: string; title: string; description: string }> = {
  gardener: {
    label: "Jardinero",
    title: "Nuevo Jardinero",
    description: "Crear un nuevo jardinero en la plataforma.",
  },
  client: {
    label: "Cliente",
    title: "Nuevo Cliente",
    description: "Crear un nuevo cliente en la plataforma.",
  },
};

const sectionBack: Record<string, string> = {
  gardeners: "/dashboard/gardeners",
  clients: "/dashboard/clients",
  users: "/dashboard/users",
};

export default function NewUserPage() {
  const searchParams = useSearchParams();
  const role = searchParams.get("role") ?? "";
  const from = searchParams.get("from") ?? "users";

  const meta = roleMeta[role];
  const backHref = sectionBack[from] ?? "/dashboard/users";

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href={backHref}>
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            {meta?.title ?? "Nuevo Usuario"}
          </h1>
          <p className="text-muted-foreground">
            {meta?.description ?? "Crear un nuevo usuario en la plataforma."}
          </p>
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Datos del usuario</CardTitle>
        </CardHeader>
        <CardContent>
          <form action={createUser} className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Nombre</Label>
                <Input id="name" name="name" placeholder="Nombre completo" required />
              </div>
              <div className="space-y-2">
                <Label htmlFor="email">Email</Label>
                <Input
                  id="email"
                  name="email"
                  type="email"
                  placeholder="correo@ejemplo.es"
                  required
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">Contraseña</Label>
              <Input
                id="password"
                name="password"
                type="password"
                placeholder="Mínimo 6 caracteres"
                required
                minLength={6}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="role">Rol</Label>
              <Select name="role" defaultValue={role || undefined} required>
                <SelectTrigger>
                  <SelectValue placeholder="Seleccionar rol" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="admin">Administrador</SelectItem>
                  <SelectItem value="gardener">Jardinero</SelectItem>
                  <SelectItem value="client">Cliente</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex gap-3 pt-4">
              <Button type="submit">
                {meta ? `Crear ${meta.label}` : "Crear Usuario"}
              </Button>
              <Link href={backHref}>
                <Button variant="outline">Cancelar</Button>
              </Link>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
