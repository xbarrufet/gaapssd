import { redirect } from "next/navigation";

export default function NewClientPage() {
  redirect("/dashboard/users/new?role=client&from=clients");
}
