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

export interface Visit {
  id: string;
  garden_id: string;
  gardener_id: string;
  status: "ACTIVE" | "CLOSED";
  verification_status: "VERIFIED" | "NOT_VERIFIED";
  initiation_method: "QR_SCAN" | "MANUAL";
  title: string;
  description: string;
  public_comment: string;
  started_at: string;
  ended_at: string | null;
  created_at: string;
  updated_at: string;
  gardener_profiles?: { id: string; display_name: string } | null;
  gardens?: { id: string; name: string; address: string } | null;
}

export interface VisitPhoto {
  id: string;
  visit_id: string;
  storage_path: string;
  thumbnail_path: string;
  label: string;
  created_at: string;
}
