import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Users, Flower2, UserCircle, CalendarCheck } from "lucide-react";

const stats = [
  { title: "Usuarios", value: "24", icon: Users, description: "Registrados" },
  { title: "Jardineros", value: "8", icon: Flower2, description: "Activos" },
  { title: "Clientes", value: "16", icon: UserCircle, description: "Activos" },
  {
    title: "Visitas",
    value: "142",
    icon: CalendarCheck,
    description: "Este mes",
  },
];

export default function DashboardPage() {
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
