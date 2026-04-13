export type UserRole =
  | "SUPER_ADMIN"
  | "COMPANY_ADMIN"
  | "GARDENER"
  | "MANAGER"
  | "CLIENT"
  | "ADMIN"; // legacy — kept for backward compat

export interface CurrentUser {
  id: string;
  role: UserRole;
  companyId: string | null;
}

export interface Company {
  id: string;
  name: string;
  slug: string;
  logoUrl?: string;
  isActive: boolean;
  createdAt: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  companyId?: string | null;
  createdAt: string;
}

export interface Gardener {
  id: string;
  userId: string;
  name: string;
  email: string;
  phone: string;
  companyId?: string | null;
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
