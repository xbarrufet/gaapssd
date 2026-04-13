import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Flower2, UserCircle, CalendarCheck } from "lucide-react";
import { createClient } from "@/lib/supabase/server";
import { getCurrentUser, isSuperAdmin } from "@/lib/auth";

async function getStats(companyId: string | null, superAdmin: boolean) {
  const supabase = await createClient();

  if (superAdmin) {
    const [users, gardeners, clients, visits] = await Promise.all([
      supabase.from("user_profiles").select("*", { count: "exact", head: true }),
      supabase.from("gardener_profiles").select("*", { count: "exact", head: true }),
      supabase.from("client_profiles").select("*", { count: "exact", head: true }),
      supabase.from("visits").select("*", { count: "exact", head: true }),
    ]);

    return [
      { title: "Usuarios", value: String(users.count ?? 0), icon: Users, description: "Total plataforma" },
      { title: "Jardineros", value: String(gardeners.count ?? 0), icon: Flower2, description: "Total plataforma" },
      { title: "Clientes", value: String(clients.count ?? 0), icon: UserCircle, description: "Total plataforma" },
      { title: "Visitas", value: String(visits.count ?? 0), icon: CalendarCheck, description: "Total" },
    ];
  }

  // Company-admin: filter by company via RLS (server will enforce it automatically)
  const [gardeners, visits] = await Promise.all([
    supabase
      .from("user_profiles")
      .select("*", { count: "exact", head: true })
      .eq("role", "GARDENER"),
    supabase
      .from("visits")
      .select("*", { count: "exact", head: true }),
  ]);

  return [
    { title: "Jardineros", value: String(gardeners.count ?? 0), icon: Flower2, description: "Tu empresa" },
    { title: "Visitas", value: String(visits.count ?? 0), icon: CalendarCheck, description: "Tu empresa" },
  ];
}

export default async function DashboardPage() {
  const user = await getCurrentUser();
  const superAdmin = isSuperAdmin(user);
  const stats = await getStats(user?.companyId ?? null, superAdmin);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-heading text-2xl font-bold tracking-tight">
          Dashboard
        </h1>
        <p className="text-muted-foreground">
          {superAdmin
            ? "Resumen general de la plataforma GAPP."
            : "Resumen de tu empresa."}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between pb-2">
              <CardTitle className="text-sm font-medium">
                {stat.title}
              </CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">
                {stat.description}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
