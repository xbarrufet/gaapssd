# Technical Specifications: Messaging Screen

**Versión:** 1.0  
**Fecha:** 8 d'abril del 2026  
**Estado:** In Design  
**Scope:** Client-Gardener messaging interface with approval workflows and document transfer

---

## 1. Overview

La pantalla de mensajes facilita la **comunicación bidireccional entre clientes y jardineros**, permitiendo:

### Core Features
- **Envío de contenido multimedia**: Texto, fotos, documentos
- **Dos modos de envío**:
  1. **Normal**: Mensaje simple sin esperar respuesta
  2. **"Con espera de respuesta"** (Solo jardinero): Requiere acción del cliente mediante botones de aprobación

- **Sistema de respuestas**: Cliente recibe mensaje con opciones de acción (ACEPTAR, RECHAZAR, MÁS INFO)
- **Persistencia**: Todos los mensajes y respuestas se guardan en SQLite local

### Casos de Uso Principales
1. Jardinero envía presupuesto (con espera de respuesta)
2. Cliente aprueba o rechaza presupuesto
3. Cliente solicita más información en presupuesto específico
4. Comunicación de coordinación de visitas
5. Envío de documentos (facturas, reportes)

---

## 2. Data Model

### 2.1 Message Entity

```dart
Message {
  id: UUID                              // Generado localmente
  conversationId: UUID                  // Agrupa mensajes entre 2 usuarios
  senderId: String                      // ID del remitente (gardener o client)
  recipientId: String                   // ID del destinatario
  senderRole: String                    // "GARDENER" | "CLIENT"
  contentType: String                   // "TEXT" | "IMAGE" | "DOCUMENT"
  content: String                       // Texto del mensaje
  
  // Multimedia (si contentType != "TEXT")
  mediaUrl: String?                     // Ruta local del archivo
  mediaFileName: String?                // Nombre original del archivo
  mediaMimeType: String?                // "image/jpeg", "application/pdf", etc.
  
  // Metadatos
  createdAt: DateTime                   // Timestamp de creación
  isRead: Boolean                       // Leído por el recipiente
  readAt: DateTime?                     // Timestamp de lectura
  
  // Solo si sendMode = "WITH_RESPONSE"
  requiresResponse: Boolean              // Indica si espera respuesta
  responseRequired: Boolean              // Duplicado lógico (redundante para queries)
}
```

### 2.2 MessageResponse Entity

```dart
MessageResponse {
  id: UUID                              // Generado localmente
  messageId: UUID                       // Referencia al Message original
  conversationId: UUID                  // Referencia a Conversation
  responderId: String                   // ID de quien responde (siempre cliente)
  responderRole: String                 // "CLIENT"
  
  // Acción principal
  action: String                        // "ACCEPT" | "REJECT" | "MORE_INFO"
  
  // Si action = "MORE_INFO"
  additionalMessage: String?            // Mensaje de texto escrito por cliente
  
  // Metadatos
  createdAt: DateTime                   // Timestamp de respuesta
  updatedAt: DateTime?                  // Timestamp de edición (si aplica)
}
```

### 2.3 Conversation Entity

```dart
Conversation {
  id: UUID                              // Generado localmente
  gardener1Id: String                   // ID del jardinero
  clientId: String                      // ID del cliente
  
  // Contexto (opcional pero recomendado)
  visitId: UUID?                        // Si la conversación está ligada a una visita
  gardenId: String?                     // ID del jardín
  
  // Estado
  status: String                        // "ACTIVE" | "ARCHIVED"
  lastMessageAt: DateTime               // Última actividad
  unreadMessageCount: Integer           // Contador de no leídos para el usuario actual
  
  // Metadatos
  createdAt: DateTime
  updatedAt: DateTime
}
```

---

## 3. Business Rules

### 3.1 Send Modes

1. **Normal Mode**
   - Disponible para ambos roles (Cliente y Jardinero)
   - El mensaje se envía sin esperar respuesta
   - `requiresResponse` = `false`
   - El recipiente lo ve pero no tiene obligación de actuar

2. **"Con espera de respuesta" Mode**
   - **Solo disponible para Jardinero**
   - Se activa manteniendo presionado el botón de envío (long-press)
   - Crea un `Message` con `requiresResponse` = `true`
   - El cliente verá el mensaje con 3 botones: **ACEPTAR**, **RECHAZAR**, **MÁS INFO**
   - El mensaje se marca como "pendiente de respuesta" visualmente hasta que el cliente responda

### 3.2 Responses

1. **ACEPTAR**
   - Crea un `MessageResponse` con `action` = "ACCEPT"
   - El jardinero ve visualmente que fue aceptado (check mark, color verde)
   - No requiere más texto

2. **RECHAZAR**
   - Crea un `MessageResponse` con `action` = "REJECT"
   - El jardinero ve visualmente que fue rechazado (X, color rojo)
   - No requiere más texto

3. **MÁS INFO**
   - Crea un `MessageResponse` con `action` = "MORE_INFO"
   - Abre un cuadro de texto para que el cliente escriba su pregunta/comentario
   - La respuesta se guarda en `additionalMessage`
   - Después de enviar, el cuadro se cierra y el jardinero ve "Solicitó más info"

### 3.3 Persistence Rules

1. Todos los mensajes se guardan en SQLite **al momento de envío**
2. Las respuestas se guardan en SQLite **al momento de responder**
3. Los estados de lectura se actualizan cuando el usuario abre la conversación
4. No hay sincronización remota en v1 (datos locales únicamente)

### 3.4 Visibility Rules

1. **Para el remitente**: Ve el mensaje con indicador de estado (enviado, leído)
2. **Para el recipiente**: 
   - Si `requiresResponse = false`: Lo ve como mensaje normal
   - Si `requiresResponse = true`: Lo ve con los 3 botones de acción debajo
3. **Conversación activa**: Se marca como no leída hasta que el recipiente la abra
4. **Contador de no leídos**: Se decrementa cuando el usuario abre la conversación

---

## 4. UI/UX Flows

### 4.1 Sending a Message (Normal Mode)

**Precondiciones:**
- Usuario está en la pantalla de chat de una conversación

**Flujo:**
1. Usuario escribe texto en el campo de entrada
2. Usuario toca el botón de envío (tap normal)
3. Sistema crea un `Message` con:
   - `contentType` = "TEXT" (o IMAGEN/DOCUMENTO según contenido)
   - `requiresResponse` = `false`
   - `senderId` = usuario actual
   - `createdAt` = ahora
4. Mensaje aparece en el chat con indicador "Enviado"
5. Campo de entrada se limpia

### 4.2 Sending a Message with Response Expected (Long-Press Mode)

**Precondiciones:**
- Usuario es Jardinero
- Usuario está en pantalla de chat

**Flujo:**
1. Usuario escribe texto en el campo de entrada
2. Usuario **mantiene presionado el botón de envío** (long-press >= 500ms)
3. Se muestra una confirmación visual: "Enviando con espera de respuesta..."
4. Sistema crea un `Message` con:
   - `requiresResponse` = `true`
   - Resto igual a Normal Mode
5. Mensaje aparece en el chat con indicador especial (ej: "⏳ Esperando respuesta")
6. Campo de entrada se limpia
7. El mensaje en el chat del **cliente** aparece con los 3 botones debajo

### 4.3 Client Receiving Message with Response Required

**Precondiciones:**
- Cliente abre conversación o recibe notificación
- Hay un mensaje no respondido con `requiresResponse = true`

**UI:**
```
┌─────────────────────────────────┐
│ Jardinero: 14:32                │
│ Presupuesto: €250 para poda     │
│ [ACEPTAR] [RECHAZAR] [MÁS INFO]│
└─────────────────────────────────┘
```

**Interacciones:**

**a) ACEPTAR (tap)**
- Sistema crea `MessageResponse`: `action` = "ACCEPT"
- Los 3 botones desaparecen, se muestra: ✓ Aceptado
- En el chat del jardinero, el mensaje se marca como aceptado

**b) RECHAZAR (tap)**
- Sistema crea `MessageResponse`: `action` = "REJECT"
- Los 3 botones desaparecen, se muestra: ✗ Rechazado
- En el chat del jardinero, el mensaje se marca como rechazado

**c) MÁS INFO (tap)**
- Se abre un modal/sheet con:
  - Texto: "¿Qué información adicional necesitas?"
  - Campo de texto de entrada
  - Botón "Enviar"
- Usuario escribe su pregunta (ej: "¿Puedes usar abono químico?")
- Usuario toca "Enviar"
- Sistema crea `MessageResponse`: `action` = "MORE_INFO", `additionalMessage` = texto escrito
- Modal se cierra, el mensaje muestra: "📝 Solicitó más información"
- En el jardinero, aparece la pregunta adicional en el chat

### 4.4 Viewing Conversation List

**UI Elements:**
- Lista de conversaciones ordenadas por `lastMessageAt` (más recientes arriba)
- Para cada conversación:
  - Nombre del otro usuario (cliente o jardinero)
  - Último mensaje (preview del contenido)
  - Timestamp (`2h ago`, `3 days`, etc.)
  - Badge rojo si hay mensajes no leídos
  - Subrayado/resaltado si tiene mensajes pendientes de respuesta

### 4.5 Opening a Conversation

**Precondiciones:**
- Usuario selecciona una conversación de la lista

**Acciones:**
1. Se abre la pantalla de chat
2. Se cargan todos los mensajes de esa conversación
3. Se marcan como leídos: `isRead = true`, `readAt = ahora`
4. El contador de no leídos se actualiza a 0
5. Los mensajes se muestran en orden cronológico (más antiguos arriba)
6. Se scrollea al último mensaje automáticamente
7. En la **zona de info del contacto** (avatar + nombre en la cabecera):
   - Se muestra el nombre y avatar del contacto actual
   - Si la conversación tiene/tenía mensajes no leídos, se muestra un **punto rojo pequeño** en la esquina superior derecha del avatar
   - Esta zona es **interactable** (tapeable) para abrir el desplegable de contactos

### 4.6 Switching Contact (Bottom Sheet)

**Precondiciones:**
- Usuario está en la pantalla de chat
- Usuario toca la zona de info del contacto (avatar + nombre)

**Acciones:**
1. Se abre un **BottomSheet** con lista de contactos
2. La lista está **ordenada por último mensaje (más reciente arriba)**
3. Para cada contacto se muestra:
   - Avatar circular
   - Nombre del contacto
   - Last message preview (texto corto)
   - **Punto rojo** en la esquina superior derecha del avatar **si tiene mensajes sin leer**
   - Timestamp del último mensaje
4. Usuario toca un contacto diferente
5. **BottomSheet se cierra automáticamente**
6. La pantalla de chat se recarga con la nueva conversación
7. Los mensajes de la nueva conversación se marcan como leídos
8. La zona de info se actualiza con el nuevo contacto

---

## 5. Database Schema (SQLite)

### 5.1 Messages Table

```sql
CREATE TABLE messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  recipient_id TEXT NOT NULL,
  sender_role TEXT NOT NULL CHECK(sender_role IN ('GARDENER', 'CLIENT')),
  content_type TEXT NOT NULL CHECK(content_type IN ('TEXT', 'IMAGE', 'DOCUMENT')),
  content TEXT,
  
  -- Multimedia
  media_url TEXT,
  media_file_name TEXT,
  media_mime_type TEXT,
  
  -- Metadata
  created_at TEXT NOT NULL,
  is_read INTEGER DEFAULT 0,
  read_at TEXT,
  requires_response INTEGER DEFAULT 0,
  
  -- Foreign keys
  FOREIGN KEY (conversation_id) REFERENCES conversations(id)
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_recipient ON messages(recipient_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
```

### 5.2 MessageResponses Table

```sql
CREATE TABLE message_responses (
  id TEXT PRIMARY KEY,
  message_id TEXT NOT NULL,
  conversation_id TEXT NOT NULL,
  responder_id TEXT NOT NULL,
  responder_role TEXT NOT NULL CHECK(responder_role IN ('CLIENT')),
  action TEXT NOT NULL CHECK(action IN ('ACCEPT', 'REJECT', 'MORE_INFO')),
  additional_message TEXT,
  
  created_at TEXT NOT NULL,
  updated_at TEXT,
  
  FOREIGN KEY (message_id) REFERENCES messages(id),
  FOREIGN KEY (conversation_id) REFERENCES conversations(id)
);

CREATE INDEX idx_responses_message ON message_responses(message_id);
CREATE INDEX idx_responses_conversation ON message_responses(conversation_id);
```

### 5.3 Conversations Table

```sql
CREATE TABLE conversations (
  id TEXT PRIMARY KEY,
  gardener_id TEXT NOT NULL,
  client_id TEXT NOT NULL,
  
  -- Context
  visit_id TEXT,
  garden_id TEXT,
  
  -- Status
  status TEXT DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE', 'ARCHIVED')),
  last_message_at TEXT,
  unread_message_count INTEGER DEFAULT 0,
  
  -- Metadata
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  
  UNIQUE(gardener_id, client_id)
);

CREATE INDEX idx_conversations_gardener ON conversations(gardener_id);
CREATE INDEX idx_conversations_client ON conversations(client_id);
```

---

## 6. Implementation Notes

### 6.1 UI Components Required

1. **MessageBubble Widget**
   - Renderiza mensajes con diferente alineación (izquierda/derecha)
   - Soporte para texto, imágenes, documentos
   - Indicadores de estado (enviado, leído, pendiente)

2. **ResponseButtonGroup Widget**
   - Muestra 3 botones (ACEPTAR, RECHAZAR, MÁS INFO)
   - Desaparece después de responder
   - Muestra estado final (✓, ✗, 📝)

3. **MessageInputField Widget**
   - Campo de texto con botón de envío
   - Long-press detector en botón de envío
   - Soporte para adjuntar imágenes/documentos

4. **ConversationListScreen**
   - Lista de conversaciones
   - Badges de no leídos
   - Ordenamiento por fecha

5. **ChatScreen**
   - Renderiza todos los mensajes de una conversación
   - Scroll automático al último mensaje
   - Manejo de teclado virtual
   - **Cabecera con zona de info:** Avatar + nombre del contacto actual
     - Tappable para abrir ContactSwitcherBottomSheet
     - Muestra punto rojo si la conversación tiene no leídos

6. **ContactSwitcherBottomSheet Widget**
   - BottomSheet que lista contactos (máx 10)
   - Ordenado por `lastMessageAt` (más recientes arriba)
   - Para cada contacto:
     - Avatar con punto rojo si `unreadMessageCount > 0`
     - Nombre
     - Preview del último mensaje
     - Timestamp relativo ("2h ago", "3 days", etc.)
   - Tap en un contacto → cierra automáticamente y carga nueva conversación
   - Tap en contacto actual → cierra sin cambiar

### 6.2 State Management

1. **ConversationProvider / ViewModel**
   - Carga lista de conversaciones
   - Maneja creación de nuevas conversaciones
   - Actualiza contadores de no leídos

2. **ChatProvider / ViewModel**
   - Carga mensajes de una conversación específica
   - Envía nuevos mensajes
   - Gestiona respuestas
   - Marca como leídos

### 6.3 Media Handling

1. **Imágenes**:
   - Guardadas en directorio local (ex: `app_documents/messages/images/`)
   - Compresión automática antes de guardar
   - Thumbnail para preview en lista

2. **Documentos**:
   - Guardados en directorio local (ex: `app_documents/messages/documents/`)
   - Icono según tipo (PDF, Word, etc.)
   - Nombre de archivo visible

### 6.4 Notifications (Future)

- Local notifications cuando se recibe un mensaje no leído
- Local notifications cuando se recibe una respuesta a un mensaje pendiente
- (Sincronización push en v2+)

---

## 7. Acceptance Criteria

- [ ] Jardinero puede enviar mensaje en modo normal
- [ ] Jardinero puede enviar mensaje con espera de respuesta (long-press)
- [ ] Cliente ve botones ACEPTAR, RECHAZAR, MÁS INFO en mensaje con respuesta requerida
- [ ] Cliente puede aceptar/rechazar en 1 tap
- [ ] Cliente puede escribir pregunta adicional en "MÁS INFO"
- [ ] Jardinero ve las respuestas del cliente en tiempo real (local)
- [ ] Todos los mensajes y respuestas se guardan en SQLite
- [ ] Las conversaciones se ordenan por última actividad
- [ ] Los contadores de no leídos funcionan correctamente
- [ ] Se pueden adjuntar imágenes a mensajes
- [ ] Se pueden adjuntar documentos a mensajes
- [ ] Los estados finales (✓, ✗, 📝) se muestran correctamente
- [ ] Cabecera del chat muestra avatar + nombre del contacto actual
- [ ] Punto rojo aparece en avatar del contacto actual si tiene no leídos
- [ ] Tocar zona de info del contacto abre BottomSheet
- [ ] BottomSheet lista hasta 10 contactos ordenados por último mensaje
- [ ] Cada contacto en BottomSheet muestra avatar, nombre, preview, timestamp
- [ ] Punto rojo aparece en avatar de contactos con mensajes sin leer
- [ ] Seleccionar contacto en BottomSheet cierra automáticamente
- [ ] Seleccionar contacto diferente carga la nueva conversación
- [ ] Los mensajes de nueva conversación se marcan como leídos

---

## 8. Related Specs

- [01-visit-lifecycle.md](01-visit-lifecycle.md) — Context de visitas puede estar ligado a conversaciones
- [05-identity-and-role-model.md](05-identity-and-role-model.md) — Roles (GARDENER, CLIENT) usados en visibilidad
- [07-client-visit-screens.md](07-client-visit-screens.md) — Cliente puede iniciar chat desde pantalla de visita

---

## Changelog

| Versión | Fecha       | Cambios |
|---------|-------------|---------|
| 1.1     | 8-abr-2026  | Agregado BottomSheet para cambio de contactos con punto rojo de no leídos |
| 1.0     | 8-abr-2026  | Especificación inicial con datos completos, flujos UI, y schema SQLite |
