# Specification: Client Visit Screens (List & Detail)

**Versión:** 1.0  
**Fecha:** 8 d'abril del 2026  
**Estado:** Implemented  
**Scope:** Client visit list and detail screens, data models, and navigation

---

## 1. Overview

This specification documents the two client-facing screens for viewing completed visits:
1. **Client Visits List** — Historical view of all completed visits for a client
2. **Client Visit Detail** — Full report of a single visit with photos, entry/exit times, and comments

Both screens pull data from SQLite via `VisitsRepository` and display full visit telemetry without relying on hardcoded metadata.

---

## 2. Data Models

### 2.1 VisitSummary (List Item)

Located in: `lib/features/visits/domain/client_visits_data.dart`

```dart
class VisitSummary {
  final String id;
  final String gardenId;
  final int durationMinutes;
  final String dayLabel;           // "08" (zero-padded day)
  final String monthLabel;          // "APR" (3-letter month)
  final String title;               // Work type (kept for now, not shown in list)
  final String description;         // Work details (shown in list card)
  final VisitVerificationStatus status;
  final int photoCount;             // Default 0; set from visit_photos count
}
```

**Purpose:** Powers the list view, provides quick scan of visit history with date badge, description, and photo indicator.

**Photo Count Source:** Dynamically queried from SQLite `visit_photos` table in `SqliteVisitsRepository.loadCompletedVisits()`.

### 2.2 VisitReport (Detail View)

Located in: `lib/features/visits/domain/client_visits_data.dart`

```dart
class VisitReport {
  final String id;
  final String gardenId;
  final VisitVerificationStatus status;
  // Logistics
  final String visitDate;           // e.g., "8 de abril de 2026"
  final String duration;            // e.g., "1h 38m"
  final String entryTime;           // e.g., "09:12" (HH:MM format)
  final String exitTime;            // e.g., "10:49" (HH:MM format)
  // Gardener Info
  final String gardenerName;
  final String gardenerRole;        // e.g., "Lead Gardener"
  final String gardenerAvatarUrl;
  final String heroImageUrl;
  // Content
  final String publicComment;       // Comment text from visit.public_comment
  final List<VisitPhoto> photos;
}
```

**Time Format:** All times (`entryTime`, `exitTime`) are formatted as HH:MM (24-hour format, e.g., "09:12").

**Comment Field:** `publicComment` comes directly from the `visits.public_comment` column in SQLite. Empty string if null.

**Photo Order:** Photos are fetched from SQLite in insertion order; the `featured` flag indicates which is hero image (shown in header).

---

## 3. Client Visits List Screen

### 3.1 File Location
`lib/features/visits/presentation/client_visits_screen.dart`

### 3.2 Screen Structure

```
SafeArea
├── CustomScrollView
│   └── SliverList (future: SliverAppBar with search)
│       └── Padding
│           └── _VisitCard (for each VisitSummary)
```

### 3.3 Visit Card Layout

**Visual:**
```
┌─────────────────────────────────────┐
│ [08]  "Pruning and..."  [🖼 if photos]
│ APR   View Details
│       [no comment button]
└─────────────────────────────────────┘
```

**Components:**
- **Date Badge (left):** 
  - Day in large text (e.g., "08")
  - Month in small text (e.g., "APR")
  - Background: surfaceLow, corner radius 12
  
- **Content (middle, expanded):**
  - Description text (not title)
  - "View Details" button (chip style, primary color)
  
- **Photo Indicator (top right, conditional):**
  - If `visit.photoCount > 0`: Circular icon with image symbol
  - Color: primary background with onPrimary icon
  - Size: 16px icon in small circle

**Interactions:**
- Tap "View Details" → Navigate to `VisitReportScreen` with same visit
- Tap card → Also navigate to detail (future enhancement)

**Removed Elements:**
- Visit title (redundant; description provides detail)
- Comment button (not relevant for client viewing completed visits)

### 3.4 Data Source

- Repository: `VisitsRepository.loadCompletedVisits()`
- Returns: `Future<List<VisitSummary>>`
- Filter: Only visits where `ended_at IS NOT NULL`
- Order: By `started_at DESC` (newest first)
- Photo Count: Queried from `visit_photos` table per visit

### 3.5 Navigation

```
ClientRoot
  ├─ Clientes tab (future, placeholder)
  └─ ClientVisitsScreen (list)
     └─ VisitReportScreen (detail, visit selected)
        └─ ChatWithRequestModesScreen (chat icon used)
```

---

## 4. Client Visit Detail Screen

### 4.1 File Location
`lib/features/visits/presentation/visit_report_screen.dart`

### 4.2 Screen Structure

```
Scaffold
├── body: SafeArea
│   └── CustomScrollView
│       ├── SliverAppBar (back button, no title)
│       ├── Hero Image (_ReportHero)
│       ├── Verification Badge
│       ├── Logistics Card (_LogisticsCard)
│       ├── Comments Card (_CommentsCard, if not empty)
│       ├── "Visual Documentation" label
│       └── Photo Grid (SliverGrid, 2 columns)
└── [no bottom nav or button; chat access via gardener info icon]
```

### 4.3 Components

#### 4.3.1 Hero Image (_ReportHero)
- Full-width image at top
- `report.heroImageUrl` (featured photo)
- Fallback: Garden icon if no URL

#### 4.3.2 Verification Badge (_VerificationBadge)
- Shows "Verified" or "Manual Entry" status
- Color: green for verified, yellow/amber for manual
- Positioned below hero image

#### 4.3.3 Logistics Card (_LogisticsCard)
**Layout:**
```
Row 1: [Visit Date | Duration]
Row 2: [Entry Time | Exit Time]
Row 3: [Avatar] [Gardener Name / Role] [📞] [💬]
```

**Row 1 — Date & Duration:**
- Visit Date: e.g., "8 de abril de 2026"
- Duration: e.g., "1h 38m"
- Both use _DataBlock component (label on top, value below)

**Row 2 — Times (NEW):**
- Entry Time: e.g., "09:12"
- Exit Time: e.g., "10:49"
- Provides clear entry/exit visibility (client's peace of mind)

**Row 3 — Gardener Info & Actions:**
- Avatar: Circle, 44px, with gardener photo or person icon fallback
- Name & Role: Display gardener name (title) and role (subtitle)
- Call Icon (📞): Primary background, placeholder onPressed (future implementation)
- Chat Icon (💬): Primary background, navigates to `ChatWithRequestModesScreen`
  - Instantiates `FakeChatRepository()` and passes to chat screen
  - No dialog or confirmation; direct navigation

**Styling:**
- Background: `AppColors.surfaceLow`
- Corner Radius: 24
- Padding: 18 all around
- Font: titleLarge for labels, bodyMedium for values

#### 4.3.4 Comments Card (_CommentsCard)
**Conditional:** Only shown if `report.publicComment.isNotEmpty`

**Layout:**
```
Title: "Comments"
Body: Multiline comment text
```

**Styling:** Same as logistics card (surfaceLow, 24 radius, 18 padding)

**Content:** Raw text from `publicComment` field; no emoji/formatting processing

#### 4.3.5 Visual Documentation (Photo Grid)
- **Label:** "Visual Documentation" (labelMedium style, padding 14 top)
- **Grid:** 2-column SliverGrid
- **Photo Tile:** Each photo as _PhotoTile (image, tap to view full screen — future)
- **Spacing:** 12px between items
- **Item Height:** 150 pixels (fixed)

### 4.4 Navigation & Interactions

**Back Button:** Safe area top-left, returns to client visits list

**Call Button:** Placeholder; no action currently

**Chat Button:** Navigates to chat screen
```dart
Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => ChatWithRequestModesScreen(
      repository: FakeChatRepository(),
    ),
  ),
);
```

**No Bottom Action Button:** Chat moved to gardener info row; no "Start Chat" button at bottom anymore

---

## 5. Repository Implementation

### 5.1 VisitsRepository Interface

Both implementations (Fake and SQLite) provide:

```dart
// Load all completed visits for client
Future<List<VisitSummary>> loadCompletedVisits();

// Load full report for a single visit
Future<VisitReport> loadVisitReport(String visitId);
```

### 5.2 FakeVisitsRepository

**Location:** `lib/features/visits/data/visits_repository.dart`

**Data:**
- Three hardcoded visits (2026-04-08, 2026-04-02, 2026-03-26)
- Each visit has:
  - `photoCount`: 3, 1, 1 respectively
  - `entryTime` & `exitTime`: HH:MM format
  - `publicComment`: Descriptive text of work performed
  - Photos with data and captions

**Behavior:**
- Returns mock data with 240ms delay (simulates network)
- Used for UI development and demos

### 5.3 SqliteVisitsRepository

**Location:** `lib/features/visits/data/sqlite_visits_repository.dart`

**Implementation:**
- `loadCompletedVisits()`: 
  - Queries all visits where `ended_at IS NOT NULL`
  - For each visit, counts photos in `visit_photos` table
  - Returns `VisitSummary` with dynamic `photoCount`

- `loadVisitReport(visitId)`:
  - Queries single visit by ID
  - Calls `loadClientProfile()` for gardener metadata
  - Formats times using helper: `String _timeLabel(DateTime)`
  - Constructs `VisitReport` with all DB-sourced fields
  - Fetches photos from `visit_photos` table

**Time Formatting:**
```dart
String _timeLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
```

**Photo Handling:**
- Photos fetched by `visit_id` from `visit_photos` table
- Order: insertion order (file path based)
- Featured flag indicates hero image

---

## 6. Data Models Reference

### Entry/Exit Time Format
- **Format:** 24-hour HH:MM (e.g., "09:12", "14:45")
- **Source:** `DateTime.hour` and `DateTime.minute` from SQLite
- **Usage:** Display in logistics card, labeled "Entry Time" and "Exit Time"

### Photo Count
- **Source:** COUNT from `visit_photos` where `visit_id = ?`
- **Usage:** Conditional display of photo icon in list
- **Threshold:** Shown if `photoCount > 0`

### Public Comment
- **Source:** `visits.public_comment` column
- **Handling:** Empty string if null
- **Display:** Multiline in comments card (if not empty)

---

## 7. Navigation Summary

### Client Visits List → Detail
```
ClientVisitsScreen
  └─ Tap "View Details" on any visit
     └─ Navigator.push(VisitReportScreen)
```

### Client Visit Detail → Chat
```
VisitReportScreen (gardener info)
  └─ Tap 💬 icon
     └─ Navigator.push(ChatWithRequestModesScreen)
```

### Client Visit Detail → Back
```
VisitReportScreen
  └─ Tap back button (top-left)
     └─ Navigator.pop()
        └─ ClientVisitsScreen
```

---

## 8. Future Enhancements

- **Photo Lightbox:** Tap photo to view full-screen with swipe
- **Download/Share:** Add button to download or share visit report
- **Rating/Review:** Allow client to rate or review gardener
- **Dispute Timeline:** Show dispute/review request flow if applicable
- **Real Chat:** Replace `FakeChatRepository` with actual messaging backend
- **Offline Support:** Cache visit reports locally for offline viewing

---

## 9. Testing & Validation

### Unit Tests (Recommended)
- Mock `VisitsRepository` in tests
- Verify time formatting HH:MM
- Test photo count calculation
- Validate comment null-safety

### Integration Tests
- Navigate list → detail → chat → back flow
- Verify lazy loading of photos
- Test empty comment state
- Verify time display accuracy

### Manual Testing
- List loads and displays all completed visits
- Photo icon appears only when `photoCount > 0`
- Entry/exit times display in HH:MM format
- Comments show only when populated
- Chat icon navigates to chat screen
- Call icon doesn't crash (placeholder)

---

## 10. Known Limitations (v1)

- No photo zoom/lightbox view
- Chat is fake data (mock repository)
- No offline sync; all data is local SQLite only
- No push notifications for new visits
- No rating/review system
- Call button is placeholder (no actual calling)

