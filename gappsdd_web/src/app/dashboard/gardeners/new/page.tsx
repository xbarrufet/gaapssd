import { redirect } from "next/navigation";

// Gardeners are created as users with role "gardener" from the Users section
export default function NewGardenerPage() {
  redirect("/dashboard/users/new");
}
