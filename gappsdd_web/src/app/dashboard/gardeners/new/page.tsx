import { redirect } from "next/navigation";

export default function NewGardenerPage() {
  redirect("/dashboard/users/new?role=gardener&from=gardeners");
}
