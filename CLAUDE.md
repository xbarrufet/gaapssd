# GAPP — Claude Code Instructions

## Repository Structure

Monorepo with two applications and shared documentation:

```
GAPPSDD/
├── gappsdd_mobile/     # Flutter mobile app (jardinero + cliente)
├── gappsdd_web/        # Next.js admin dashboard (gestión de usuarios)
├── memory/             # Shared specs, designs, product docs
├── BLUEPRINT.md        # Project blueprint & business logic
└── CLAUDE.md           # This file
```

---

## Mobile App (`gappsdd_mobile/`)

### Tech Stack
- **Flutter/Dart** — SDK ^3.11.4
- **State management:** flutter_riverpod ^2.6.1
- **Routing:** go_router ^14.8.1
- **Local DB:** sqflite (SQLite)
- **Voice:** speech_to_text
- **Other:** google_fonts, uuid, qr_flutter

### Architecture
Feature-based structure under `lib/features/`. Each feature has `data/`, `domain/`, `presentation/` layers.

```
lib/
├── main.dart
├── app/          # App shell, theme, router, providers, shared widgets
├── core/         # Shared utils (format_utils) and errors (AppError sealed class)
└── features/
    ├── auth/     # Login (mock auth)
    ├── chat/     # Bidirectional messaging with request/response modes
    └── visits/   # Core feature: create, edit, close visits
```

### Key Conventions
- **Language:** Code in English. UI strings in Spanish. Docs in Spanish/Catalan.
- **Files:** `snake_case.dart`. Classes: `PascalCase`. Methods: `camelCase`.
- **UI:** Minimum tap targets 56x56 dp (glove-friendly). Confirmation on destructive actions.
- **State:** Riverpod providers in `lib/app/providers.dart`. No raw `setState` for shared state.
- **Navigation:** GoRouter with ShellRoutes. See `lib/app/router.dart`.
- **Errors:** Use `AppError` sealed hierarchy from `lib/core/errors/app_error.dart`.

### Domain Rules (Critical)
- **Verified visit:** Created via QR scan or manual with GPS proximity (<=10m).
- **Unverified visit:** Manual start without GPS or no nearby garden.
- **Editing a CLOSED visit marks it as Unverified.**
- Only one active visit at a time per gardener.
- Visit restoration: if app reopens with active visit, navigate directly to it.

### Running
```bash
cd gappsdd_mobile
flutter pub get
flutter run           # Run on device/emulator
flutter test          # All tests
flutter analyze       # Static analysis
```

---

## Web Admin (`gappsdd_web/`)

### Tech Stack
- **Next.js 16** (App Router, TypeScript)
- **Styling:** Tailwind CSS v4 + shadcn/ui (Arbor Ethos theme)
- **Components:** shadcn/ui (button, card, table, sidebar, form, dialog, etc.)
- **Theme:** next-themes (dark mode via system preference)
- **Tables:** @tanstack/react-table
- **Fonts:** Manrope (headings) + Work Sans (body) via next/font/google

### Architecture
```
src/
├── app/
│   ├── layout.tsx              # Root layout (fonts, ThemeProvider)
│   ├── page.tsx                # Redirects to /dashboard
│   ├── (auth)/login/           # Login page
│   └── dashboard/
│       ├── layout.tsx          # Sidebar + Topbar shell
│       ├── page.tsx            # Overview with stat cards
│       ├── users/              # CRUD: list, new, [id]
│       ├── gardeners/          # CRUD: list, new, [id]
│       └── clients/            # CRUD: list, new, [id]
├── components/
│   ├── ui/                     # shadcn/ui primitives
│   ├── app-sidebar.tsx         # Navigation sidebar
│   ├── topbar.tsx              # Breadcrumbs + dark mode toggle
│   ├── data-table.tsx          # Reusable table with search
│   └── theme-provider.tsx      # next-themes wrapper
├── lib/
│   ├── utils.ts                # cn() helper
│   └── sample-data.ts          # Mock data (temporary)
└── types/index.ts              # User, Gardener, Client types
```

### Key Conventions
- **shadcn/ui v2:** Uses `render` prop (not `asChild`) for polymorphic components.
- **Pages:** Server Components by default; add `"use client"` only when needed.
- **Theme:** CSS variables in `globals.css` (oklch color space). Arbor Ethos palette matching mobile app.
- **UI text:** Spanish.

### Running
```bash
cd gappsdd_web
npm install
npm run dev           # Dev server at localhost:3000
npm run build         # Production build
npm run lint          # ESLint
```

---

## Backend: Supabase

- **Project ID:** `vepznvgqkoqldtlyzbxd`
- **Auth:** Email + Password via Supabase Auth (new publishable key system)
- **DB:** PostgreSQL with RLS (Row Level Security)
- **Storage:** `visit-photos` bucket for visit photography
- **Schema:** `supabase/schema.sql` (run in SQL Editor to initialize)
- **Keys:**
  - Publishable (`sb_publishable_...`) — used in both mobile and web (public)
  - Secret (`sb_secret_...`) — used only in web server-side actions (private)
- **Env files:** `gappsdd_mobile/.env` and `gappsdd_web/.env.local` (both gitignored)

### Key Architecture Decisions
- `user_profiles` auto-created via trigger on `auth.users` insert
- RLS: admins full access, gardeners own visits, clients own gardens
- Mobile uses `SupabaseVisitsRepository` when authenticated, falls back to `SqliteVisitsRepository`
- Web uses `@supabase/ssr` with Server Components and Server Actions

---

## Shared: Arbor Ethos Theme

Both apps share the same visual identity:
- **Primary:** Forest green (#17340E light / #A8D398 dark)
- **Surface:** Cream (#FCF9F0 light / #1A1C16 dark)
- **Fonts:** Manrope (headings, 700-800) + Work Sans (body, 400-500)
- **Border radius:** 14px (inputs/buttons), 24px (cards)
- **Dark mode:** System preference

---

## Post-Implementation Checklist

<!-- IMPORTANT: After completing any feature or significant change, review this checklist -->
<!-- Claude: ALWAYS check these items before considering a task done -->

- [ ] **BLUEPRINT.md** — Does the change affect features, navigation, models, or roadmap status? Update the relevant sections.
- [ ] **memory/specs/** — Does the change modify or complete a spec? Update the spec status.
- [ ] **Tests** — Did you add/update tests for new logic?
- [ ] **Both apps** — If shared types/models changed, check consistency across mobile and web.
- [ ] **flutter analyze** / **npm run lint** — Run to ensure no new warnings.
