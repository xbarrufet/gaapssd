# Technical Specifications: Identity, Roles & Garden Ownership Model

**Versión:** 1.0  
**Fecha:** 8 d'abril del 2026  
**Estado:** Approved  
**Scope:** Modelo de datos base para `User`, perfiles de negocio (`Cliente`, `Jardinero`), propiedad de jardines y asignaciones

---

## 1. Overview

Esta especificación define el modelo de identidad y roles que soporta el dominio actual y evita bloqueos para fases futuras (chat transaccional, presupuestos, sincronización remota y dashboards).

Principio clave: **la identidad de acceso (`User`) se separa de los perfiles de negocio (`Cliente`, `Jardinero`)**.

---

## 2. Scope

**Incluye:**
- Entidad `User` para autenticación/identidad
- Entidades de perfil de negocio `ClientProfile` y `GardenerProfile`
- Propiedad de jardines (1 cliente tiene N jardines)
- Asignación de jardines a jardineros (1 jardinero asignado a N jardines)
- Regla de negocio: un cliente puede tener jardines con distinto jardinero

**No incluye:**
- Modelo completo de chat
- Modelo de presupuestos
- Permisos avanzados por pantalla
- Multiempresa (se deja preparado para futura extensión)

---

## 3. Business Rules

1. Un `Cliente` puede ser propietario de **muchos** jardines.
2. Cada jardín debe tener **un único cliente propietario**.
3. Un `Jardinero` puede estar asignado a **muchos** jardines.
4. Un cliente puede tener jardines distintos, cada uno asignado a jardineros diferentes.
5. El `User` no equivale a cliente o jardinero; `User` es identidad de login.
6. Un mismo `User` puede tener uno o más roles (ejemplo futuro: gestor con rol jardinero).
7. Toda visita debe registrar explícitamente `gardenId` y `gardenerId`.
8. Debe existir una única visita `ACTIVE` por jardinero.

---

## 4. Data Model

### 4.1 Identity Layer

```text
User {
  id: UUID
  email: String
  passwordHash: String
  isActive: Bool
  createdAt: DateTime
  updatedAt: DateTime
}

Role {
  id: UUID
  code: String          // CLIENT | GARDENER | MANAGER | ADMIN
  name: String
}

UserRole {
  id: UUID
  userId: UUID          // FK -> User
  roleId: UUID          // FK -> Role
  createdAt: DateTime
}
```

### 4.2 Business Profiles Layer

```text
ClientProfile {
  id: UUID
  userId: UUID          // FK -> User (1:1 logical)
  displayName: String
  phone: String?
  createdAt: DateTime
  updatedAt: DateTime
}

GardenerProfile {
  id: UUID
  userId: UUID          // FK -> User (1:1 logical)
  displayName: String
  phone: String?
  createdAt: DateTime
  updatedAt: DateTime
}
```

### 4.3 Garden Ownership & Assignment Layer

```text
Garden {
  id: UUID
  clientId: UUID        // FK -> ClientProfile (owner)
  name: String
  address: String
  latitude: Double?
  longitude: Double?
  createdAt: DateTime
  updatedAt: DateTime
}

GardenAssignment {
  id: UUID
  gardenId: UUID        // FK -> Garden
  gardenerId: UUID      // FK -> GardenerProfile
  isActive: Bool
  validFrom: DateTime
  validTo: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
}
```

### 4.4 Visit Anchor (required relation)

```text
Visit {
  id: UUID
  gardenId: UUID        // FK -> Garden
  gardenerId: UUID      // FK -> GardenerProfile
  status: String        // ACTIVE | CLOSED
  verificationStatus: String
  initiationMethod: String
  startTime: DateTime
  endTime: DateTime?
  createdAt: DateTime
  updatedAt: DateTime
}
```

---

## 5. Cardinality Summary

1. `User 1 --- N UserRole`
2. `User 1 --- 0..1 ClientProfile`
3. `User 1 --- 0..1 GardenerProfile`
4. `ClientProfile 1 --- N Garden`
5. `Garden 1 --- N GardenAssignment`
6. `GardenerProfile 1 --- N GardenAssignment`
7. `Garden 1 --- N Visit`
8. `GardenerProfile 1 --- N Visit`

Regla operativa actual:
- Un jardín tiene una única asignación activa (`GardenAssignment.isActive = true`) en cada momento.

---

## 6. Integrity Constraints

1. `users.email` debe ser único.
2. `client_profiles.user_id` único (perfil cliente máximo uno por user).
3. `gardener_profiles.user_id` único (perfil jardinero máximo uno por user).
4. Debe existir un `ClientProfile` válido para crear un jardín.
5. Debe existir un `GardenerProfile` válido para asignar un jardín.
6. Solo una asignación activa por jardín:
   - índice único parcial sobre `garden_assignments(garden_id)` donde `is_active = true`.
7. Solo una visita activa por jardinero:
   - índice único parcial sobre `visits(gardener_id)` donde `status = 'ACTIVE'`.

---

## 7. Query Patterns (v1 + future-safe)

1. Jardines por cliente:
   - `SELECT * FROM gardens WHERE client_id = :clientId`
2. Jardines asignados a jardinero:
   - join `garden_assignments` + `gardens` con `is_active = true`
3. Jardinero actual de un jardín:
   - `SELECT gardener_id FROM garden_assignments WHERE garden_id = :gardenId AND is_active = true`
4. Verificar regla de visita activa única:
   - `SELECT id FROM visits WHERE gardener_id = :gardenerId AND status = 'ACTIVE'`

---

## 8. Migration Strategy Guidance

1. Mantener tablas de identidad separadas de tablas operativas (`visits`, `visit_photos`, etc.).
2. Modelar enums como `TEXT` en SQLite para facilitar migración futura a PostgreSQL/Supabase o Java + DB relacional.
3. Usar UUID local para todas las entidades desde v1.
4. Guardar `createdAt/updatedAt` en UTC para estrategia de sincronización futura.
5. Evitar acoplar UI a flags de rol sueltos; siempre resolver permisos por rol/perfil.

---

## 9. Acceptance Criteria

1. El sistema puede representar usuarios cliente y usuarios jardinero sin ambiguedad.
2. Un cliente puede tener múltiples jardines.
3. Un jardinero puede estar asignado a múltiples jardines.
4. El sistema puede representar que jardines de un mismo cliente tengan jardineros distintos.
5. El modelo soporta cambios de asignación de jardinero sin perder histórico.
6. El modelo no bloquea la incorporación futura de gestor/admin y funcionalidades de chat/presupuestos.