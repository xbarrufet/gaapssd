# Technical Specifications: Edicio de Visita

**Versión:** 1.0  
**Fecha:** 2026-04-08  
**Estado:** Implemented

---

## 1. Overview

La funcionalidad "Edicio de Visita" cubre las acciones que el jardinero puede realizar dentro de una visita: subir fotos del trabajo realizado, mantener un comentario publico en texto plano y usar dictado por voz para añadir texto sin escribir manualmente.

Esta spec aplica tanto a visitas activas como a visitas cerradas. Si se edita una visita cerrada, la visita pasa automaticamente a **Visita No Verificada**.

Una visita recien creada queda editable de forma inmediata. En cuanto la visita entra en estado `ACTIVE`, el jardinero puede añadir fotos, comentario o dictado sin pasos intermedios adicionales.

---

## 2. Scope

**Incluye:**
- Añadir una o varias fotos a una visita
- Visualizar thumbnails de fotos en listados y detalle
- Eliminar fotos de una visita
- Crear y editar comentario publico de la visita
- Añadir texto al comentario mediante dictado
- Eliminar completamente el comentario
- Editar horario (HH:MM) en visitas cerradas dentro de rango ±24h
- Recalculo automático de duración al editar horarios
- Editar contenido de visitas cerradas

**No incluye:**
- Clasificación de fotos por tarea
- Comentarios privados
- Relación entre fotos y comentario
- Sincronización remota de multimedia
- OCR, IA o etiquetado automático

---

## 3. Business Rules

1. Una visita puede tener cero, una o muchas fotos.
2. Cada visita tiene un unico comentario publico en texto plano.
3. El dictado no reemplaza el comentario existente; siempre añade el texto nuevo al final.
4. El usuario puede borrar el comentario completo con una accion explicita.
5. Las fotos y el comentario se guardan localmente.
6. No existe jerarquia de tareas ni agrupacion; fotos y comentario pertenecen directamente a la visita.
7. Si una visita cerrada es editada, `verificationStatus` pasa a `Visita No Verificada`.
8. La edicion de una visita activa no modifica su estado de verificacion actual.
9. La interfaz debe usar botones grandes y faciles de pulsar por uso con guantes.
10. Una visita recien creada y en estado `ACTIVE` puede editarse inmediatamente.
11. Si la aplicación se abre o se restaura con una visita `ACTIVE`, la aplicación debe abrir directamente la pantalla principal de detalle de esa visita.
12. Solo las visitas CERRADAS permiten edición de horarios (`startTime` y/o `endTime`).
13. La edición de horarios solo permite cambiar HH:MM (hora y minutos), no la fecha.
14. El rango permitido para `startTime` y `endTime` es ±24 horas desde el `startTime` original de la visita.
15. Al cambiar cualquier horario en una visita cerrada, `duration` se recalcula automáticamente como `endTime - startTime`.
16. Al editar horarios de una visita cerrada, `verificationStatus` pasa a `Visita No Verificada`.

---

## 4. Data Model

### 4.1 Visit Updates

```text
Visit {
  id: UUID
  verificationStatus: String        // "Visita Verificada" | "Visita No Verificada"
  publicComment: String?            // Texto plano editable
  photoCount: Int                   // Derivado de las fotos asociadas
  updatedAt: DateTime
}
```

### 4.2 Visit Photo Entity

```text
VisitPhoto {
  id: UUID                          // Generado localmente
  visitId: UUID                     // FK a Visit
  localPath: String                 // Ruta local de la imagen original
  thumbnailLocalPath: String        // Ruta local del thumbnail
  mimeType: String                  // image/jpeg, image/png
  width: Int
  height: Int
  fileSizeBytes: Int
  createdAt: DateTime
  updatedAt: DateTime
}
```

### 4.3 Suggested Storage Model

- Comentario almacenado en la propia entidad `Visit`
- Fotos almacenadas en tabla separada `visit_photos`
- Archivos de imagen guardados en almacenamiento local de la app
- Thumbnail generado localmente en el momento de importar o capturar la foto

---

## 5. User Flows

### 5.1 Añadir Fotos a una Visita Activa o Cerrada

**Precondiciones:**
- Existe una visita seleccionada
- El dispositivo permite acceso a cámara o galería, según implementación
- La visita puede ser una visita recien creada en estado `ACTIVE`

**Flujo:**
1. Jardinero abre el detalle de la visita
2. Presiona botón grande "Afegir Fotos"
3. Sistema ofrece fuente de entrada disponible
4. Jardinero selecciona una o varias fotos
5. Sistema valida formato y tamaño medio permitido
6. Sistema guarda las imagenes localmente
7. Sistema genera thumbnails locales
8. Sistema crea registros `VisitPhoto`
9. Si la visita estaba cerrada:
   - actualiza `verificationStatus = "Visita No Verificada"`
10. Sistema refresca la galeria de la visita y el contador de fotos

**Resultado:**
- Fotos visibles en el detalle de la visita
- Thumbnails visibles en listados donde aplique

### 5.2 Eliminar Foto de una Visita

**Flujo:**
1. Jardinero abre la galeria de la visita
2. Selecciona una foto
3. Presiona botón grande "Eliminar Foto"
4. Sistema solicita confirmacion
5. Sistema elimina archivo original, thumbnail y registro local
6. Si la visita estaba cerrada:
   - actualiza `verificationStatus = "Visita No Verificada"`
7. Sistema actualiza contador y galeria

### 5.3 Editar Comentario Manualmente

**Flujo:**
1. Jardinero abre el detalle de la visita
2. Si la visita acaba de crearse, el formulario de comentario debe estar disponible sin bloqueo adicional
3. Presiona sobre el area de comentario
4. Sistema abre editor de texto plano con controles grandes
5. Jardinero escribe o modifica el contenido
6. Sistema guarda automaticamente `publicComment` localmente tras una pausa breve de escritura
7. Si la visita estaba cerrada:
   - actualiza `verificationStatus = "Visita No Verificada"`

### 5.4 Añadir Texto por Dictado

**Flujo:**
1. Jardinero abre el detalle de la visita
2. Presiona botón "Dictado" debajo del cuadro de texto
3. Sistema inicia reconocimiento de voz del dispositivo
4. Usuario dicta texto
5. Sistema recibe el texto reconocido
6. Sistema añade el texto al final de `publicComment`
   - Si el comentario estaba vacio, el texto dictado pasa a ser el comentario completo
   - Si ya existe comentario, se concatena con separacion legible
7. Sistema guarda el comentario actualizado localmente
8. Si la visita estaba cerrada:
   - actualiza `verificationStatus = "Visita No Verificada"`

### 5.5 Eliminar Comentario

**Flujo:**
1. Jardinero abre detalle de la visita
2. Presiona botón "Borrar" debajo del cuadro de texto
3. Sistema solicita confirmacion
4. Sistema vacia `publicComment`
5. Si la visita estaba cerrada:
   - actualiza `verificationStatus = "Visita No Verificada"`

### 5.6 Editar Horario de Visita Cerrada

**Precondiciones:**
- La visita tiene `status = CLOSED`
- Jardinero abre el detalle de la visita cerrada

**Flujo:**
1. Jardinero presiona botón "Editar Horario" (visible solo en visitas cerradas)
2. Sistema abre modal/pantalla de edición de horarios
3. Sistema muestra dos campos editables:
   - "Hora de Entrada" (HH:MM)
   - "Hora de Salida" (HH:MM)
4. Sistema muestra el rango permitido:
   - Mínima: `startTime original - 24 horas`
   - Máxima: `startTime original + 24 horas`
5. Jardinero modifica uno o ambos campos
6. Sistema valida:
   - HH:MM válido entre 00:00 y 23:59
   - Tiempo dentro del rango permitido
   - `endTime >= startTime` (salida no puede ser antes de entrada)
7. Si validación falla: mostrar error especifico
8. Si validación pasa:
   - Actualiza `startTime` y/o `endTime` localmente
   - Recalcula `duration = endTime - startTime`
   - Actualiza `verificationStatus = "Visita No Verificada"`
   - Actualiza `updatedAt` timestamp
9. Cierra modal y vuelve al detalle de la visita
10. Detalle muestra nuevos horarios y duración actualizada

**Error Handling:**
- Si HH:MM está fuera del rango permitido: "La hora debe estar dentro de 24 horas del inicio original"
- Si `endTime < startTime`: "La hora de salida no puede ser anterior a la hora de entrada"

---

## 6. UX Requirements

### 6.1 Interaction Design

- Botones primarios con area minima tactil de 56x56 dp
- Separacion amplia entre acciones para evitar errores con guantes
- Acciones frecuentes visibles sin depender de menus pequeños
- El botón de dictado debe ser prominente y accesible desde el editor/comentario
- El botón de eliminar comentario debe ser claro pero con confirmacion obligatoria

### 6.2 Visit Detail Screen

**Bloques funcionales:**
- Cabecera de visita con estado y badge de verificacion
- Galeria de thumbnails de fotos
- Botón grande "Afegir Fotos"
- Area de comentario publico
- Botón "Dictado" (debajo del cuadro de comentario)
- Botón "Borrar" (debajo del cuadro de comentario)
- Guardado automatico del comentario sin botón "Guardar"
- Botón "Editar Horario" (solo visible en visitas cerradas)
- Botón "End Visit" si la visita sigue activa
- Si la visita acaba de crearse, las acciones de fotos y comentario deben estar habilitadas desde la primera renderizacion
- Si la aplicación se restaura con una visita activa, esta pantalla debe abrirse como primer destino
- La restauración debe abrir el detalle principal, sin entrar automáticamente al editor de comentario, galería o dictado
- Esta pantalla no debe mostrar la bottom bar raíz del jardinero

### 6.3 Visit List Screen

- Mostrar thumbnail de foto principal de cada visita (si existe)
- Mostrar estado y badge de verificacion
- Permitir navegar a detalle de la visita
