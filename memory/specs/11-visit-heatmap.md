# Spec 11 — Visit Heatmap (Location Tracking + Activity Map)

**Status:** Implemented  
**Date:** 2026-04-13  
**Scope:** Mobile (jardinero) + Supabase backend

---

## 1. Objetivo

Registrar la posición GPS del jardinero periódicamente durante una visita activa y visualizarla como un mapa de calor (heatmap) una vez cerrada la visita. El heatmap muestra qué zonas del jardín han recibido más atención, diferenciando densidad de trabajo por color (amarillo → rojo).

---

## 2. Actors

| Actor | Acción |
|---|---|
| Jardinero | Inicia visita → la app recoge su posición cada 30 s automáticamente |
| Jardinero | Accede al heatmap desde el detalle de una visita cerrada |
| Cliente | Accede al heatmap desde el informe de visita |
| Supabase | Almacena los puntos GPS en `visit_location_points` |

---

## 3. Functional Requirements

### FR-01 — Recogida de posición durante visita activa

- La app solicita permiso de localización **"When In Use"** en el momento en que se carga la pantalla de detalle de una visita activa.
- Si el permiso se deniega, la recogida no se inicia y no se muestra error al usuario (silent fail).
- La posición se lee cada **30 segundos** a precisión alta.
- Si una lectura GPS falla (timeout 10 s, GPS no disponible), se omite ese punto sin error visible.
- La recogida se detiene automáticamente:
  - Al cerrar la visita (botón "Cerrar").
  - Al salir de la pantalla de detalle (`dispose`).
- Solo se recogen puntos para visitas con `status = ACTIVE` y con `id` resuelto desde Supabase (no en modo offline/SQLite).

### FR-02 — Almacenamiento de puntos

Cada punto GPS se guarda en Supabase con:
- `visit_id` — FK a `visits.id`
- `lat`, `lng` — coordenadas WGS-84 (double precision)
- `accuracy` — precisión en metros (nullable)
- `recorded_at` — timestamp UTC (default `now()`)

### FR-03 — Pantalla de Heatmap

- Accesible desde:
  - **Jardinero:** botón "Mapa de Actividad" en `GardenerVisitDetailsScreen`, visible **solo** cuando la visita está cerrada (`selectedVisitId != null`).
  - **Cliente:** botón "Mapa de Actividad" en `VisitReportScreen`, siempre visible.
- La pantalla es **solo lectura**. No permite edición de datos.
- Carga los puntos GPS de la visita seleccionada desde Supabase.
- Estado vacío: si no hay puntos, muestra icono y texto "No hay datos de ubicación para esta visita".
- El mapa se auto-ajusta (zoom + centro) para encuadrar todos los puntos con padding de 60 dp.
- El mapa es **interactivo**: el usuario puede hacer zoom y pan libremente.

### FR-04 — Densidad y colores

- Para cada punto se calcula la densidad local: número de otros puntos a ≤ 15 m de radio (Haversine).
- Se normaliza la densidad al máximo de la visita → valor `t ∈ [0, 1]`.
- Color resultante vía HSV: hue `60° × (1 − t)` (60° = amarillo, 0° = rojo), alpha `0.30 + 0.45 × t`.
- Todos los puntos se renderizan como círculos de 15 m de radio real sobre el mapa.
- Si solo hay 1 punto → densidad 0 → círculo amarillo.

### FR-05 — Proveedor de mapas

- Mapa base: OpenStreetMap (tiles `https://tile.openstreetmap.org/{z}/{x}/{y}.png`).
- Sin API key ni coste. User-Agent declarado: `com.gapp.gappsdd`.
- Alternativa futura: Mapbox o Google Maps si se requiere estilo personalizado.

---

## 4. Non-Functional Requirements

### NFR-01 — App Store (iOS)

- Permiso utilizado: `NSLocationWhenInUseUsageDescription` únicamente.
- **No** se declara `NSLocationAlwaysUsageDescription` ni `UIBackgroundModes: location`.
- Justificación en Info.plist: "GAPP registra tu posición durante la visita activa para generar un mapa de zonas trabajadas en el jardín."
- La recogida ocurre exclusivamente mientras la visita está activa y la app está en primer plano. Este modelo es trivialmente aprobable por Apple.

### NFR-02 — Batería

- Intervalo de 30 s es el sweet-spot para jardines (100–1000 m²): suficiente densidad de puntos con impacto mínimo en batería.
- Cada lectura tiene timeout de 10 s para evitar bloqueos de GPS.

### NFR-03 — Modo offline / SQLite

- `SqliteVisitsRepository.recordLocationPoint` y `loadVisitLocationPoints` son stubs no-op / vacíos.
- El tracking de posición solo se activa cuando `_visit.id != null` (resuelto desde Supabase).

---

## 5. Data Model

### Supabase: `visit_location_points`

```sql
create table public.visit_location_points (
  id          uuid default gen_random_uuid() primary key,
  visit_id    uuid references public.visits(id) on delete cascade not null,
  lat         double precision not null,
  lng         double precision not null,
  accuracy    double precision,         -- metres, nullable
  recorded_at timestamptz default now() not null
);
```

**Índices:** `visit_id`, `recorded_at`

**RLS:**
| Rol | Operación | Condición |
|---|---|---|
| Jardinero | ALL | `visit_id` pertenece a sus visitas (`my_gardener_id()`) |
| Cliente | SELECT | `visit_id` pertenece a visitas de sus jardines (`my_client_id()`) |
| Admin | ALL | `is_admin()` |

### Domain: `VisitLocationPoint`

```dart
class VisitLocationPoint {
  final String visitId;
  final double lat;
  final double lng;
  final double? accuracy;
  final DateTime recordedAt;
}
```

### Domain: `ActiveVisitSnapshot.id`

Se añade campo `id: String?` a `ActiveVisitSnapshot` — resuelto desde Supabase en `loadActiveVisit` y `_startVisit`. Null en FakeVisitsRepository y SqliteVisitsRepository.

---

## 6. Architecture

### Servicio: `LocationTracker`

```
lib/features/visits/data/location_tracker.dart
```

- Clase pura Dart, sin Riverpod.
- Lifecycle: creado en `_GardenerVisitDetailsScreenState`, disposed en `dispose()` y al cerrar visita.
- API:
  - `start() → Future<bool>` — solicita permiso, inicia Timer cada 30 s, lectura inmediata.
  - `stop()` — cancela Timer.
  - `isRunning` — getter de estado.

### Repositorio

| Método | SupabaseRepo | SqliteRepo | FakeRepo |
|---|---|---|---|
| `recordLocationPoint(visitId, lat, lng, accuracy?)` | INSERT en `visit_location_points` | No-op | No-op |
| `loadVisitLocationPoints(visitId)` | SELECT ordenado por `recorded_at` | `[]` | 10 puntos fake en Barcelona |

### Pantalla

```
lib/features/visits/presentation/visit_heatmap_screen.dart
```

Ruta: `/visit-heatmap` (GoRouter, `parentNavigatorKey: rootNavigatorKey`).  
Entrada: `state.extra as String` → `visitId`.

Flujo:
```
initState → loadVisitLocationPoints(visitId)
  └─ empty → EmptyState widget
  └─ points →
       _buildCircles(points)       — calcula densidad + color
       _fitCamera(latLngs)         — CameraFit.coordinates + padding 60dp
       FlutterMap
         ├─ TileLayer (OSM)
         └─ CircleLayer(circles)
```

---

## 7. Files Modified / Created

| Archivo | Cambio |
|---|---|
| `pubspec.yaml` | `geolocator: ^13.0.2`, `flutter_map: ^7.0.2`, `latlong2: ^0.9.1` |
| `android/app/src/main/AndroidManifest.xml` | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |
| `ios/Runner/Info.plist` | `NSLocationWhenInUseUsageDescription` |
| `supabase/schema.sql` | Tabla `visit_location_points` + RLS + índices |
| `lib/features/visits/domain/client_visits_data.dart` | `VisitLocationPoint` model; `id: String?` en `ActiveVisitSnapshot` |
| `lib/features/visits/data/visits_repository.dart` | `recordLocationPoint`, `loadVisitLocationPoints` abstractos + stubs Fake |
| `lib/features/visits/data/supabase_visits_repository.dart` | Implementaciones reales; `id` poblado en `loadActiveVisit` y `_startVisit` |
| `lib/features/visits/data/sqlite_visits_repository.dart` | Stubs no-op / vacíos |
| `lib/features/visits/data/location_tracker.dart` | **NUEVO** — Timer 30 s, permisos, lectura GPS |
| `lib/features/visits/presentation/visit_heatmap_screen.dart` | **NUEVO** — Pantalla heatmap completa |
| `lib/app/router.dart` | Ruta `/visit-heatmap` + constante `AppRoutes.visitHeatmap` |
| `lib/features/visits/presentation/gardener_visit_details_screen.dart` | Botón "Mapa de Actividad" (visitas cerradas) + integración `LocationTracker` |
| `lib/features/visits/presentation/visit_report_screen.dart` | Botón "Mapa de Actividad" |

---

## 8. Open Questions / Future Work

- **Heatmap acumulado:** mostrar todos los puntos históricos de un jardín (todas las visitas) en lugar de solo la visita actual. Requiere query distinta y toggle en UI.
- **Visualización avanzada:** gaussian blur real (librería `heatmap_flutter` o CustomPainter con `MaskFilter`), actualmente se usa superposición de círculos semi-transparentes.
- **Límite de puntos:** una visita de 8 h a 30 s de intervalo = ~960 puntos. La densidad O(n²) es aceptable para este volumen; si se supera ~5.000 puntos considerar grid-based aggregation.
- **Precisión GPS:** en jardines interiores o con mala cobertura, considerar filtrar puntos con `accuracy > 30 m`.
