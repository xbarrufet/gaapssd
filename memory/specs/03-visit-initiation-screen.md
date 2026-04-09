# Technical Specifications: Nueva Visita (Visit Initiation Screen)

**Versión:** 1.0  
**Fecha:** 2026-04-08  
**Estado:** Implemented  
**Scope:** UI/UX specification for the "Nueva Visita" screen and QR initiation flow

---

## 1. Objetivo

La pantalla `Nueva Visita` es la entrada operativa para iniciar una visita desde la navegación principal del jardinero. Su función es permitir:

1. iniciar una visita verificada mediante lectura de QR
2. iniciar una visita desde un flujo manual asistido por GPS
3. resolver el conflicto cuando ya existe una visita activa

Esta pantalla se abre desde el botón central `Nueva Visita` de la bottom bar raíz del jardinero.

La lógica de dominio subyacente se define en `01-visit-lifecycle.md`.

---

## 2. Posición en la Navegación

### 2.1 Entrada

- origen: bottom bar del jardinero
- acción: tap en `Nueva Visita`
- icono: cámara
- tamaño visual: aproximadamente el doble que el resto de items de la bottom bar

### 2.2 Comportamiento visual

- la pantalla `Nueva Visita` se abre en modo cámara a pantalla completa
- no debe mostrar la bottom bar de 5 elementos
- debe incluir un botón visible de cancelar/vuelta
- al cancelar, vuelve a la pestaña `Visita`

---

## 3. Scope de v1

**Incluye:**
- vista de cámara para escanear QR
- lectura de QR de jardines
- validación local de jardín asignado
- validación de proximidad para QR
- botón de inicio manual siempre visible
- inicio manual asistido por GPS
- selector de jardines cuando aplique
- manejo de visita activa existente
- mensajes de error y fallback a flujo manual

**No incluye:**
- cambio de cámara
- flash
- zoom manual
- instrucciones contextuales avanzadas
- guía visual compleja de escaneo

---

## 4. Business Rules

1. Solo puede existir una visita `ACTIVE` por jardinero.
2. Si el jardinero pulsa `Nueva Visita` teniendo una visita activa, el sistema debe avisar y abrir la visita activa.
3. El escaneo QR puede crear únicamente visitas verificadas.
4. El inicio manual puede crear visitas verificadas o no verificadas según proximidad GPS.
5. Si el inicio manual detecta exactamente un jardín asignado dentro de 10m, la visita será verificada.
6. Si el inicio manual detecta varios jardines asignados dentro de 10m, el usuario debe elegir uno y la visita será verificada.
7. Si el inicio manual no detecta jardines dentro de 10m, el usuario elige de la lista de jardines asignados y la visita será no verificada.
8. Si el GPS no está disponible en el inicio manual, el usuario elige de la lista de jardines asignados y la visita será no verificada.
9. Si la cámara no está disponible, el botón de inicio manual sigue operativo.
10. El resultado de una creación exitosa siempre navega al detalle principal de la visita.

---

## 5. Flujos de Usuario

### 5.1 Entrada con visita activa existente

**Precondiciones:**
- existe una visita `ACTIVE`

**Flujo:**
1. Usuario pulsa `Nueva Visita`
2. Sistema consulta `loadActiveVisit()`
3. Sistema detecta la visita activa
4. Sistema muestra aviso: `Ya tienes una visita activa`
5. Sistema navega al detalle principal de esa visita

**Resultado:**
- no se abre un nuevo flujo de creación

### 5.2 Inicio por QR

**Precondiciones:**
- no existe visita activa
- la cámara está disponible

**Flujo:**
1. Usuario entra en `Nueva Visita`
2. Sistema abre la cámara
3. Usuario apunta al QR del jardín
4. Sistema detecta y parsea el QR
5. Sistema obtiene `clientId`, `gardenId` y coordenadas del QR
6. Sistema valida que el jardín está asignado al jardinero
7. Sistema obtiene la posición actual del dispositivo
8. Sistema calcula distancia entre QR y dispositivo
9. Si la distancia es menor o igual a 10m:
   - crea visita verificada
10. Sistema navega al detalle principal de la visita

### 5.3 Inicio manual asistido por GPS

**Precondiciones:**
- no existe visita activa

**Flujo:**
1. Usuario pulsa el botón `Inicio Manual`
2. Sistema intenta obtener la posición del dispositivo
3. Sistema busca jardines asignados dentro de 10m

**Caso A: un único candidato**
4. Si hay exactamente un jardín candidato:
   - crea visita verificada con ese jardín
   - navega al detalle principal

**Caso B: varios candidatos**
5. Si hay varios jardines candidatos:
   - muestra selector con candidatos cercanos
   - usuario selecciona uno
   - crea visita verificada con el jardín seleccionado
   - navega al detalle principal

**Caso C: ningún candidato**
6. Si no hay jardines candidatos:
   - muestra selector con todos los jardines asignados
   - usuario selecciona uno
   - crea visita no verificada
   - navega al detalle principal

**Caso D: GPS no disponible**
7. Si el GPS no está disponible:
   - muestra selector con todos los jardines asignados
   - usuario selecciona uno
   - crea visita no verificada
   - navega al detalle principal

### 5.4 Cancelación

1. Usuario pulsa `Cancelar` o vuelve atrás
2. Sistema cierra la pantalla `Nueva Visita`
3. Sistema vuelve a la pestaña `Visita`

---

## 6. Validaciones y Errores

| Validación | Trigger | Acción |
|---|---|---|
| Existe visita activa | Entrada en Nueva Visita | Aviso + abrir visita activa |
| QR inválido o ilegible | Escaneo QR | Error: `QR inválido, intenta de nuevo` |
| Jardín no asignado | Escaneo QR | Error: `Jardín no Asignado` |
| Distancia > 10m | Escaneo QR | Error: `No estás suficientemente cerca del jardín (Xm)` |
| Cámara no disponible | Apertura cámara | Error informativo + mantener inicio manual |
| GPS no disponible en QR | Validación QR | Error: `GPS no disponible, valida tu ubicación` |
| GPS no disponible en manual | Inicio manual | Abrir selector de jardines asignados |
| No hay jardines asignados | Inicio manual | Error: `No tienes jardines asignados` |
| Fallo al crear visita | Creación local | Error: `No se ha podido iniciar la visita` |

---

## 7. UI Requirements

### 7.1 Layout general

- preview de cámara a pantalla completa
- overlay sencillo con instrucciones de escaneo
- botón de cancelar/back en zona superior
- botón `Inicio Manual` fijo y visible
- estado visual limpio, priorizando lectura rápida y uso con guantes

### 7.2 Controles mínimos de v1

- `Cancelar`
- área de cámara/preview
- texto guía: `Apunta al QR del jardín`
- botón grande `Inicio Manual`

### 7.3 Botón Inicio Manual

- debe ser grande y fácil de pulsar con guantes
- debe estar disponible incluso si la cámara falla o no tiene permiso
- debe poder lanzar selector de candidatos o selector de jardines asignados según el resultado GPS

### 7.4 Selector de jardines

La pantalla puede abrir uno de estos dos selectores:

1. **Selector de jardines cercanos**
   - muestra solo jardines asignados detectados dentro de 10m
   - permite elegir uno
   - crea visita verificada

2. **Selector de jardines asignados**
   - muestra todos los jardines asignados al jardinero
   - permite elegir uno
   - crea visita no verificada
   - usado cuando GPS no detecta jardines cercanos o no está disponible
