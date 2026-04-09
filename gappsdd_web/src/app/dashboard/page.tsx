import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Flower2, UserCircle, CalendarCheck } from "lucide-react";
import { createClient } from "@/lib/supabase/server";

async function getStats() {
  const supabase = await createClient();

  const [users, gardeners, clients, visits] = await Promise.all([
    supabase.from("user_profiles").select("*", { count: "exact", head: true }),
    supabase.from("gardener_profiles").select("*", { count: "exact", head: true }),
    supabase.from("client_profiles").select("*", { count: "exact", head: true }),
    supabase.from("visits").select("*", { count: "exact", head: true }),
  ]);

  return [
    { title: "Usuarios", value: String(users.count ?? 0), icon: Users, description: "Registrados" },
    { title: "Jardineros", value: String(gardeners.count ?? 0), icon: Flower2, description: "Registrados" },
    { title: "Clientes", value: String(clients.count ?? 0), icon: UserCircle, description: "Registrados" },
    { title: "Visitas", value: String(visits.count ?? 0), icon: CalendarCheck, description: "Total" },
  ];
}

export default async function DashboardPage() {
  const stats = await getStats();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-heading text-2xl font-bold tracking-tight">
          Dashboard
        </h1>
        <p className="text-muted-foreground">
          Resumen general de la plataforma GAPP.
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
