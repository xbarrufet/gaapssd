# Specs — Índice y Guía de Navegación

> **Nota:** Todos los paths a código (`lib/features/...`) son relativos a `gappsdd_mobile/`.

## Tabla de specs

| # | Título | Estado | Fecha |
|---|--------|--------|-------|
| 01 | [Visit Lifecycle](01-visit-lifecycle.md) | Implemented | 2026-04-08 |
| 02 | [Visit Editing](02-visit-editing.md) | Implemented | 2026-04-08 |
| 03 | [Visit Initiation Screen](03-visit-initiation-screen.md) | Implemented | 2026-04-08 |
| 04 | [Implementation Guide](04-implementation-guide.md) | Implemented | 2026-04-08 |
| 05 | [Identity & Role Model](05-identity-and-role-model.md) | Approved | 2026-04-08 |
| 06 | [Identity/Role SQLite Implementation](06-identity-role-sqlite-implementation-guide.md) | Approved | 2026-04-08 |
| 07 | [Client Visit Screens](07-client-visit-screens.md) | Implemented | 2026-04-08 |
| 08 | [Messaging Screen](08-messaging-screen.md) | In Design | 2026-04-08 |
| 09 | [Garden QR Generation](09-garden-qr-generation.md) | Implemented | 2026-04-10 |
| 10 | [Visit Entry/Exit Notifications](10-visit-entry-exit-notifications.md) | In Design | 2026-04-10 |
| 11 | [Visit Heatmap](11-visit-heatmap.md) | Implemented | 2026-04-13 |

### Estados

- **Implemented** — Spec y código terminados
- **Approved** — Spec aprobada, pendiente de implementar (o implementación parcial)
- **In Design** — En fase de diseño, no implementar aún

## Grafo de dependencias

```
05 Identity Model
 └─► 06 SQLite Implementation (implementa 05)

01 Visit Lifecycle (core)
 ├─► 02 Visit Editing (extiende 01: fotos, comentarios, dictado)
 ├─► 03 Visit Initiation Screen (UI para crear visitas de 01)
 ├─► 04 Implementation Guide (arquitectura para 01 + 02 + 03)
 └─► 07 Client Visit Screens (vista cliente de visitas de 01)

08 Messaging Screen (independiente, futuro)

01 Visit Lifecycle
 ├─► 10 Visit Entry/Exit Notifications (notifica al cliente en inicio/cierre)
 └─► 11 Visit Heatmap (registra posición durante visita, visualiza como mapa de calor)
```

## Convenciones

- Paths a código: relativos a `gappsdd_mobile/` (ej: `lib/features/visits/...`)
- Fechas en headers: ISO 8601 (`2026-04-08`)
- Idioma: mezcla ES/EN según el autor original, código siempre en inglés
