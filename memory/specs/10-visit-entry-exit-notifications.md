# Spec 10 — Aviso de Entrada/Salida (Visit Entry/Exit Notifications)

**Status:** Draft  
**Date:** 2026-04-10  
**Scope:** Mobile (cliente) + Supabase backend (Edge Functions + Postgres triggers)

---

## 1. Objetivo

Incrementar la confianza cliente-jardinero notificando al cliente en tiempo real cuando el jardinero inicia y finaliza una visita a su jardín. El cliente puede abrir la app y ver el estado actual de la visita.

---

## 2. Actors

| Actor | Acción |
|---|---|
| Jardinero | Inicia y cierra visitas (comportamiento sin cambios) |
| Cliente | Recibe notificaciones push; ve visita en curso en su pantalla |
| Supabase | Dispara Edge Functions en respuesta a cambios en `visits` |
| FCM (Firebase Cloud Messaging) | Entrega las notificaciones a dispositivos iOS y Android |

---

## 3. Functional Requirements

### FR-01 — Notificación de entrada

- Se envía cuando el jardinero inicia una visita a un jardín cuyo cliente tiene un `device_token` registrado.
- Se envía independientemente de si la visita es verificada o no verificada.
- El contenido varía según el estado de verificación:

| Estado | Texto de la notificación |
|---|---|
| Verificada | `🌿 Visita iniciada — Tu jardinero está en [nombre jardín] desde las HH:MM` |
| No verificada | `⚠️ Visita iniciada (no verificada) — Tu jardinero está en [nombre jardín] desde las HH:MM` |

- Si el dispositivo del cliente estaba offline y la visita **ya está cerrada** cuando se conecta, FCM **no entrega** la notificación de entrada; en su lugar se entrega únicamente la de salida (ver FR-02 y FR-05).

### FR-02 — Notificación de salida

- Se envía cuando el jardinero cierra una visita.
- Contenido: `✅ Visita finalizada — [nombre jardín] · Duración: X h Y min`
- Al tocar esta notificación, la app navega directamente al informe completo de esa visita (`ClientVisitReport`).

### FR-03 — Pantalla de visitas del cliente: línea "Visita en Curso"

- La pantalla `ClientVisitsScreen` muestra una línea fija en la parte superior de la lista cuando existe una visita activa para cualquiera de los jardines del cliente.
- Contenido de la línea:
  - Etiqueta: "Visita en Curso"
  - Hora de entrada (HH:MM)
  - Nombre del jardinero
- La línea **no es tappable** (no navega a ningún detalle).
- Se carga consultando Supabase al abrir la pantalla o al refrescar manualmente.
- Desaparece cuando la visita finaliza, en la siguiente carga de la pantalla (no en tiempo real).

### FR-04 — Solicitud de permisos push (iOS)

- Al entrar por primera vez en `ClientVisitsScreen`, la app solicita permiso del sistema para recibir notificaciones push.
- Solo aplica a usuarios con rol `client`.
- El permiso se solicita una única vez (sistema operativo no repite si ya fue concedido o denegado).

### FR-05 — Lógica de entrega diferida (offline)

- Si el cliente estaba offline durante el inicio de la visita pero la visita ya ha finalizado cuando reconecta:
  - La Edge Function de entrada **comprueba el estado de la visita** antes de enviar a FCM.
  - Si `ended_at IS NOT NULL`, cancela el envío de la notificación de entrada.
  - La notificación de salida se entrega normalmente (FCM la retiene hasta 4 semanas).

### FR-06 — Jardín sin cliente registrado

- Si el jardín visitado no tiene un `client_profile` con `device_token` registrado, no se envía ninguna notificación. Sin error ni log visible al jardinero.

### FR-07 — Transparencia para el jardinero

- El jardinero no recibe ningún feedback de que la notificación fue enviada. El flujo de inicio/cierre de visita no cambia.

---

## 4. Out of Scope (esta iteración)

- Historial de notificaciones enviadas en el web admin.
- Actualización en tiempo real de la línea "Visita en Curso" (Supabase Realtime).
- Notificaciones para el jardinero (ej. confirmación del cliente).
- Soporte para múltiples dispositivos por usuario (el token se registra por sesión activa).
- Notificaciones para usuarios con rol `gardener` o `admin`.

---

## 5. Infraestructura técnica

### 5.1 Stack

| Componente | Tecnología |
|---|---|
| Push delivery | Firebase Cloud Messaging (FCM) |
| iOS bridge | APNs (gestionado automáticamente por FCM) |
| Trigger | Postgres trigger en tabla `visits` |
| Lógica de envío | Supabase Edge Function (Deno/TypeScript) |
| Token storage | Tabla `device_tokens` en Supabase |
| Mobile SDK | `firebase_messaging` (Flutter) |

### 5.2 Tabla `device_tokens`

```sql
CREATE TABLE device_tokens (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token       text NOT NULL,
  platform    text NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);
```

- Se upserta el token cada vez que el cliente abre la app (puede cambiar).
- RLS: el usuario solo puede escribir su propio token; las Edge Functions acceden con service role.

### 5.3 Triggers en `visits`

| Evento | Condición | Edge Function |
|---|---|---|
| `AFTER INSERT` | — | `notify-visit-started` |
| `AFTER UPDATE` | `ended_at` cambia de NULL a valor | `notify-visit-ended` |

### 5.4 Edge Function: `notify-visit-started`

1. Recibe `garden_id`, `gardener_id`, `started_at`, `is_verified`.
2. Consulta `gardens` → `client_profiles` → `device_tokens` para obtener el token del cliente.
3. Si no hay token → return (sin error).
4. **Comprueba si la visita ya está cerrada** (`ended_at IS NOT NULL`) → si sí, return (FR-05).
5. Compone el texto según `is_verified`.
6. Llama FCM API con el token y el payload.

### 5.5 Edge Function: `notify-visit-ended`

1. Recibe `garden_id`, `gardener_id`, `started_at`, `ended_at`.
2. Calcula duración en horas y minutos.
3. Obtiene token del cliente igual que en `notify-visit-started`.
4. Si no hay token → return.
5. Compone texto: `✅ Visita finalizada — [jardín] · Duración: X h Y min`.
6. Añade `data payload` con `visit_id` para que la app navegue al informe al tocar.
7. Llama FCM API.

---

## 6. Cambios en la app Flutter

### 6.1 Nuevas dependencias (`pubspec.yaml`)

```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
```

### 6.2 Registro de token

- Al autenticarse como cliente, obtener el FCM token y hacer upsert en `device_tokens`.
- Escuchar `onTokenRefresh` para actualizar si el token cambia.

### 6.3 Solicitud de permisos

- En `ClientVisitsScreen.initState()`, llamar `FirebaseMessaging.instance.requestPermission()`.
- Solo si el usuario es `client` (guardia por `AuthState.role`).

### 6.4 Gestión de notificaciones recibidas

| Estado de la app | Comportamiento |
|---|---|
| Foreground | Mostrar banner local (usando `flutter_local_notifications` o handler custom) |
| Background / Terminated | FCM entrega la notificación al sistema |
| Usuario toca notificación de salida | Navegar a `ClientVisitReport` con el `visit_id` del payload |
| Usuario toca notificación de entrada | Navegar a `ClientVisitsScreen` |

### 6.5 Línea "Visita en Curso" en `ClientVisitsScreen`

- Al cargar la pantalla, consultar Supabase por visitas activas en los jardines del cliente (`status = 'ACTIVE'`).
- Si existe una, renderizar una card/fila no interactiva en la parte superior de la lista con:
  - Etiqueta "Visita en Curso"
  - Hora de inicio formateada (HH:MM)
  - Nombre del jardinero

---

## 7. Modelo de datos afectado

| Tabla | Cambio |
|---|---|
| `device_tokens` | Nueva tabla |
| `visits` | Nuevos triggers (no cambios de columnas) |
| `gardens` | Sin cambios |
| `client_profiles` | Sin cambios |

---

## 8. Acceptance Criteria

### AC-01 — Notificación de entrada verificada
**Dado** que el jardinero inicia una visita verificada (QR o GPS)  
**Cuando** el jardín tiene un cliente con token registrado  
**Entonces** el cliente recibe: `🌿 Visita iniciada — Tu jardinero está en [jardín] desde las HH:MM`

### AC-02 — Notificación de entrada no verificada
**Dado** que el jardinero inicia una visita manual sin verificación  
**Cuando** el jardín tiene un cliente con token registrado  
**Entonces** el cliente recibe: `⚠️ Visita iniciada (no verificada) — Tu jardinero está en [jardín] desde las HH:MM`

### AC-03 — Notificación de salida
**Dado** que el jardinero cierra una visita  
**Entonces** el cliente recibe: `✅ Visita finalizada — [jardín] · Duración: X h Y min`

### AC-04 — Tap en notificación de salida
**Cuando** el cliente toca la notificación de salida  
**Entonces** la app abre directamente el informe de esa visita

### AC-05 — Tap en notificación de entrada
**Cuando** el cliente toca la notificación de entrada  
**Entonces** la app abre `ClientVisitsScreen`

### AC-06 — Línea "Visita en Curso"
**Dado** que hay una visita activa en un jardín del cliente  
**Cuando** el cliente abre `ClientVisitsScreen`  
**Entonces** aparece una línea no tappable con "Visita en Curso", hora de inicio y nombre del jardinero

### AC-07 — Sin visita activa
**Dado** que no hay visitas activas  
**Entonces** la línea "Visita en Curso" no aparece

### AC-08 — Cliente offline durante la visita completa
**Dado** que el cliente estaba offline durante toda la visita  
**Cuando** reconecta  
**Entonces** solo recibe la notificación de salida (no la de entrada)

### AC-09 — Sin device token
**Dado** que el jardín tiene cliente pero sin token registrado  
**Entonces** no se envía ninguna notificación y el jardinero no ve ningún error

### AC-10 — Solicitud de permisos iOS
**Dado** que el cliente entra por primera vez en `ClientVisitsScreen` en iOS  
**Entonces** el sistema solicita permiso para recibir notificaciones

---

## 9. Dependencias externas

- Cuenta Firebase con proyecto configurado para iOS y Android
- `google-services.json` (Android) y `GoogleService-Info.plist` (iOS) añadidos al proyecto Flutter
- APNs certificate configurado en Firebase Console
- Variable de entorno `FCM_SERVER_KEY` (o Firebase Admin SDK credentials) en Supabase Edge Functions
