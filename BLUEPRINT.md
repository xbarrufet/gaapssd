# GAPP (Garden Application) — Project Blueprint

**Última actualización:** 9 d'abril del 2026  
**Estado general:** En desarrollo (fase de implementación)  
**Punto de entrada:** Este documento

---

## 1. Visión General

**GAPP** es una aplicación móvil que conecta pequeñas empresas de jardinería con sus clientes, eliminando la desconfianza mediante **verificación de visitas, documentación fotográfica y comunicación fluida**.

### El Problema

- Clientes particulares (sobretodo segundas residencias) no saben si el jardinero realizó las tareas
- Empresas pequeñas de jardinería carecen de infraestructura digital
- No hay constancia clara de acuerdos de costes
- Revisiones pueden ocurrir semanas después del trabajo

### La Solución

GAPP proporciona:
- ✅ Entrada/salida verificada mediante QR + GPS (radio 10m)
- ✅ Documentación fotográfica de trabajos realizados
- ✅ Comentarios públicos en texto y por voz
- ✅ Chat cliente-jardinero para aprobación de presupuestos
- ✅ Historial completo y auditable

---

## 2. Usuarios

| Rol | Responsabilidad | Acceso |
|-----|-----------------|--------|
| **Cliente** | Propietario del jardín. Revisa visitas, fotos, presupuestos. | App móvil (Clientes tab) |
| **Jardinero** | Realiza tareas. Crea visitas, añade fotos, comentarios. | App móvil (Visitas, fotos, chat) |
| **Gestor** | Gestiona visitas, presupuestos, clientes. Tiene rol de jardinero. | App móvil + Dashboard (future) |
| **Administrador** | Gestiona empresas de jardinería usuarias. | Dashboard admin (future) |

**Focus v1:** Jardinero + Cliente en aplicación móvil

---

## 3. Technology Stack

### Mobile App (`gappsdd_mobile/`)
- **Framework:** Flutter (Dart)
- **Persistencia local:** SQLite (via sqflite)
- **Cámara & QR:** camera + qr_flutter packages
- **Voz:** speech_to_text package
- **Estado:** Riverpod
- **Ruteo:** GoRouter

### Web Admin Dashboard (`gappsdd_web/`)
- **Framework:** Next.js 16 (App Router, TypeScript)
- **UI:** Tailwind CSS v4 + shadcn/ui
- **Diseño:** Tema Arbor Ethos (compartido con mobile)
- **Propósito:** CRUD de usuarios, jardineros y clientes
- **Estado:** En desarrollo (estructura inicial)

### Backend — Supabase
- **Base de datos:** PostgreSQL en Supabase (schema en `supabase/schema.sql`)
- **Auth:** Email + Password via Supabase Auth (publishable key system)
- **Storage:** Bucket `visit-photos` para fotografías de visitas
- **RLS:** Row Level Security por rol (admin, gardener, client)
- **Fallback mobile:** SQLite local para uso offline

### Infraestructura
- **Compilación:** Gradle (Android), Xcode (iOS), Node.js (Web admin)
- **Plataformas mobile:** iOS, Android, macOS, Web (parcial)
- **Plataformas web admin:** Navegador (Next.js)
- **Sincronización:** Pendiente para fase 2

---

## 4. Estructura del Proyecto

```
GAPPSDD/                          # Monorepo root
├── gappsdd_mobile/               # Flutter mobile app
│   ├── lib/                      # Código Dart
│   │   ├── main.dart             # Entry point
│   │   ├── app/                  # Root widget, theme, router, providers
│   │   ├── core/                 # Shared utils, errors
│   │   └── features/             # Features by domain
│   │       ├── auth/             # Autenticación (login)
│   │       ├── chat/             # Chat cliente-jardinero
│   │       └── visits/           # Core: creación, edición, cierre
│   ├── test/                     # Flutter tests
│   ├── android/, ios/, macos/    # Platform native configs
│   └── pubspec.yaml              # Flutter dependencies
│
├── gappsdd_web/                  # Next.js admin dashboard
│   ├── src/app/                  # App Router pages
│   │   ├── dashboard/            # Dashboard, users, gardeners, clients
│   │   └── (auth)/login/         # Login page
│   ├── src/components/           # UI components (shadcn/ui + custom)
│   ├── src/lib/                  # Utils, sample data
│   ├── src/types/                # TypeScript types
│   └── package.json              # Node dependencies
│
├── memory/                       # Shared project documentation
│   ├── tech_stack.md             # Technical requirements
│   ├── product_vision.md         # Business case
│   ├── funcional.md              # Funcional features (Catalan)
│   ├── specs/                    # Technical specifications
│   ├── sample designs/           # UI/UX mockups
│   └── skills/                   # Specialized knowledge
│
├── BLUEPRINT.md                  # THIS FILE
├── CLAUDE.md                     # Claude Code instructions
└── README.md                     # Standard project README
```

---

## 5. Features Principales

### 5.1 Gestión de Visitas (Core)

#### Creación de Visita
- **QR Scan:** Jardinero escanea QR del jardín
  - Valida que el jardín está asignado
  - Valida proximidad GPS (≤ 10m)
  - Crea visita **Verificada**
  
- **Inicio Manual:** Jardinero presiona botón "Nueva Visita"
  - GPS detecta 1 jardín cercano → **Verificada**
  - GPS detecta varios → Usuario elige → **Verificada**
  - GPS no detecta o no disponible → Usuario elige de lista → **NO Verificada**

#### Edición de Visita (Activa o Cerrada)
- Añadir fotos (múltiples)
- Editar comentario publico
- Añadir texto por dictado de voz
- Eliminar fotos o comentarios

**Regla importante:** Si se edita una visita cerrada → pasa a **NO Verificada**

#### Cierre de Visita
- Botón "End Visit" + confirmación
- Calcula automáticamente duración (endTime - startTime)
- Sincronización automática (si hay conectividad)

#### Restauración de App
- Si app se abre/restaura con visita activa
- Salta directamente al detalle de esa visita
- No pasa por lista histórica

### 5.2 Chat Cliente-Jardinero (En desarrollo)
- **ref:** [08-messaging-screen.md](memory/specs/08-messaging-screen.md)
- **Funcionalidades:**
  - Mensajería bidireccional (texto, fotos, documentos)
  - Modo normal: Mensaje simple sin respuesta requerida
  - Modo "con espera de respuesta" (solo jardinero): Long-press en botón envío
  - Sistema de aprobación: Cliente responde con ACEPTAR, RECHAZAR o MÁS INFO
  - Historial completo y auditable en SQLite
  - Marca de leídos

### 5.3 Gestión de Clientes & Jardines (Futuro)
- Lista de clientes asignados
- Jardines por cliente
- Historial de visitas por jardín
- Contactal directo (teléfono, dirección)

### 5.4 Vistas de Cliente (En desarrollo)

#### 5.4.1 Lista de Visitas Completadas
- **Pantalla:** `client_visits_screen.dart`
- **Datos mostrados:**
  - Fecha de visita (badge: día/mes)
  - Descripción de trabajo realizado
  - Indicador visual si hay fotos (icono de cámara en círculo)
  - Estado de verificación (badge)
- **Interacciones:**
  - Botón "Ver Detalles" abre detalle de visita
  - Tap en card también abre detalle (navegación)

#### 5.4.2 Detalle de Visita Completada
- **Pantalla:** `visit_report_screen.dart`
- **Datos mostrados:**
  - **Logística:** Fecha de visita, duración, hora de entrada, hora de salida, info del jardinero
  - **Comentarios:** Texto público del jardinero sobre el trabajo (si disponible)
  - **Galería de fotos:** Grid de 2 columnas con todas las fotos tomadas
  - **Jardinero:** Avatar circular, nombre, rol, con botones de acción:
    - 📞 Llamar (placeholder)
    - 💬 Iniciar Chat (navega a ChatWithRequestModesScreen)
- **Datos origen:** Todo cargado desde SQLite mediante `VisitsRepository.loadVisitReport(visitId)`

#### 5.4.3 Data Models (Cliente)
- **`VisitSummary`:** id, gardenId, durationMinutes, dayLabel, monthLabel, title, description, status, photoCount
- **`VisitReport`:** 
  - id, gardenId, visitDate, duration, entryTime, exitTime, status
  - gardenerName, gardenerRole, gardenerAvatarUrl, heroImageUrl
  - publicComment (comentario del jardinero)
  - photos (lista de fotos con URL, caption, featured flag)

---

## 6. Estado Actual & Roadmap

### ✅ Completado
- Estructura base de Flutter
- Análisis de requisitos
- Especificaciones técnicas (8 docs)
- Design mockups (Arbor Ethos theme)

### 🚧 En Desarrollo (v1)
- **Visitas:** Creación (QR + manual), Edición (fotos, comentarios, dictado), Cierre
- **Navegación:** Bottom bar de 5 elementos, routing completo
- **Persistencia:** SQLite local, sin backend aún

### 🧩 Implementación actual del prototipo
- `Nueva Visita` ya está integrada en el flujo del jardinero con pantalla dedicada.
- El flujo QR y GPS está implementado como simulación funcional (sin cámara/GPS nativos todavía).
- Ya existe control de visita activa única y apertura directa de visita activa desde `Nueva Visita`.
- Se puede cerrar la visita activa desde detalle (`Manual Exit`) para desbloquear nuevas visitas.
- El repositorio de visitas está conectado a persistencia local SQLite (sin backend remoto).
- **Vistas de Cliente:** Completadas pantallas de lista y detalle de visitas completadas:
  - `client_visits_screen.dart`: Lista en card con fecha, descripción e indicador de fotos (si existen)
  - `visit_report_screen.dart`: Detalle con logística (fechas/horarios), comentarios, galería de fotos, e info del jardinero con opciones de llamar/chat
  - Datos cargados desde SQLite (VisitsRepository) con foto count dinámico y chat navegable
  - Chat accesible desde icono en info del jardinero (no button dedicado en footer)

### 🆕 Web Admin Dashboard (En desarrollo)
- **Estructura:** Next.js 16 + Tailwind + shadcn/ui con tema Arbor Ethos
- **Páginas:** Dashboard, Usuarios CRUD, Jardineros CRUD, Clientes CRUD
- **Estado:** Estructura inicial con datos mock. Pendiente integración con backend.

### 📋 Planificado (v2+)
- Backend (Supabase o Spring)
- Sincronización remota
- Chat completo
- Dashboard de cliente web
- Dashboard de gestor
- Presupuestos integrados
- Reportes automáticos

---

## 7. Conceptos Clave

### Visita Verificada vs. NO Verificada

| Aspecto | Verificada | NO Verificada |
|--------|-----------|--------------|
| **Iniciación** | QR scan O Manual con GPS 1-n candidatos | Manual sin GPS / GPS sin candidatos |
| **Garantía** | Ubicación confirmada | Ubicación no validada |
| **Si se edita después** | Sigue verificada (no cambia) | Sigue no verificada |
| **Si se edita siendo CLOSED** | Pasa a NO verified | — |

### Estados de Visita

- **ACTIVE:** Abierta, editable en tiempo real
- **CLOSED:** Cerrada, duración final calculada, editable pero desverifica si se cambia

---

## 8. Navegación de la Aplicación

### Bottom Bar del Jardinero (5 elementos)

```
[Visita] [Clientes] [  Nueva Visita  ] [Chat] [Config]
         Home       Icon doble tamaño
```

### Flujo Completo

```
Login
  ↓
Gardener Root (bottom bar visible)
  ├─ Visita
  │  ├─ visit_list_gardener (histórico)
  │  └─ [Si hay visita activa] → GardenerVisitDetailsScreen (salta lista)
  │
  ├─ Clientes (futuro)
  │  └─ assigned_gardens_visit_status_screen
  │
  ├─ Nueva Visita
  │  ├─ visit_initiation_screen (cámara QR + botón manual)
  │  ├─ [Si hay visita activa] → alerta + abre visita activa
  │  └─ Selectors (jardines cercanos o todos)
  │
  ├─ Chat (futuro)
  └─ Configuración (futuro)

GardenerVisitDetailsScreen (no muestra bottom bar)
  ├─ Ver datos de visita
  ├─ Añadir/eliminar fotos
  ├─ Comentarios + dictado
  └─ Cerrar visita
```

---

## 9. Especificaciones Técnicas (Referencias)

Para detalles implementativos, consultar:

1. **[01-visit-lifecycle.md](memory/specs/01-visit-lifecycle.md)**
   - Lógica de dominio: creación, verificación, cierre
   - Modelos de datos: Visit, VisitPhoto, QrPayload
   - Reglas de negocio

2. **[02-visit-editing.md](memory/specs/02-visit-editing.md)**
   - Flujos de edición: fotos, comentarios, dictado
   - UX requirements (botones 56x56 dp, uso con guantes)
   - Regla de desverificación

3. **[03-visit-initiation-screen.md](memory/specs/03-visit-initiation-screen.md)**
   - UI/UX de pantalla "Nueva Visita"
   - QR scanning + manual flows
   - Selectors de jardines

4. **[04-implementation-guide.md](memory/specs/04-implementation-guide.md)**
   - Arquitectura completa
   - Contrato de VisitsRepository
   - Modelos Dart (Visit, VisitPhoto, VisitSession)
   - State management (Provider/Riverpod)
   - Routing (GoRouter)
   - Testing strategy

5. **[05-identity-and-role-model.md](memory/specs/05-identity-and-role-model.md)**
   - Relación entre User, Cliente y Jardinero
   - Propiedad de jardines y asignaciones activas
   - Cardinalidades y constraints de integridad

6. **[06-identity-role-sqlite-implementation-guide.md](memory/specs/06-identity-role-sqlite-implementation-guide.md)**
   - Guía de implementación SQLite de la Spec 05
   - Esquema SQL, índices, migraciones y transacciones críticas
   - Estrategia de rollout y validación

7. **[07-client-visit-screens.md](memory/specs/07-client-visit-screens.md)**
   - Pantallas cliente: lista de visitas completadas y detalle
   - Modelos de datos: VisitSummary, VisitReport
   - Componentes UI: cards, logistics, comments, photos, chat navigation
   - Implementación de repository y source de datos SQLite

8. **[08-messaging-screen.md](memory/specs/08-messaging-screen.md)**
   - Chat bidireccional entre cliente y jardinero
   - Dos modos de envío: Normal y "Con espera de respuesta" (solo jardinero)
   - Sistema de respuestas (ACEPTAR, RECHAZAR, MÁS INFO)
   - Persistencia completa de mensajes y respuestas en SQLite
   - Modelos de datos: Message, MessageResponse, Conversation

---

## 10. Convenciones del Proyecto

### Idiomas
- **Documentación:** Español o Catalan (según archivo)
- **Código Dart:** Inglés
- **UI texto:** Español (app)

### Naming
- Features en `lib/features/[feature_name]/`
- Specs en `memory/specs/[##-feature-description.md]`
- Files en `snake_case`
- Classes en `PascalCase`
- Métodos en `camelCase`

### Screen State Management
- Usar `StatefulWidget` para pantallas complejas con timer/listeners
- Provider/Riverpod para shared state
- `TextEditingController` para formularios

### UI Principles (Importante para desarrollo)
- Botones mínimo 56x56 dp (toque con guantes)
- Espaciado amplio entre acciones
- Confirmaciones obligatorias en destructivas
- Mensajes de error claros y accionables
- Bottom bar solo en pantallas raíz

---

## 11. Quick Start para Nueva Sesión

1. **¿Qué estoy implementando?**
   - Revisar [01-06 specs](memory/specs/) según feature

2. **¿Cómo se conecta con el resto?**
   - Ver sección 8 (Navegación) de este documento

3. **¿Qué modelos de datos necesito?**
   - Consultar [04-implementation-guide.md](memory/specs/04-implementation-guide.md) sección 3

4. **¿Cuál es la regla de dominio?**
   - Buscar en specs relevante (01, 02, 03, 05, 06) sección Business Rules

5. **¿Errores o edge cases?**
   - Ver sección 9 de 04-implementation-guide.md

---

## 12. Contacto & Recursos

### Design Reference
- **Base design:** memory/sample designs/arbor_ethos/DESIGN.md
- **Screens mockup:** memory/sample designs/screens/

### External Docs
- Flutter: https://docs.flutter.dev
- Supabase: https://supabase.com/docs
- QR scanning: https://pub.dev/packages/qr_code_scanner

### Workspace
- Root: `/Users/barrufex/Development/GAPP2025/GAPPSDD`

---

## 📝 Nota de Uso

Este documento es tu **mapa mental principal**. Léelo al iniciar una sesión si vienes de contexto externo. Cada sección te dirige a documentos más detallados para profundizar.

**Última revisión:** 9 d'abril del 2026
