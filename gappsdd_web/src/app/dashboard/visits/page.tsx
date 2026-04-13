import { getVisits } from "./actions";
import { VisitsTable } from "./visits-table";

export default async function VisitsPage() {
  const visits = await getVisits();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="font-heading text-2xl font-bold tracking-tight">
          Visitas
        </h1>
        <p className="text-muted-foreground">
          Registro de visitas realizadas por los jardineros.
        </p>
      </div>
      <VisitsTable visits={visits} />
    </div>
  );
}
