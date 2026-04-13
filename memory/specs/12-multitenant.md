# Spec 12 — Multitenant: Gestión de múltiples empresas de jardinería

**Estado:** Draft  
**Fecha:** 2026-04-13  
**Alcance:** Backend (Supabase schema + RLS), Web admin (panel adaptado por rol), Mobile (sin cambios de UX)

---

## 1. Resumen

El sistema pasa de single-tenant a multitenant. Cada empresa de jardinería opera de forma aislada: sus jardineros, jardines y visitas son privados. Los clientes son globales (pueden tener jardines con distintas empresas). El super-admin gestiona toda la plataforma; cada empresa tiene su propio company-admin.

---

## 2. Roles

| Rol | Descripción |
|-----|-------------|
| `SUPER_ADMIN` | Ve y gestiona toda la plataforma (todas las empresas, todos los datos). Es el ADMIN actual renombrado. |
| `COMPANY_ADMIN` | Gestiona su empresa: jardineros, jardines y clientes de su empresa. No ve datos de otras empresas. |
| `GARDENER` | Jardinero de una empresa. Ve solo sus jardines asignados y datos de contacto mínimos del cliente. |
| `CLIENT` | Global. Puede tener jardines con distintas empresas. |
| `MANAGER` | Reservado para uso futuro (sin cambios respecto al estado actual). |

---

## 3. Modelo de datos

### 3.1 Nueva tabla: `companies`

```sql
CREATE TABLE companies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  logo_url    TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 3.2 Cambios en tablas existentes

| Tabla | Campo nuevo | Descripción |
|-------|-------------|-------------|
| `user_profiles` | `company_id UUID REFERENCES companies(id)` | Nulo para SUPER_ADMIN y CLIENT. Obligatorio para COMPANY_ADMIN y GARDENER. |
| `gardens` | `company_id UUID NOT NULL REFERENCES companies(id)` | Un jardín pertenece a exactamente una empresa. |
| `conversations` | `company_id UUID NOT NULL REFERENCES companies(id)` | Conversación vinculada a la empresa del jardinero. |

> **Nota sobre clientes:** Los clientes (`client_profiles`) siguen siendo globales, sin `company_id`. El email es el identificador único de un cliente.

### 3.3 Unicidad de conversaciones

La restricción única existente `(gardener_id, client_id)` se reemplaza por `(gardener_id, client_id, company_id)` para permitir conversaciones separadas si el mismo cliente trabaja con varias empresas.

---

## 4. Aislamiento de datos (RLS)

### Principios

- **SUPER_ADMIN:** Acceso completo a todas las tablas.
- **COMPANY_ADMIN:** Solo datos donde `company_id = su company_id`.
- **GARDENER:** Solo sus jardines asignados (`garden_assignments`) y visitas propias. Del cliente, solo ve `name` y `phone`.
- **CLIENT:** Solo sus propios jardines y conversaciones.

### Campos de cliente visibles para GARDENER

Siempre fijos, sin configuración por el cliente:
- `name`
- `phone`

El email y otros datos del cliente **no son visibles** para el jardinero.

---

## 5. Flujo de creación de una empresa

Solo el SUPER_ADMIN puede crear empresas, desde el panel web:

1. SUPER_ADMIN rellena formulario: nombre de empresa + slug + (opcional) logo.
2. En el mismo flujo, crea el usuario COMPANY_ADMIN de esa empresa: email + contraseña temporal.
3. El sistema crea la empresa en `companies` y el usuario en Supabase Auth + `user_profiles` con `role = COMPANY_ADMIN` y `company_id` asignado.
4. El company-admin recibe email con credenciales y puede cambiar su contraseña en el primer login.

---

## 6. Capacidades del COMPANY_ADMIN

### Gestión de jardineros
- Crear jardinero: genera usuario Supabase Auth + perfil vinculado a su empresa.
- Editar datos del jardinero (nombre, teléfono, avatar).
- Desactivar jardinero (sin borrar historial de visitas). Campo `is_active` en `user_profiles`.
- Asignar y desasignar jardines a jardineros (`garden_assignments`).

### Gestión de clientes y jardines
- Crear cliente nuevo (global, identificado por email). Si el email ya existe, se vincula el cliente existente.
- Crear jardines para clientes y asignarlos a su empresa (`company_id`).
- Ver y editar jardines de su empresa.

### Lo que NO puede hacer el COMPANY_ADMIN
- Ver o editar datos de otras empresas.
- Eliminar usuarios o empresas (solo SUPER_ADMIN).
- Ver el email u otros datos privados de clientes que pertenecen a jardines de otras empresas.

---

## 7. Panel web — experiencia por rol

Misma aplicación (`gappsdd_web`), misma URL. El sidebar y las páginas se adaptan al rol del usuario logueado.

### SUPER_ADMIN ve
- Todo el panel actual + nueva sección **Empresas** (CRUD de empresas y creación de company-admins).
- En todas las listas (jardineros, clientes, jardines) puede filtrar por empresa.

### COMPANY_ADMIN ve
- Panel filtrado a su empresa: jardineros, clientes, jardines de su empresa.
- No ve la sección Empresas.
- No ve datos de otras empresas.

---

## 8. App móvil — sin cambios de UX

- El jardinero hace login normalmente. Su `company_id` se resuelve automáticamente desde su `user_profiles`.
- No se introduce ningún código de empresa en el login.
- El jardinero solo ve jardines y visitas de su empresa.

---

## 9. Migración de datos

Los datos existentes se consideran datos de prueba/desarrollo. **Se limpian y se empieza de cero.** No hay migración de datos legacy.

---

## 10. Fuera de scope (MVP)

- Billing o facturación por empresa.
- Personalización de marca por empresa en la app móvil (logo propio, colores).
- Analytics cruzados entre empresas.
- API pública por empresa.
- Subdominios por empresa.
- Auto-registro de empresas (onboarding público).

---

## 11. Impacto en specs existentes

| Spec | Impacto |
|------|---------|
| 05 — Identity & Role Model | Añadir roles SUPER_ADMIN y COMPANY_ADMIN. `company_id` en `user_profiles`. |
| 09 — Garden QR Generation | Los QR siguen funcionando igual; la validación de jardín incluirá `company_id`. |
| 10 — Notificaciones | Sin cambio funcional; el jardinero sigue siendo el actor. |
| 11 — Heatmap | Sin cambio funcional; las visitas siguen vinculadas al jardinero. |
| Todas las RLS | Reescribir políticas RLS para incluir filtro por `company_id`. |
