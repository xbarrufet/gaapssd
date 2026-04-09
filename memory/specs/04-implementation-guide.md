# Implementation Guide: Visit Features Architecture & Code Structure

**Versión:** 1.0  
**Fecha:** 2026-04-08  
**Estado:** Implemented  
**Scope:** Architecture decisions, required data models, navigation, and component integration

> **Nota monorepo:** Todos los paths `lib/...` son relativos a `gappsdd_mobile/`.

---

## 1. Overview

This guide translates the domain logic defined in the three functional specifications into actionable implementation steps. It maps screens, repositories, state management, and navigation within the existing flutter app structure.

**Referenced specs:**
- `01-visit-lifecycle.md` — Visit creation, verification, and closure logic
- `02-visit-editing.md` — Photo, comment, and voice dictation features
- `03-visit-initiation-screen.md` — QR and manual initiation UI

---

## 2. Navigation Architecture

### 2.1 Gardener App Bottom Bar (Root Level)

**5-element bottom bar visible only in root screens:**

```
1. Visita (Visit)
   - Icon: Home
   - Destination: visit_list_gardener
   - Role: Historical list of all visits
   
2. Clientes (Clients)
   - Icon: People
   - Destination: client list screen (future)
   - Role: View assigned clients and gardens contextually
   
3. Nueva Visita (New Visit) — CENTRAL, DOUBLED SIZE
   - Icon: Camera
   - Destination: visit_initiation_screen (QR camera + manual start)
   - Role: Begin a new visit
   
4. Chat
   - Icon: Message
   - Destination: chat screen (future)
   - Role: Communicate with clients
   
5. Configuración (Settings)
   - Icon: Gear
   - Destination: settings screen (future)
   - Role: User preferences
```

### 2.2 Navigation Flow

```text
Login
  ↓
Gardener Root (bottom bar visible)
  ├─ Visita tab
  │   ├─ visit_list_gardener (shows historical visits)
  │   └─ [If active visit exists on app open] → skips list, opens GardenerVisitDetailsScreen
  │
  ├─ Clientes tab (future)
  │   └─ assigned_gardens_visit_status_screen (can be reused contextually)
  │
  ├─ Nueva Visita tab
  │   ├─ visit_initiation_screen (full-screen camera/manual)
  │   │  ├─ QR scan path → creates visit → GardenerVisitDetailsScreen
  │   │  └─ Manual start path → GardenerVisitDetailsScreen
  │   └─ [If active visit on entry] → shows alert, skips to GardenerVisitDetailsScreen
  │
  ├─ Chat tab (future)
  └─ Configuración tab (future)

GardenerVisitDetailsScreen (NO bottom bar)
  └─ [Active or closed visit detail, editing disabled after closure]
```

### 2.3 Key Navigation Rules

1. **Active visit priority**: If app opens/restores with an active visit, skip `visit_list_gardener` and open `GardenerVisitDetailsScreen` directly.
2. **No parallel active visits**: "Nueva Visita" button checks for active visit; if one exists, shows alert and navigates to it.
3. **No bottom bar in detail**: `GardenerVisitDetailsScreen` is a full-screen detail view without the 5-element bottom bar.
4. **Closure navigation**: After closing a visit, return to `visit_list_gardener` or the Visits tab.

---

## 3. Required Domain Models

### 3.1 Visit Entity (Core)

```dart
enum VisitStatus { ACTIVE, CLOSED }
enum VisitVerificationStatus { VERIFIED, NOT_VERIFIED }
enum VisitInitiationMethod { QR_SCAN, MANUAL }

class Visit {
  final String id;                    // UUID
  final String gardenerId;
  final String gardenId;
  final String clientId;
  
  final VisitStatus status;
  final VisitVerificationStatus verificationStatus;
  final VisitInitiationMethod initiationMethod;
  
  final DateTime startTime;
  final DateTime? endTime;
  final Duration? duration;           // Calculated
  
  final String? publicComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Derived
  Duration get liveDuration =>
    endTime != null
      ? endTime!.difference(startTime)
      : DateTime.now().difference(startTime);
}
```

### 3.2 Visit Photo Entity

```dart
class VisitPhoto {
  final String id;                // UUID
  final String visitId;           // FK
  
  final String localPath;         // Original image
  final String thumbnailLocalPath;
  
  final String mimeType;
  final int width;
  final int height;
  final int fileSizeBytes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 3.3 QR Payload

```dart
class QrVisitPayload {
  final String clientId;
  final String gardenId;
  
  final double latitude;
  final double longitude;
  final double accuracy;          // Meters
  
  GpsLocation get gpsLocation =>
    GpsLocation(lat: latitude, lon: longitude, accuracy: accuracy);
}
```

### 3.4 Visit Session View Model (For Screen State)

```dart
class VisitSession {
  final String id;
  final String gardenerId;
  final String gardenId;
  final String gardenName;
  final String clientId;
  final String address;
  
  final VisitStatus status;
  final VisitVerificationStatus verificationStatus;
  final VisitInitiationMethod initiationMethod;
  
  final DateTime startTime;
  final DateTime? endTime;
  
  final String? publicComment;
  final List<VisitPhoto> photos;
  
  Duration get currentDuration =>
    endTime != null
      ? endTime!.difference(startTime)
      : DateTime.now().difference(startTime);
}
```

---

## 4. Repository Contract (VisitsRepository)

### 4.1 Lifecycle Methods

```dart
// Load the active visit for the current gardener, if any
Future<Visit?> loadActiveVisit(String gardenerId);

// Load a specific visit session with all details
Future<VisitSession> loadVisitSession(String visitId);

// Start a new visit from QR scan
Future<Visit> startVerifiedVisitFromQr({
  required String gardenerId,
  required QrVisitPayload qrPayload,
  required GpsLocation currentLocation,
});

// Start a manual visit (assignment already chosen or selected by user)
Future<Visit> startManualVisit({
  required String gardenerId,
  required String gardenId,
  required bool wasGpsVerified,
  required GpsLocation? currentLocation,
});

// Close an active visit
Future<Visit> closeVisit(String visitId);

// Load all visits (historical)
Future<List<Visit>> loadVisitHistory(String gardenerId);
```

### 4.2 Content Editing Methods

```dart
// Save photo(s) to a visit
Future<List<VisitPhoto>> addVisitPhotos({
  required String visitId,
  required List<LocalImageInput> images,
});

// Remove a photo
Future<void> removeVisitPhoto({
  required String visitId,
  required String photoId,
});

// Save or update comment
Future<void> saveVisitComment({
  required String visitId,
  required String comment,
});

// Append text from voice dictation
Future<void> appendVisitDictation({
  required String visitId,
  required String dictatedText,
});

// Clear comment
Future<void> clearVisitComment(String visitId);
```

### 4.3 Repository Behavior

**Must enforce:**
1. Only one `ACTIVE` visit per gardener at a time.
2. If a `CLOSED` visit is edited (photos, comment), mark as `NOT_VERIFIED`.
3. Persist all changes locally before updating UI.
4. Calculate `duration` automatically when visit closes.
5. Retry failed local saves with exponential backoff.

---

## 5. Screen Refactoring: From Current to Target

### 5.1 AssignedGardensVisitStatusScreen

**Current state:** Renders gardens, has mock QR button, each card has "Start Visit" action.

**Decision:** This screen is **no longer the root entry** for the Visits tab. Its role becomes secondary and contextual.

**New location:** Accessible from the Clientes tab to view gardens within a client context.

**Changes required:**
- Remove from being the default route for the Visita tab
- Decouple from visit initiation (QR, manual) — that's now `visit_initiation_screen`'s job
- Can remain as a contextual view if needed for client/garden exploration

### 5.2 VisitListGardener

**Current state:** Exists as a design; should be the root of the Visita tab.

**Changes required:**
- Implement as the default route for Visita tab
- Show historical visits (all status = CLOSED)
- If app opens with active visit, **skip this screen** and jump directly to `GardenerVisitDetailsScreen`
- Include search, filters, and sorting (can be placeholders in v1)

### 5.3 VisitInitiationScreen (NEW — replaces the QR button logic)

**Responsibility:** Handle QR scanning and manual start flows.

**Inputs:** None (queries repository for gardener, active visit, assigned gardens)

**Logic:**
```
On entry:
  1. Check if active visit exists → alert + navigate to detail
  2. Open camera for QR
  3. Show "Manual Start" button always visible
  4. On QR success → validate garden assigned → validate GPS proximity → create visit
  5. On manual click → request GPS → find candidates → selector (1, many, or all) → create visit
  6. On creation success → navigate to GardenerVisitDetailsScreen(visitId)
```

**Key decisions:**
- No bottom bar on this screen
- Full-screen camera preview
- Must work even if camera unavailable (manual button still functional)

### 5.4 GardenerVisitDetailsScreen (MAJOR REFACTORING)

**Current inputs:**
```dart
GardenerVisitDetailsScreen({required AssignedGardenVisitStatus garden})
```

**Target inputs:**
```dart
GardenerVisitDetailsScreen({
  required String visitId,
  required VisitsRepository repository,
})
```

**Current UI blocks:**
- ClientCard (hardcoded data)
- TimerControlsCard (hardcoded duration, "SCAN EXIT" button)
- ActivityGallery (mock remote images)
- NotesDictateSection (no persistence)
- ChecklistCard (out of scope for now)

**Target UI blocks:**
- **Header**: Garden name, client, address, status badge (ACTIVE/CLOSED), verification badge
- **Timer**: Show real `startTime`, live duration if ACTIVE, final duration if CLOSED
- **Controls**:
  - "End Visit" button if ACTIVE (shows confirmation, closes visit, updates status, duration)
  - (Optional) "SCAN EXIT QR" as placeholder for future
- **Gallery**:
  - Show real VisitPhoto thumbnails from repository
  - "Add Photos" button with glove-friendly size
  - Delete photo option with confirmation
  - On deletion/addition of closed visit → mark NOT_VERIFIED
- **Comment Section**:
  - Load real `publicComment` state
  - Edit button → text editor modal
  - Save persists via repository
  - "Dictate" button → voice input → append to comment
  - "Clear Comment" button with confirmation
  - On edit of closed visit → mark NOT_VERIFIED
- **Checklist**: Remove or hide behind feature flag (out of scope v1)

**State management:**
```dart
class _GardenerVisitDetailsScreenState extends State<GardenerVisitDetailsScreen> {
  late VisitSession currentVisit;
  late TextEditingController commentController;
  
  bool isSavingComment = false;
  bool isUploadingPhotos = false;
  bool isClosingVisit = false;
  
  Timer? durationTicker;  // For live updates if ACTIVE
  
  @override
  void initState() {
    super.initState();
    _loadVisitSession();
    _startDurationTicker();
  }
  
  // ... lifecycle and event handlers
}
```

**Behavior on restoration:**
- If app opens with active visit, this screen opens directly (no bottom bar)
- Does not auto-open comment editor, gallery, or dictation
- Allows user to continue editing or close the visit

**Behavior on closure:**
- Updates visit status to CLOSED, calculates final duration
- Optionally shows snackbar/confirmation
- Navigates back to visit_list_gardener or Visita tab

---

## 6. State Management Approach (Recommendation)

Use **Provider** or **Riverpod** for:

1. **VisitsRepository** — singleton, provides all visit CRUD operations
2. **CurrentVisitProvider** — notifier that holds the active visit (or null)
3. **VisitSessionProvider(visitId)** — notifier for a specific visit detail
4. **GardenerProvider** — current logged-in gardener context

Example:
```dart
final visitsRepositoryProvider = Provider((ref) => VisitsRepository(...));

final activeVisitProvider = FutureProvider<Visit?>((ref) async {
  final repo = ref.watch(visitsRepositoryProvider);
  final gardener = ref.watch(gardenerProvider);
  return repo.loadActiveVisit(gardener.id);
});

final visitSessionProvider = FutureProvider.family<VisitSession, String>((ref, visitId) async {
  final repo = ref.watch(visitsRepositoryProvider);
  return repo.loadVisitSession(visitId);
});
```

---

## 7. Navigation Routing (GetX, GoRouter, or Navigator)

Recommended: Use **GoRouter** for declarative routing.

```dart
final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/gardener',
      builder: (context, state) => GardenerRootScreen(),
      routes: [
        GoRoute(
          path: 'visits',
          builder: (context, state) => VisitListGardener(),
        ),
        GoRoute(
          path: 'clients',
          builder: (context, state) => ClientsListScreen(), // future
        ),
        GoRoute(
          path: 'new-visit',
          builder: (context, state) => VisitInitiationScreen(),
        ),
        GoRoute(
          path: 'chat',
          builder: (context, state) => ChatScreen(), // future
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => SettingsScreen(), // future
        ),
        GoRoute(
          path: 'visit-detail/:visitId',
          builder: (context, state) {
            final visitId = state.pathParameters['visitId']!;
            return GardenerVisitDetailsScreen(visitId: visitId);
          },
        ),
      ],
    ),
  ],
);
```

---

## 8. Local Persistence Strategy

- **Technology:** SQLite via **sqflite**
- **Tables:** `visits`, `visit_photos`, plus any app-specific state
- **Transactions:** Ensure atomic updates (e.g., close + duration + status together)
- **Indexing:** Index `gardener_id`, `status`, `created_at` for efficient queries
- **Cleanup:** Implement periodic sync cleanup after successful remote persistence (future)

---

## 9. Error Handling & Edge Cases

1. **No active visit on manual start but user attempts**: Reject; warn actively to create new visit.
2. **GPS fails on QR scan**: Show error; allow manual start as option.
3. **Calmly degrade**: If camera unavailable, skip QR, manual start still works.
4. **Multiple simultaneous edits**: Use `updatedAt` timestamp to detect conflicts; local always wins in v1.
5. **Photo/comment persistence fails**: Queue and retry on next connectivity.
6. **Visited closed, user edits**: Automatically downgrade to NOT_VERIFIED; do not re-verify without new QR.

---

## 10. Feature Flags & Rollout

- Recommend feature flag for `visit_list_gardener` → enable when ready
- Can keep `assigned_gardens_visit_status_screen` behind flag for gradual migration
- Launch `visit_initiation_screen` and `GardenerVisitDetailsScreen` together

---

## 11. Testing & Validation

### Unit Tests
- Visit creation logic (QR vs. manual, verification rules)
- GPS proximity calculations
- Comment/photo persistence
- Deserialization of QR data

### Widget Tests
- Visit initiation screen flows
- Detail screen rendering
- Photo/comment interactions

### Integration Tests
- Full flow: new visit → add photos → close → verify in history
- Active visit restoration on app cold start
- Error handling (no camera, GPS fail, etc.)

---

## 12. Current Implementation Snapshot (8 d'abril del 2026)

- `NewVisitScreen` ya existe y está conectado desde navegación de jardinero.
- La bottom bar del jardinero incluye acción central de `Nueva Visita`.
- Se aplica lock de visita activa única en repositorio fake (`loadActiveVisit`, `startVisitFromQr`, `startManualVisit`).
- El flujo manual contempla casos de jardines cercanos y fallback a selector de jardines asignados.
- `GardenerVisitDetailsScreen` puede cerrar la visita activa (`closeActiveVisit`) desde `Manual Exit`.

### Limitaciones actuales

- Lectura QR está simulada (no integración con cámara nativa todavía).
- Validación GPS está simulada (no geolocalización real todavía).
- Persistencia sigue siendo en memoria del repositorio fake para este flujo.
