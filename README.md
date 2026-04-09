# GAPP — Garden Application

Aplicación para conectar empresas de jardinería con sus clientes mediante verificación de visitas, documentación fotográfica y comunicación directa.

## Estructura

| Directorio | Descripción | Tech |
|---|---|---|
| `gappsdd_mobile/` | App móvil (jardinero + cliente) | Flutter / Dart |
| `gappsdd_web/` | Panel admin (gestión de usuarios) | Next.js / TypeScript |
| `memory/` | Specs, diseños, documentación | Markdown |

## Quick Start

### Mobile
```bash
cd gappsdd_mobile
flutter pub get
flutter run
```

### Web Admin
```bash
cd gappsdd_web
npm install
npm run dev
```

## Documentación

- [BLUEPRINT.md](BLUEPRINT.md) — Visión general, features, roadmap
- [CLAUDE.md](CLAUDE.md) — Instrucciones para desarrollo con Claude Code
- [memory/specs/](memory/specs/) — Especificaciones técnicas
