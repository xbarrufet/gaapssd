import Link from "next/link";
import { ArrowLeft } from "lucide-react";
import { notFound } from "next/navigation";
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
import { getCompany, updateCompany } from "../actions";
import { getCurrentUser, isSuperAdmin } from "@/lib/auth";
import { redirect } from "next/navigation";

export default async function EditCompanyPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const user = await getCurrentUser();
  if (!isSuperAdmin(user)) redirect("/dashboard");

  const { id } = await params;
  const company = await getCompany(id).catch(() => null);

  if (!company) notFound();

  const updateCompanyWithId = updateCompany.bind(null, id);

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
            {company.name}
          </h1>
          <p className="text-muted-foreground">Editar datos de la empresa.</p>
        </div>
      </div>

      <Card className="max-w-2xl">
        <CardHeader>
          <CardTitle>Datos de la empresa</CardTitle>
        </CardHeader>
        <CardContent>
          <form action={updateCompanyWithId} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="name">Nombre</Label>
              <Input
                id="name"
                name="name"
                defaultValue={company.name}
                required
              />
            </div>
            <div className="space-y-2">
              <Label>Slug</Label>
              <Input value={company.slug} disabled className="font-mono" />
              <p className="text-xs text-muted-foreground">
                El slug no se puede modificar.
              </p>
            </div>
            <div className="space-y-2">
              <Label htmlFor="logo_url">URL del logo</Label>
              <Input
                id="logo_url"
                name="logo_url"
                type="url"
                defaultValue={company.logo_url ?? ""}
                placeholder="https://..."
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="is_active">Estado</Label>
              <Select
                name="is_active"
                defaultValue={company.is_active ? "true" : "false"}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="true">Activa</SelectItem>
                  <SelectItem value="false">Inactiva</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex gap-3 pt-4">
              <Button type="submit">Guardar cambios</Button>
              <Link href="/dashboard/companies">
                <Button variant="outline">Cancelar</Button>
              </Link>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
