"use client";

import Image from "next/image";
import {
  Building2,
  LayoutDashboard,
  Users,
  Flower2,
  UserCircle,
  Settings,
  LogOut,
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  Sidebar,
  SidebarContent,
  SidebarFooter,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarHeader,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
} from "@/components/ui/sidebar";
import type { UserRole } from "@/types";

const superAdminItems = [
  { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { title: "Empresas", href: "/dashboard/companies", icon: Building2 },
  { title: "Usuarios", href: "/dashboard/users", icon: Users },
  { title: "Jardineros", href: "/dashboard/gardeners", icon: Flower2 },
  { title: "Clientes", href: "/dashboard/clients", icon: UserCircle },
];

const companyAdminItems = [
  { title: "Dashboard", href: "/dashboard", icon: LayoutDashboard },
  { title: "Jardineros", href: "/dashboard/gardeners", icon: Flower2 },
  { title: "Clientes", href: "/dashboard/clients", icon: UserCircle },
];

function getNavItems(role: UserRole | null) {
  if (role === "SUPER_ADMIN" || role === "ADMIN") return superAdminItems;
  if (role === "COMPANY_ADMIN") return companyAdminItems;
  return superAdminItems; // fallback
}

export function AppSidebar({ role }: { role: UserRole | null }) {
  const pathname = usePathname();
  const navItems = getNavItems(role);

  return (
    <Sidebar>
      <SidebarHeader className="border-b border-sidebar-border px-4 py-4">
        <Link href="/dashboard" className="flex items-center gap-3">
          <Image
            src="/logo_no_text.svg"
            alt="GAPP"
            width={36}
            height={36}
          />
          <div>
            <h2 className="font-heading text-base font-bold tracking-tight">
              GAPP
            </h2>
            <p className="text-xs text-muted-foreground">Admin Panel</p>
          </div>
        </Link>
      </SidebarHeader>

      <SidebarContent>
        <SidebarGroup>
          <SidebarGroupLabel>Gestión</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {navItems.map((item) => (
                <SidebarMenuItem key={item.href}>
                  <SidebarMenuButton
                    isActive={pathname === item.href}
                    render={<Link href={item.href} />}
                  >
                    <item.icon className="h-4 w-4" />
                    <span>{item.title}</span>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter className="border-t border-sidebar-border">
        <SidebarMenu>
          <SidebarMenuItem>
            <SidebarMenuButton render={<Link href="/dashboard/settings" />}>
              <Settings className="h-4 w-4" />
              <span>Configuración</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
          <SidebarMenuItem>
            <SidebarMenuButton render={<Link href="/" />}>
              <LogOut className="h-4 w-4" />
              <span>Cerrar Sesión</span>
            </SidebarMenuButton>
          </SidebarMenuItem>
        </SidebarMenu>
      </SidebarFooter>
    </Sidebar>
  );
}
