"use client";

import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

type UserProfile = {
  id: string;
  display_name: string;
  role: string;
  phone: string | null;
};

export function EditUserForm({
  user,
  action,
}: {
  user: UserProfile;
  action: (formData: FormData) => Promise<void>;
}) {
  return (
    <form action={action} className="space-y-4">
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="space-y-2">
          <Label htmlFor="name">Nombre</Label>
          <Input id="name" name="name" defaultValue={user.display_name} required />
        </div>
        <div className="space-y-2">
          <Label htmlFor="phone">Teléfono</Label>
          <Input id="phone" name="phone" defaultValue={user.phone ?? ""} />
        </div>
      </div>
      <div className="space-y-2">
        <Label htmlFor="role">Rol</Label>
        <Select name="role" defaultValue={user.role.toLowerCase()}>
          <SelectTrigger>
            <SelectValue />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="admin">Administrador</SelectItem>
            <SelectItem value="gardener">Jardinero</SelectItem>
            <SelectItem value="client">Cliente</SelectItem>
          </SelectContent>
        </Select>
      </div>
      <div className="flex gap-3 pt-4">
        <Button type="submit">Guardar Cambios</Button>
        <Link href="/dashboard/users">
          <Button variant="outline">Cancelar</Button>
        </Link>
      </div>
    </form>
  );
}
