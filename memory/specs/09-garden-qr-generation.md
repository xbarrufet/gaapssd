# 09 — Generación de QR de Jardín (Web)

**Estado:** Completado
**Fecha:** 2026-04-10

## Objetivo

Permitir al administrador generar un código QR para cada jardín desde el panel web, para que los jardineros puedan escanearlo con la app móvil al iniciar una visita.

## Decisiones de diseño

| Decisión | Resolución |
|---|---|
| **Contenido QR** | Solo el `gardenId` (UUID, texto plano) |
| **Corrección errores** | Level H (30%) para soportar logo central |
| **Logo** | `logo.png` de GAPPSDD incrustado en el centro |
| **Ubicación botón** | Dentro del dialog de edición del jardín |
| **Disponibilidad** | Solo si el jardín tiene coordenadas GPS |
| **UX** | Modal de previsualización + botón descarga PNG |
| **Formato descarga** | PNG alta resolución |
| **Persistencia** | No se guarda en Supabase (generación bajo demanda) |
| **Librería web** | `react-qrcode-logo` |
| **API backend** | Descartada — generación client-side |
| **Móvil** | Usará `qr_flutter` (ya en deps), implementación futura |

## Flujo de usuario

1. Admin navega a detalle de cliente → lista de jardines
2. Pulsa "Editar" en un jardín que tiene GPS configurado
3. En el dialog de edición aparece un botón "Generar QR"
4. Se abre un modal con el QR renderizado (garden ID + logo GAPPSDD)
5. Admin pulsa "Descargar PNG" → se descarga archivo `qr-{nombre-jardin}.png`
6. Admin puede cerrar el modal y seguir editando

## Componentes

- `garden-dialog.tsx` — Añadir botón "Generar QR" (visible solo con GPS)
- `qr-preview-dialog.tsx` — Nuevo componente: modal con QR + descarga
- `public/logo.png` — Logo GAPPSDD para el centro del QR

## Dependencias

- `react-qrcode-logo` — Generación QR con logo integrado
