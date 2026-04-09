export interface User {
  id: string;
  name: string;
  email: string;
  role: "admin" | "gardener" | "client";
  createdAt: string;
}

export interface Gardener {
  id: string;
  userId: string;
  name: string;
  email: string;
  phone: string;
  assignedGardens: number;
  status: "active" | "inactive";
}

export interface Client {
  id: string;
  userId: string;
  name: string;
  email: string;
  phone: string;
  gardens: number;
  status: "active" | "inactive";
}
