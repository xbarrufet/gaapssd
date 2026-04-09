import type { User, Gardener, Client } from "@/types";

export const sampleUsers: User[] = [
  { id: "1", name: "Admin GAPP", email: "admin@gapp.es", role: "admin", createdAt: "2026-01-15" },
  { id: "2", name: "Carlos Martínez", email: "carlos@gapp.es", role: "gardener", createdAt: "2026-02-01" },
  { id: "3", name: "María López", email: "maria@gapp.es", role: "gardener", createdAt: "2026-02-10" },
  { id: "4", name: "Ana García", email: "ana@cliente.es", role: "client", createdAt: "2026-03-01" },
  { id: "5", name: "Pedro Sánchez", email: "pedro@cliente.es", role: "client", createdAt: "2026-03-05" },
  { id: "6", name: "Laura Fernández", email: "laura@cliente.es", role: "client", createdAt: "2026-03-12" },
];

export const sampleGardeners: Gardener[] = [
  { id: "1", userId: "2", name: "Carlos Martínez", email: "carlos@gapp.es", phone: "+34 612 345 678", assignedGardens: 5, status: "active" },
  { id: "2", userId: "3", name: "María López", email: "maria@gapp.es", phone: "+34 623 456 789", assignedGardens: 3, status: "active" },
];

export const sampleClients: Client[] = [
  { id: "1", userId: "4", name: "Ana García", email: "ana@cliente.es", phone: "+34 634 567 890", gardens: 2, status: "active" },
  { id: "2", userId: "5", name: "Pedro Sánchez", email: "pedro@cliente.es", phone: "+34 645 678 901", gardens: 1, status: "active" },
  { id: "3", userId: "6", name: "Laura Fernández", email: "laura@cliente.es", phone: "+34 656 789 012", gardens: 3, status: "inactive" },
];
