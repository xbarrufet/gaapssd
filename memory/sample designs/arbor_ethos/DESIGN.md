# Design System Document: Nature Professional Editorial

## 1. Overview & Creative North Star
### The Creative North Star: "The Organic Curator"
This design system moves away from the rigid, boxed-in aesthetics of traditional utility apps and instead embraces the philosophy of "The Organic Curator." Like a well-maintained estate, the UI should feel intentional, spacious, and premium. 

We break the "template" look by utilizing **Editorial Asymmetry**. Instead of centering every element, we use heavy left-aligned typography contrasted with off-axis imagery or floating action elements. This system prioritizes tonal depth over structural lines, using a palette of deep forest greens and warm woods to establish authority and trust, while soft sage and linen-like surfaces provide a fresh, modern breath of air.

## 2. Colors & Surface Philosophy
The palette is rooted in the "Nature Professional" ethos, using earthy tones to ground the user experience.

### The "No-Line" Rule
To achieve a high-end editorial feel, **1px solid borders are prohibited for sectioning.** Boundaries must be defined solely through background color shifts or subtle tonal transitions. For example, a task detail section should be defined by placing a `surface_container_low` card on a `surface` background, rather than drawing a stroke around it.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine paper or frosted glass. Use the `surface_container` tiers to create depth:
- **Base Layer:** `surface` (#fcf9f0) - The foundation of the application.
- **Sectioning:** `surface_container_low` (#f6f3ea) - Used for grouping broad content areas.
- **Component Level:** `surface_container_highest` (#e5e2da) - Used for interactive elements or focused cards to provide a natural lift.

### The "Glass & Gradient" Rule
To modernize the experience beyond the reference image, use **Glassmorphism** for floating headers or navigation bars. Apply a semi-transparent `surface` color with a 20px backdrop-blur. 
- **Signature Textures:** For primary CTAs (Call to Actions) or Hero backgrounds, use a subtle linear gradient transitioning from `primary` (#17340e) to `primary_container` (#2d4b22) at a 135-degree angle. This adds "visual soul" that flat color cannot replicate.

## 3. Typography
Our typography pairing is designed for high-legibility with an editorial edge.

*   **Display & Headlines:** `Manrope` – A modern sans-serif with a geometric foundation. Use `display-lg` and `headline-md` to command attention in a way that feels architectural and firm.
*   **Body & Labels:** `Work Sans` – Optimized for readability. Its slightly wider apertures ensure that even at `body-sm`, maintenance notes and client communications remain crystal clear.

**Hierarchy as Identity:** Use large `display` scales for screen titles (e.g., "Daily Harvest") to create a "magazine header" feel, contrasted with tight, uppercase `label-md` for metadata like "DATE" or "CLIENT."

## 4. Elevation & Depth
We eschew traditional "drop shadows" in favor of **Tonal Layering**.

*   **The Layering Principle:** Place a `surface_container_lowest` (#ffffff) card on a `surface_container_low` (#f6f3ea) background to create a soft, natural lift. This mimics how light hits different planes of a garden.
*   **Ambient Shadows:** When a floating effect is required (e.g., for a Floating Action Button), use an extra-diffused shadow: `blur: 24px`, `spread: -4px`, `opacity: 6%`. The shadow color must be a tinted version of `on_surface` (#1c1c17) rather than pure black.
*   **The "Ghost Border" Fallback:** If a border is required for accessibility, use the `outline_variant` token at **15% opacity**. 100% opaque borders are strictly forbidden.

## 5. Components

### Buttons & Chips
- **Primary Button:** Uses the Signature Texture (Primary Gradient). Corner radius is set to `xl` (0.75rem) for a modern, organic feel.
- **Action Chips:** Use `secondary_container` with `on_secondary_container` text. These should feel like small, smooth pebbles. No border; only color-fill.

### Input Fields & Controls
- **Inputs:** Utilize a "Soft Inset" look. Use `surface_container_highest` with a `Ghost Border`. When focused, transition the border to `primary` at 40% opacity.
- **Checkboxes:** When checked, the fill should be `primary`. The icon inside (the "check") should be a custom-drawn organic leaf-flick rather than a standard checkmark.

### Cards & Lists
- **The "No-Divider" Rule:** Forbid the use of horizontal divider lines. Separate list items using vertical white space (16px - 24px) or by alternating subtle background shifts between `surface` and `surface_container_low`.
- **Weather/Status Cards:** Use Glassmorphism (surface-tint at 10% opacity + blur) to overlay important garden status updates over site photography, as seen in the reference image but modernized with softer corners (`xl`).

### Specialized Components
- **The Garden Timeline:** An asymmetrical vertical line using `outline_variant` that connects maintenance events. The "nodes" on the timeline should be `primary_fixed` circles with `on_primary_fixed` icons.

## 6. Do's and Don'ts

### Do:
- **Do** use generous white space. A "Nature Professional" UI needs room to breathe, much like a well-spaced garden.
- **Do** use `tertiary` (#432715) for earthy accents, such as wood-related maintenance tasks or soil-health indicators.
- **Do** lean into `Manrope` for numbers. The geometry of the typeface makes "2h" or "0.5h" look sophisticated.

### Don't:
- **Don't** use pure black (#000000). Use `on_surface` (#1c1c17) to maintain a soft, organic feel.
- **Don't** use sharp corners. Everything should have at least a `md` (0.375rem) radius to avoid looking "industrial."
- **Don't** crowd icons. Icons should be surrounded by a minimum 8px clear-space padding to ensure they feel like "stamps" rather than clutter.