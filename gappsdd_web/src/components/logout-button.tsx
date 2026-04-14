"use client";

import { LogOut } from "lucide-react";
import { SidebarMenuButton } from "@/components/ui/sidebar";
import { signOut } from "@/app/auth/actions";

export function LogoutButton() {
  return (
    <form action={signOut}>
      <SidebarMenuButton type="submit">
        <LogOut className="h-4 w-4" />
        <span>Cerrar Sesión</span>
      </SidebarMenuButton>
    </form>
  );
}
