# GAPP - Auditoria de Best Practices & Plan de Refactor

**Data:** 8 d'abril del 2026  
**Estat:** Prototip funcional (v1) - Pre-produccion

---

## Resumen Ejecutivo

La aplicacion tiene una base solida: estructura feature-first, repository pattern, modelos de dominio inmutables y un theme system bien pensado. Sin embargo, hay divergencias significativas respecto a las specs (`memory/specs/04-implementation-guide.md`) y multiples anti-patterns que dificultaran la escalabilidad. Este documento lista los problemas ordenados por prioridad de impacto y propone un plan de refactor incremental.

---

## PRIORIDAD CRITICA (P0) - Bloquean escalabilidad y calidad

### 1. Sin State Management (specs requieren Provider/Riverpod)

**Problema:** Toda la app usa `setState()` + `FutureBuilder` sin caching. La spec `04-implementation-guide.md` requiere Provider/Riverpod con providers dedicados (`CurrentVisitProvider`, `VisitSessionProvider`, `GardenerProvider`).

**Impacto:**
- `FutureBuilder` se re-ejecuta en cada rebuild (consultas SQLite innecesarias)
- El bottom nav bar hace queries async en cada build (`_hasUnreadMessages` en 6 pantallas)
- No hay forma de compartir estado entre pantallas (el unread count del chat se calcula independientemente en cada screen)
- Imposible implementar real-time updates sin re-arquitecturar

**Archivos afectados:** Todos los screens en `lib/features/*/presentation/`

**Solucion:** Implementar Riverpod con providers para:
- `activeVisitProvider` - visita activa (o null)
- `visitsListProvider` - lista historica con cache
- `chatUnreadProvider` - contador unread compartido
- `gardenListProvider` - jardines asignados

---

### 2. Repositorios creados en `build()` - Memory Leaks

**Problema:** En `app.dart:15-16`, los repositorios se instancian dentro de `build()`, recreandose en cada rebuild. Peor aun, varias pantallas crean `SqliteChatRepository()` inline:
- `client_visits_screen.dart:32`
- `visit_report_screen.dart:286`
- `chat_with_request_modes_screen.dart:177,186`

**Impacto:** Multiples conexiones SQLite abiertas simultaneamente, posibles data races, memory leaks.

**Solucion:** Singleton de repositorios via Riverpod providers o GetIt service locator.

---

### 3. Archivos gigantes (God Widgets)

**Problema:**
- `gardener_visit_details_screen.dart` — **1526 lineas**
- `chat_with_request_modes_screen.dart` — **1143 lineas**
- `gardener_visits_list_screen.dart` — **704 lineas**
- `assigned_gardens_visit_status_screen.dart` — **665 lineas**
- `client_visits_screen.dart` — **630 lineas**

**Impacto:** Dificil de mantener, testear y revisar. Logica de negocio mezclada con UI.

**Solucion:** Extraer widgets a archivos separados, mover logica de negocio a controllers/cubits.

---

### 4. Logica de negocio en la capa de presentacion

**Problema:** Las pantallas contienen logica de dominio que deberia estar en servicios o use cases:
- `new_visit_screen.dart` — flujo completo de inicio de visita (QR + manual + GPS + seleccion) en metodos UI (~120 lineas en `_startManualFlow`)
- `gardener_visit_details_screen.dart` — logica de autosave, dictado, gestion de fotos
- `gardener_visits_list_screen.dart` — parsing de fechas, filtrado, calculo de metricas

**Impacto:** Imposible testear unitariamente la logica de negocio sin levantar widgets.

**Solucion:** Extraer a use cases o service classes:
- `StartVisitUseCase`
- `VisitEditingService`
- `VisitListController`

---

## PRIORIDAD ALTA (P1) - Afectan robustez y mantenibilidad

### 5. Sin routing declarativo (specs requieren GoRouter)

**Problema:** Navegacion imperativa con `Navigator.push(MaterialPageRoute(...))` en todas partes. La spec `04-implementation-guide.md` define rutas GoRouter (`/gardener/visits`, `/visit-detail/:visitId`, etc.).

**Impacto:**
- Deep linking imposible
- No se puede restaurar estado de navegacion
- Rutas duplicadas y fragiles
- Bottom bar reimplementado en cada pantalla con logica de navegacion custom

**Archivos afectados:** Todas las pantallas + `app.dart`

**Solucion:** Implementar GoRouter con `ShellRoute` para el bottom nav bar.

---

### 6. IDs de usuario hardcodeados

**Problema:** `'gardener-001'`, `'client-001'` aparecen en:
- `client_visits_screen.dart:34`
- `chat_with_request_modes_screen.dart` (multiples)
- `gardener_visits_list_screen.dart`
- `assigned_gardens_visit_status_screen.dart`
- Todos los seed data files

**Impacto:** Imposible soportar multi-usuario. La spec `05-identity-and-role-model.md` define un modelo User/Profile completo.

**Solucion:** Implementar `AuthProvider` que exponga el usuario actual y sus perfiles.

---

### 7. Cobertura de tests minima

**Problema:** Solo 3 archivos de test (chat models + 1 integracion). La spec `04-implementation-guide.md` requiere:
- Unit tests de logica de visitas (creacion, verificacion, cierre)
- Widget tests de flujos principales
- Integration tests de 7 flujos criticos
- Tests de constraints (email duplicado, visita activa duplicada, etc.)

**Archivos sin test:** `sqlite_visits_repository.dart` (780 lineas de logica critica), todos los screens, todos los modelos de visits.

**Solucion:** Priorizar tests de repositorio (business rules) y tests de flujos criticos.

---

### 8. Bottom Nav Bar duplicado en cada pantalla

**Problema:** `_GardenerBottomNavBar` esta copy-pasted (con variaciones) en:
- `gardener_visits_list_screen.dart`
- `assigned_gardens_visit_status_screen.dart`
- `chat_with_request_modes_screen.dart`

Cada copia tiene su propio `FutureBuilder` para calcular unread count.

**Impacto:** Inconsistencias entre copias, N queries por cada pantalla, imposible mantener.

**Solucion:** Extraer a widget compartido + GoRouter `ShellRoute` para bottom bar persistente.

---

## PRIORIDAD MEDIA (P2) - Mejoran calidad del codigo

### 9. Error handling generico

**Problema:** Se usa `StateError` para errores de negocio y SnackBars genericos para feedback. No hay tipos de error especificos.

**Solucion:** Crear jerarquia de errores: `VisitError`, `AuthError`, `ChatError` con mensajes localizados. Implementar `Result<T>` pattern o sealed classes para manejo explicito.

---

### 10. Modelos de dominio incompletos

**Problema:**
- Sin `==` / `hashCode` overrides (comparacion por referencia)
- Sin `fromJson` / `toJson` (necesarios para backend futuro)
- Strings en vez de enums para estados (`status: String` en vez de `VisitStatus.active`)
- Chat models usan `String status` en vez de enum

**Solucion:** Usar `freezed` o implementar manualmente equality + serialization. Convertir strings a enums.

---

### 11. Sin soporte dark mode

**Problema:** `app_theme.dart` solo define tema claro. No hay `ThemeData` para dark mode.

**Impacto:** UX pobre en condiciones de poca luz (jardineros trabajan al amanecer/atardecer).

**Solucion:** Crear `AppTheme.dark()` basado en la misma paleta "Arbor Ethos".

---

### 12. Callbacks vacios (funcionalidad placeholder)

**Problema:** Multiples `onPressed: () {}` sin implementacion:
- `login_screen.dart:160,170` (botones de accion)
- `client_visits_screen.dart:100,165` (navegacion)
- `assigned_gardens_visit_status_screen.dart:133,135,221`

**Impacto:** Botones que no hacen nada confunden al usuario.

**Solucion:** Deshabilitar botones no implementados (`onPressed: null`) o mostrar "Coming soon" toast.

---

### 13. Sin internacionalizacion (i18n)

**Problema:** Strings UI hardcodeados en espanol/catalan mezclados directamente en widgets.

**Solucion:** Implementar `flutter_localizations` + `intl` con archivos `.arb`.

---

### 14. Seed data con posible bug critico

**Problema:** En `chat_seed_data.dart:52`, se inserta en tabla `'conversations'` un objeto `msg` que deberia ir a `'messages'`. Posible bug de tabla incorrecta.

**Solucion:** Verificar y corregir la insercion.

---

## PRIORIDAD BAJA (P3) - Nice to have

### 15. Sin accesibilidad (a11y)

**Problema:** Ninguna pantalla tiene `Semantics` widgets, labels para screen readers, ni soporte de focus management.

---

### 16. Animaciones con magic numbers

**Problema:** Valores de animacion (durations, offsets, curves) hardcodeados en cada widget sin constantes compartidas.

---

### 17. Network images sin error handling

**Problema:** `Image.network()` sin `errorBuilder` ni `loadingBuilder`. Si la URL falla, widget roto.

---

### 18. Schema migrations fragil

**Problema:** En `sqlite_visits_repository.dart`, la migracion solo chequea version 2. No hay rollback ni validacion de schema.

---

---

## PLAN DE REFACTOR

### Fase 0: Preparacion (1-2 dias)

**Objetivo:** Base solida sin romper funcionalidad existente.

| # | Tarea | Archivos |
|---|-------|----------|
| 0.1 | Corregir bug de seed data (chat_seed_data.dart:52) | `chat_seed_data.dart` |
| 0.2 | Deshabilitar botones placeholder (onPressed: null) | Todos los screens |
| 0.3 | Reemplazar strings de estado por enums | `chat_models.dart`, `client_visits_data.dart` |
| 0.4 | Añadir `==` / `hashCode` a modelos de dominio | `chat_models.dart`, `client_visits_data.dart` |

### Fase 1: State Management + DI (3-4 dias)

**Objetivo:** Riverpod como columna vertebral. Eliminar FutureBuilder abuse.

| # | Tarea | Archivos |
|---|-------|----------|
| 1.1 | Añadir `flutter_riverpod` al proyecto | `pubspec.yaml` |
| 1.2 | Crear `ProviderScope` en `main.dart` | `main.dart` |
| 1.3 | Crear providers de repositorio (singleton) | Nuevo: `lib/core/providers/` |
| 1.4 | Crear `AuthNotifier` con usuario actual | Nuevo: `lib/features/auth/domain/` |
| 1.5 | Crear `ActiveVisitNotifier` | Nuevo: `lib/features/visits/domain/` |
| 1.6 | Crear `ChatUnreadNotifier` | Nuevo: `lib/features/chat/domain/` |
| 1.7 | Migrar pantallas a `ConsumerWidget` / `ConsumerStatefulWidget` | Todos los screens |
| 1.8 | Eliminar FutureBuilder de bottom nav bars | 3 screens |
| 1.9 | Eliminar creacion inline de repositorios | 4 screens |

### Fase 2: Routing + Bottom Nav (2-3 dias)

**Objetivo:** GoRouter con ShellRoute. Bottom bar unico.

| # | Tarea | Archivos |
|---|-------|----------|
| 2.1 | Añadir `go_router` al proyecto | `pubspec.yaml` |
| 2.2 | Crear `AppRouter` con todas las rutas | Nuevo: `lib/app/router.dart` |
| 2.3 | Implementar `ShellRoute` con bottom nav compartido | Nuevo: `lib/app/widgets/gardener_shell.dart` |
| 2.4 | Extraer `GardenerBottomNavBar` como widget unico | Nuevo: `lib/app/widgets/bottom_nav_bar.dart` |
| 2.5 | Eliminar bottom nav duplicado de cada pantalla | 3 screens |
| 2.6 | Migrar toda la navegacion imperativa a GoRouter | Todos los screens |
| 2.7 | Implementar restauracion de visita activa en router redirect | `router.dart` |

### Fase 3: Separacion de responsabilidades (3-4 dias)

**Objetivo:** Logica fuera de widgets. Archivos < 500 lineas.

| # | Tarea | Archivos |
|---|-------|----------|
| 3.1 | Extraer `StartVisitUseCase` de `new_visit_screen.dart` | Nuevo: `lib/features/visits/domain/` |
| 3.2 | Extraer `VisitEditingController` de `gardener_visit_details_screen.dart` | Nuevo: `lib/features/visits/domain/` |
| 3.3 | Descomponer `gardener_visit_details_screen.dart` en sub-widgets | Nuevo: `lib/features/visits/presentation/widgets/` |
| 3.4 | Descomponer `chat_with_request_modes_screen.dart` en sub-widgets | Nuevo: `lib/features/chat/presentation/widgets/` |
| 3.5 | Extraer `ChatController` del screen de chat | Nuevo: `lib/features/chat/domain/` |
| 3.6 | Mover logica de formateo/parsing a utils | Nuevo: `lib/core/utils/` |

### Fase 4: Testing (3-4 dias)

**Objetivo:** Cobertura critica de logica de negocio.

| # | Tarea | Archivos |
|---|-------|----------|
| 4.1 | Tests unitarios de `SqliteVisitsRepository` (CRUD + business rules) | Nuevo: `test/features/visits/` |
| 4.2 | Tests unitarios de `StartVisitUseCase` | Nuevo: `test/features/visits/` |
| 4.3 | Tests unitarios de modelos de dominio | Nuevo: `test/features/*/domain/` |
| 4.4 | Widget tests de flujo de nueva visita | Nuevo: `test/features/visits/presentation/` |
| 4.5 | Widget tests de flujo de cliente | Nuevo: `test/features/visits/presentation/` |
| 4.6 | Integration test: crear visita -> fotos -> cerrar -> verificar en historial | Nuevo: `integration_test/` |
| 4.7 | Tests de constraints (visita activa duplicada, etc.) | Nuevo: `test/features/visits/` |

### Fase 5: Polish (2-3 dias)

**Objetivo:** Calidad de produccion.

| # | Tarea | Archivos |
|---|-------|----------|
| 5.1 | Error handling con tipos especificos + Result pattern | Nuevo: `lib/core/errors/` |
| 5.2 | Dark mode | `app_theme.dart` |
| 5.3 | Internacionalizacion (i18n) | Nuevo: `lib/l10n/` |
| 5.4 | Accesibilidad basica (Semantics en screens principales) | Todos los screens |
| 5.5 | Error builders en Image.network | Screens con imagenes |

---

## Orden de ejecucion recomendado

```
Fase 0 (preparacion)
  ↓
Fase 1 (Riverpod) ← Mayor impacto, desbloquea todo lo demas
  ↓
Fase 2 (GoRouter) ← Elimina duplicacion de bottom nav
  ↓
Fase 3 (separacion) ← Hace el codigo testeable
  ↓
Fase 4 (testing) ← Valida que no se ha roto nada
  ↓
Fase 5 (polish) ← Solo si hay tiempo antes de v2
```

**Estimacion total:** ~14-20 dias de trabajo (1 desarrollador)

**Riesgo principal:** Fase 1 (Riverpod) toca todos los archivos. Recomiendo branch dedicado con merge frecuente a main.

---

## Metricas de exito

- [x] 0 `FutureBuilder` en bottom nav bars (Fase 1 — Riverpod chatUnreadProvider)
- [x] 0 repositorios creados en `build()` (Fase 1 — singleton providers)
- [x] 0 archivos > 600 lineas en `presentation/` (Fase 3 — max 533 lineas)
- [x] GoRouter como unico sistema de navegacion (Fase 2 — ShellRoutes)
- [x] Bottom nav bar en un solo lugar (Fase 2 — gardener_shell + client_shell)
- [x] Dark mode (Fase 5 — ThemeMode.system)
- [x] Error handling tipado (Fase 5 — sealed AppError hierarchy)
- [x] 76 tests pasando, 54 nuevos (Fase 4)
- [ ] 0 IDs hardcodeados en screens (parcial — authProvider centraliza, pero quedan fallbacks)
- [ ] Cobertura de tests > 60% en `data/` (SqliteVisitsRepository sin tests por dependencia sqflite)
- [ ] i18n, a11y (Fase 5 pendiente)

## Estado final (8 abril 2026)

Fases 0-5 completadas (5.3-5.5 pendientes). La app tiene Riverpod, GoRouter, widgets decomposed,
76 unit tests, dark mode y error handling tipado. Proximos pasos: i18n, a11y, y tests del
repositorio SQLite (requiere sqflite mock o integration tests).
