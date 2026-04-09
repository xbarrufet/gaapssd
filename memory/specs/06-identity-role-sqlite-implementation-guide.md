# Implementation Guide: Spec 05 on SQLite

**Versión:** 1.0  
**Fecha:** 2026-04-08  
**Estado:** Approved  
**Scope:** Implementación técnica en SQLite del modelo definido en `05-identity-and-role-model.md`

> **Nota monorepo:** Todos los paths `lib/...` son relativos a `gappsdd_mobile/`.

---

## 1. Overview

Esta guía convierte la Spec 05 en una implementación SQLite lista para producción local (offline-first), manteniendo compatibilidad futura con backend relacional.

**Referenced specs:**
- `01-visit-lifecycle.md`
- `02-visit-editing.md`
- `05-identity-and-role-model.md`

Objetivo principal:
- materializar el modelo `User`/`Role`/`Cliente`/`Jardinero`/`Garden`/`GardenAssignment`
- conservar reglas críticas de visitas (una `ACTIVE` por jardinero)
- dejar base para sync futuro sin rediseño de esquema

---

## 2. SQLite Conventions

1. Todas las PK como `TEXT` con UUID.
2. Fechas en UTC ISO-8601 (`TEXT`) para trazabilidad.
3. Enums como `TEXT` (`CLIENT`, `GARDENER`, `ACTIVE`, `CLOSED`, etc.).
4. `PRAGMA foreign_keys = ON` obligatorio al abrir DB.
5. Índices en FKs y columnas de búsqueda frecuente.
6. Escrituras críticas dentro de transacciones.

---

## 3. Physical Schema (v1)

### 3.1 Identity Tables

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE roles (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL
);

CREATE TABLE user_roles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  role_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
  UNIQUE (user_id, role_id)
);
```

### 3.2 Business Profiles

```sql
CREATE TABLE client_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  phone TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE gardener_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  phone TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

### 3.3 Gardens and Assignments

```sql
CREATE TABLE gardens (
  id TEXT PRIMARY KEY,
  client_id TEXT NOT NULL,
  name TEXT NOT NULL,
  address TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (client_id) REFERENCES client_profiles(id) ON DELETE RESTRICT
);

CREATE INDEX idx_gardens_client_id ON gardens(client_id);

CREATE TABLE garden_assignments (
  id TEXT PRIMARY KEY,
  garden_id TEXT NOT NULL,
  gardener_id TEXT NOT NULL,
  is_active INTEGER NOT NULL,
  valid_from TEXT NOT NULL,
  valid_to TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (garden_id) REFERENCES gardens(id) ON DELETE CASCADE,
  FOREIGN KEY (gardener_id) REFERENCES gardener_profiles(id) ON DELETE RESTRICT
);

CREATE INDEX idx_garden_assignments_garden_id ON garden_assignments(garden_id);
CREATE INDEX idx_garden_assignments_gardener_id ON garden_assignments(gardener_id);

CREATE UNIQUE INDEX ux_garden_active_assignment
ON garden_assignments(garden_id)
WHERE is_active = 1;
```

### 3.4 Visit Anchor Constraints

```sql
CREATE TABLE visits (
  id TEXT PRIMARY KEY,
  garden_id TEXT NOT NULL,
  gardener_id TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('ACTIVE', 'CLOSED')),
  verification_status TEXT NOT NULL,
  initiation_method TEXT NOT NULL,
  start_time TEXT NOT NULL,
  end_time TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (garden_id) REFERENCES gardens(id) ON DELETE RESTRICT,
  FOREIGN KEY (gardener_id) REFERENCES gardener_profiles(id) ON DELETE RESTRICT
);

CREATE INDEX idx_visits_garden_id ON visits(garden_id);
CREATE INDEX idx_visits_gardener_id ON visits(gardener_id);

CREATE UNIQUE INDEX ux_visits_active_per_gardener
ON visits(gardener_id)
WHERE status = 'ACTIVE';
```

---

## 4. Application Layers

### 4.1 Suggested Structure

```text
lib/
  core/
    db/
      app_database.dart
      migrations/
        migration_v1.dart
  features/
    auth/
      data/
        sqlite_user_repository.dart
    visits/
      data/
        sqlite_visits_repository.dart
    gardens/
      data/
        sqlite_gardens_repository.dart
```

### 4.2 DB Bootstrap Responsibilities

`app_database.dart` debe:
1. abrir conexión SQLite
2. activar `foreign_keys`
3. aplicar migraciones por versión
4. inicializar datos base (`roles`) si no existen

---

## 5. Repository Contracts (Implementation Targets)

### 5.1 Identity Queries

1. `findUserByEmail(email)`
2. `loadUserRoles(userId)`
3. `loadClientProfileByUser(userId)`
4. `loadGardenerProfileByUser(userId)`

### 5.2 Gardens/Assignments Queries

1. `loadGardensByClient(clientId)`
2. `loadActiveGardensByGardener(gardenerId)`
3. `loadActiveGardenerForGarden(gardenId)`

### 5.3 Visit Guard Queries

1. `loadActiveVisit(gardenerId)`
2. `startVisit(...)` con validación de visita activa en transacción
3. `closeVisit(visitId)`

---

## 6. Critical Transactions

### 6.1 Start Visit Transaction

Pasos:
1. consultar visita `ACTIVE` de `gardener_id`
2. si existe, abortar con error de negocio
3. validar asignación activa del jardín al jardinero
4. insertar nueva visita `ACTIVE`

### 6.2 Reassign Garden Transaction

Pasos:
1. cerrar asignación activa existente (`is_active = 0`, `valid_to = now`)
2. insertar nueva asignación con `is_active = 1`
3. commit atómico

---

## 7. Migration Plan

### 7.1 DB Version 1

Crear tablas e índices de secciones 3.1 a 3.4.

### 7.2 DB Version 2 (implemented)

Aplicado en `sqlite_visits_repository.dart` para eliminar metadatos hardcoded del reporte cliente:
1. `ALTER TABLE client_profile ADD COLUMN gardener_role TEXT NOT NULL DEFAULT 'Lead Gardener'`
2. Backfill automático por `DEFAULT` para instalaciones existentes
3. `loadVisitReport(...)` toma `gardenerName`, `gardenerRole`, `gardenerAvatarUrl` y `headerImageUrl` desde `client_profile`

### 7.3 DB Version 3 (future)

Preparado para:
1. `chat_threads`, `chat_messages`, `chat_requests`
2. `quotes`, `quote_items`, `quote_decisions`
3. `sync_outbox` para cambios pendientes remotos

Regla:
- No romper PK/FK existentes.
- Añadir tablas nuevas o columnas nullable con backfill controlado.

---

## 8. Seed Data (Local Development)

Inicializar en v1:
1. `roles`: CLIENT, GARDENER, MANAGER, ADMIN
2. usuarios demo cliente/jardinero
3. perfiles asociados
4. jardines demo y asignaciones activas

Objetivo:
- mantener prototipo funcional sin backend
- asegurar que pantallas actuales pueden migrar de FakeRepository a SQLite repository

---

## 9. Validation & Testing

### 9.1 Mandatory Integration Tests

1. crear usuario con email duplicado falla
2. crear segundo perfil cliente para mismo `user_id` falla
3. crear segunda asignación activa del mismo jardín falla
4. crear segunda visita `ACTIVE` para mismo jardinero falla
5. cliente con varios jardines y jardineros distintos se consulta correctamente

### 9.2 Behavior Tests

1. login por user y resolución de perfil/rol correcta
2. listado de jardines por cliente correcto
3. listado de jardines asignados por jardinero correcto
4. inicio/cierre de visita respeta constraints

---

## 10. Rollout Strategy

1. introducir `AppDatabase` sin sustituir repositorios fake
2. crear repositorios SQLite en paralelo
3. activar por feature flag (`useSqliteRepo`)
4. ejecutar smoke tests de flujo de login y visitas
5. retirar fake repositories al estabilizar

---

## 11. Acceptance Criteria

1. El modelo de Spec 05 está persistido íntegramente en SQLite.
2. Se cumple la integridad de ownership y asignación activa.
3. Se cumple una visita activa por jardinero a nivel de DB.
4. El prototipo sigue funcionando sin backend.
5. El diseño permite evolución a sync remoto sin rediseño de entidades núcleo.