import Link from "next/link";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { getGardeners } from "./actions";
import { GardenersTable } from "./gardeners-table";

export default async function GardenersPage() {
  const gardeners = await getGardeners();

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-heading text-2xl font-bold tracking-tight">
            Jardineros
          </h1>
          <p className="text-muted-foreground">
            Gestión de jardineros y sus asignaciones.
          </p>
        </div>
        <Link href="/dashboard/users/new">
          <Button>
            <Plus className="mr-2 h-4 w-4" />
            Nuevo Jardinero
          </Button>
        </Link>
      </div>
      <GardenersTable gardeners={gardeners} />
    </div>
  );
}
