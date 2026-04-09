import { redirect } from "next/navigation";

// Clients are created as users with role "client" from the Users section
export default function NewClientPage() {
  redirect("/dashboard/users/new");
}
