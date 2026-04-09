# Technical Specifications: Visit Lifecycle

**Versión:** 1.0  
**Fecha:** 2026-04-08  
**Estado:** Implemented  
**Scope:** Domain logic for visit creation, verification, and closure

---

## 1. Overview

La funcionalidad "Visit Lifecycle" define el ciclo de vida completo de una visita:
- **Creación**: mediante escaneo de QR (verificada) o manualmente (verificada o no verificada según GPS)
- **Apertura y mantenimiento**: única visita activa por jardinero
- **Edición de contenido**: fotos, comentarios y dictado (ver `02-visit-editing.md` para detalles UI)
- **Cierre**: fin de la visita con cálculo automático de duración

Las transacciones se guardan localmente en el dispositivo. La verificación de una visita depende del método de iniciación y la proximidad GPS.

---

## 2. Data Model

### 2.1 Visit Entity

```
Visit {
  id: UUID                          // Generado localmente
  gardenerId: String                // ID del jardinero
  gardenId: String                  // ID del jardín
  clientId: String                  // ID del cliente (extraído del QR)
  status: VisitStatus               // ACTIVE | CLOSED
  verificationStatus: String        // "Visita Verificada" | "Visita No Verificada"
  startTime: DateTime               // Timestamp de entrada
  endTime: DateTime?                // Timestamp de salida (NULL si activa)
  duration: Duration?               // Calculado automáticamente (endTime - startTime)
  initiationMethod: String          // "QR_SCAN" | "MANUAL"
  createdAt: DateTime               // Timestamp de creación en BD local
  updatedAt: DateTime               // Timestamp de última actualización
}
```

### 2.2 QR Content Structure

```
QR Data {
  clientId: String            // ID del cliente propietario del jardín
  gardenId: String            // ID único del jardín
  gps: {
    latitude: Double
    longitude: Double
    accuracy: Double          // En metros
  }
}
```

---

## 3. Business Rules

1. **Una visita activa por jardinero**: Un jardinero solo puede tener una visita `ACTIVE` a la vez.
2. **Desverificación al editar cerradas**: Si una visita `CLOSED` se edita (fotos, comentario), pasa automáticamente a `Visita No Verificada`.
3. **Cálculo de duración**: Se calcula `duration = endTime - startTime` automáticamente.
4. **Restauración con visita activa**: Si la app se abre/restaura con una visita activa, se abre directamente al detalle principal de esa visita, no a la lista histórica.
5. **Verificación por proximidad GPS**: Una visita es `Verificada` si:
   - Se inicia con QR scan **y** el dispositivo está dentro de 10m del QR, **o**
   - Se inicia manualmente **y** el GPS detectó exactamente 1 jardín dentro de 10m (usuario no necesita elegir), **o**
   - Se inicia manualmente **y** el GPS detectó varios jardines dentro de 10m (usuario eligió uno de los candidatos cercanos).
6. **No verificadas por defecto**: Si el inicio manual no detecta jardines cercanos o el GPS no está disponible, la visita es `No Verificada`.

---

## 4. Flujos de Negocio

### 4.0 Restauración de Aplicación con Visita Activa

**Precondiciones:**
- La aplicación se abre desde cero o se restaura desde background

**Flujo:**
1. Sistema carga el estado local de visitas del jardinero actual
2. Sistema busca una visita con `status = ACTIVE`
3. Si existe una visita activa:
   - omite la navegación inicial estándar
   - redirige directamente a la pantalla principal de detalle de la visita
4. Si no existe una visita activa:
   - continúa con el flujo normal de arranque de la aplicación

**Resultado:**
- La visita abierta tiene prioridad sobre la pantalla inicial
- El jardinero retoma inmediatamente la visita en curso
- La restauración siempre aterriza en la vista principal de detalle, no en un subflujo concreto

---

### 4.1 Creación via QR Scan

**Precondiciones:**
- Jardinero pulsa `Nueva Visita` desde la bottom bar raíz
- El dispositivo tiene cámara disponible
- Jardinero no tiene otra visita activa

**Flujo:**
1. Jardinero entra en la pantalla `Nueva Visita`
2. Sistema muestra la cámara para lectura de QR
3. Cámara detecta QR válido
4. Sistema extrae datos del QR (clientId, gardenId, GPS)
5. Sistema valida que el jardín (gardenId) está en la lista de jardines asignados al jardinero
   - Si NO: mostrar error "Jardín no Asignado" y permitir reintentos
   - Si SÍ: continuar
6. Sistema valida proximidad geografica:
   - Calcula distancia entre GPS actual del dispositivo y GPS del QR
   - Si distancia > 10m: mostrar error "No estás suficientemente cerca del jardín"
   - Si distancia ≤ 10m: continuar
7. Sistema crea registro Visit (localmente):
   - initiationMethod = "QR_SCAN"
   - verificationStatus = "Visita Verificada"
   - startTime = ahora
   - endTime = NULL
   - status = ACTIVE
8. Redirige a pantalla de detalle de visita
9. La visita queda editable inmediatamente para fotos, comentario y dictado
10. Iniciar sincronización automática (si hay conectividad)

**Error Handling:**
- Cámara no disponible: mensaje genérico de error
- QR inválido/ilegible: mensaje "QR inválido, intenta de nuevo"
- Fallo de GPS: mensaje "GPS no disponible, valida tu ubicación"
- Distancia > 10m: mensaje "No estás suficientemente cerca del jardín (distancia: Xm)"
- Jardín no asignado: mensaje "Jardín no Asignado"

---

### 4.2 Creación Manual (Sin QR)

**Precondiciones:**
- Jardinero entra en la pantalla `Nueva Visita`
- Jardinero no tiene otra visita activa

**Flujo:**
1. Jardinero presiona el botón de inicio manual dentro de `Nueva Visita`
2. Sistema intenta obtener la posición actual del dispositivo
3. Si la posición está disponible, busca jardines asignados dentro de un radio de 10m
4. Si existe un solo jardín candidato:
   - crea la visita asociada a ese jardín
   - verificationStatus = "Visita Verificada"
5. Si existen varios jardines candidatos:
   - muestra selector con candidatos
   - el usuario elige un jardín
   - crea la visita asociada al jardín elegido
   - verificationStatus = "Visita Verificada"
6. Si no existe ningún jardín candidato:
   - muestra selector con todos los jardines asignados
   - el usuario elige un jardín
   - crea la visita asociada al jardín elegido
   - verificationStatus = "Visita No Verificada"
7. Si el GPS no está disponible:
   - muestra selector con todos los jardines asignados
   - el usuario elige un jardín
   - crea la visita asociada al jardín elegido
   - verificationStatus = "Visita No Verificada"
8. Sistema crea registro Visit (localmente):
   - initiationMethod = "MANUAL"
   - startTime = ahora
   - endTime = NULL
   - status = ACTIVE
9. Redirige a pantalla de detalle de visita
10. La visita queda editable inmediatamente para fotos, comentario y dictado
11. Iniciar sincronización automática (si hay conectividad)

**Error Handling:**
- Si no hay jardines asignados: mostrar mensaje "No tienes jardines asignados"
- Si el GPS falla: permitir continuar con selector manual de jardines asignados

---

### 4.3 Control de Visita Activa Única

**Requisito:** Un jardinero solo puede tener una visita ACTIVE a la vez

**Verificación en entrada Nueva Visita:**
- Si el usuario pulsa `Nueva Visita` y ya existe una visita activa:
  - mostrar aviso: "Ya tienes una visita en progreso"
  - abrir la visita activa en lugar de iniciar un nuevo flujo
  - no permitir crear una segunda visita

**Implementación:**
- En creación: validar que no exista otra visita con status = ACTIVE para ese jardinero
- Si existe: mostrar error y permitir vista de la visita activa para cerrarla

---

### 4.4 Cierre de Visita

**Precondiciones:**
- Hay una visita activa (status = ACTIVE)

**Flujo:**
1. Jardinero en pantalla de detalle de visita presiona botón "End Visit"
2. Sistema muestra confirmación: "¿Cerrar visita?"
3. Usuario confirma
4. Sistema actualiza registro Visit (localmente):
   - endTime = ahora
   - duration = endTime - startTime (calculado automáticamente)
   - status = CLOSED
   - updatedAt = ahora
5. Iniciar sincronización automática (si hay conectividad)
6. Redirige a pantalla de lista de visitas

**Error Handling:**
- Fallo al guardar localmente: reintentar con backoff exponencial

---

## 5. Data Persistence & Synchronization

### 5.1 Local Storage

- **Tecnología:** SQLite (via Flutter local DB package)
- **Ubicación:** Base de datos local del dispositivo
- **Scope:** Solo datos del usuario (jardinero) actual
- **Retención:** Indefinida (hasta sincronización exitosa y limpieza manual)

### 5.2 Synchronization

- **Trigger:** Automático cuando hay conectividad
- **Timeout:** 30 segundos por intento
- **Reintentos:** 3 intentos con backoff exponencial
- **Cambio detectado:** Comparar `updatedAt` local vs. servidor
- **Conflictos:** En caso de conflicto, prevalece la versión local más reciente

---

## 6. UI Requirements

Consultar `03-visit-initiation-screen.md` para los requisitos UI de la pantalla "Nueva Visita".

Consultar `02-visit-editing.md` para los requisitos UI de edición de fotos, comentarios y dictado.
