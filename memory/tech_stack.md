# Technology Stack

**Última actualización:** 2026-04-09

## Estructura: Monorepo

| App | Directorio | Framework |
|-----|-----------|-----------|
| Mobile (jardinero + cliente) | `gappsdd_mobile/` | Flutter (Dart) |
| Web admin (gestión usuarios) | `gappsdd_web/` | Next.js 16 (TypeScript) |

## Mobile — `gappsdd_mobile/`

- **Framework:** Flutter, Dart SDK ^3.11.4
- **Estado:** Riverpod (`flutter_riverpod ^2.6.1`)
- **Routing:** GoRouter (`go_router ^14.8.1`)
- **Persistencia local:** SQLite (`sqflite ^2.4.2`)
- **Voz:** `speech_to_text ^7.1.0`
- **Tipografía:** Google Fonts (Manrope + Work Sans)
- **Otros:** `uuid`, `qr_flutter`

## Web Admin — `gappsdd_web/`

- **Framework:** Next.js 16 (App Router, TypeScript)
- **UI:** Tailwind CSS v4 + shadcn/ui
- **Tablas:** @tanstack/react-table
- **Formularios:** react-hook-form + zod
- **Tema:** next-themes (dark mode via system)
- **Tipografía:** Manrope + Work Sans via next/font/google

## Backend (v1: NO implementado)

- **Datos locales:** SQLite en mobile, datos mock en web
- **Futuro:** Supabase o Java Spring + BBDD relacional
- **Sincronización remota:** Pendiente para v2

## Diseño visual

Tema compartido **Arbor Ethos** en ambas apps:
- Primary: forest green (#17340E / #A8D398 dark)
- Surface: cream (#FCF9F0 / #1A1C16 dark)
- Ver detalle completo en `sample designs/arbor_ethos/DESIGN.md`
