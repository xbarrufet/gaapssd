"use client";

import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Separator } from "@/components/ui/separator";
import { createCompany } from "../actions";

function slugify(value: string) {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-");
}

export default function NewCompanyPage() {
  function handleNameChange(e: React.ChangeEvent<HTMLInputElement>) {
    const slugInput = document.getElementById("slug") as HTMLInputElement | null;
    if (slugInput && !slugInput.dataset.edited) {
      slugInput.value = slugify(e.target.value);
    }
  }

  function handleSlugChange(e: React.ChangeEvent<HTMLInputElement>) {
    e.target.dataset.edited = "true";
    e.target.value = slugify(e.target.value);
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/dashboard/companies">
          <Button variant="ghost" size="icon">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </Link>
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Nueva Empresa
          </h1>
          <p className="text-muted-foreground">
            Crear una empresa y su administrador.
          </p>
        </div>
      </div>

      <form action={createCompany} className="space-y-6 max-w-2xl">
        <Card>
          <CardHeader>
            <CardTitle>Datos de la empresa</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Nombre de la empresa</Label>
              <Input
                id="name"
                name="name"
                placeholder="Jardinería El Bosque"
                required
                onChange={handleNameChange}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="slug">Slug (identificador único)</Label>
              <Input
                id="slug"
                name="slug"
                placeholder="jardineria-el-bosque"
                required
                pattern="[a-z0-9-]+"
                onChange={handleSlugChange}
              />
              <p className="text-xs text-muted-foreground">
                Solo letras minúsculas, números y guiones.
              </p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="logo_url">URL del logo (opcional)</Label>
              <Input
                id="logo_url"
                name="logo_url"
                type="url"
                placeholder="https://..."
              />
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Administrador de la empresa</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid gap-4 sm:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="admin_name">Nombre</Label>
                <Input
                  id="admin_name"
                  name="admin_name"
                  placeholder="Nombre completo"
                  required
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="admin_email">Email</Label>
                <Input
                  id="admin_email"
                  name="admin_email"
                  type="email"
                  placeholder="admin@empresa.es"
                  required
                />
              </div>
            </div>
            <div className="space-y-2">
              <Label htmlFor="admin_password">Contraseña temporal</Label>
              <Input
                id="admin_password"
                name="admin_password"
                type="password"
                placeholder="Mínimo 6 caracteres"
                required
                minLength={6}
              />
            </div>
          </CardContent>
        </Card>

        <div className="flex gap-3">
          <Button type="submit">Crear Empresa</Button>
          <Link href="/dashboard/companies">
            <Button variant="outline">Cancelar</Button>
          </Link>
        </div>
      </form>
    </div>
  );
}
