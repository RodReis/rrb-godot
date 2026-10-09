---
name: Runic Arcade MOBA HUD
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#d8c3ad'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#a08e7a'
  outline-variant: '#534434'
  surface-tint: '#ffb95f'
  primary: '#ffc174'
  on-primary: '#472a00'
  primary-container: '#f59e0b'
  on-primary-container: '#613b00'
  inverse-primary: '#855300'
  secondary: '#93ccff'
  on-secondary: '#003351'
  secondary-container: '#3198dc'
  on-secondary-container: '#002c47'
  tertiary: '#ffbcb7'
  on-tertiary: '#68000a'
  tertiary-container: '#ff938c'
  on-tertiary-container: '#8d0012'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffddb8'
  primary-fixed-dim: '#ffb95f'
  on-primary-fixed: '#2a1700'
  on-primary-fixed-variant: '#653e00'
  secondary-fixed: '#cce5ff'
  secondary-fixed-dim: '#93ccff'
  on-secondary-fixed: '#001d31'
  on-secondary-fixed-variant: '#004b73'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ad'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930013'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-hero:
    fontFamily: Space Grotesk
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.02em
  display-hero-mobile:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: 0em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Outfit
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
  body-md:
    fontFamily: Outfit
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Outfit
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-numeric-lg:
    fontFamily: JetBrains Mono
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 24px
    letterSpacing: -0.02em
  label-numeric-md:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
  label-numeric-sm:
    fontFamily: JetBrains Mono
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
  hotkey-cap:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1.25rem
  space-xl: 2rem
---

## Brand & Style

This design system establishes a high-octane, stylized dark-fantasy HUD tailored for arcade isometric MOBA and battle arena games. The visual direction merges the tactile, chunky read of casual competitive titles with the angular geometry of low-poly medieval fantasy art.

### Design Movement: Stylized Tactile Fantasy
The interface eschews flat, sterile corporate patterns in favor of stylized, low-poly skeuomorphic framing layered over semi-translucent cosmic slate foundations. Key traits include:
- **Immediate Combat Readability:** High-contrast frames, neon-charged vital gauges, and distinct geometric silhouettes guarantee clarity during fast-paced 3D team fights, spell effects, and shifting terrain.
- **Punchy Tactical Weight:** Buttons and skill slots carry directional light bevels, thick structural borders (2px to 3px), drop shadows, and metallic accents that feel chunky and satisfying to press.
- **Arcade Momentum:** Crisp chamfers, diamond cuts, and angular badge indicators create a competitive, active sensation while preserving medieval flair.

## Colors

The palette organizes into distinct tactical tiers to separate environmental awareness, action triggers, and resource status.

### Tactical Tiers & Atmospheric Layers
- **Primary (Runic Gold - `#F59E0B` / `#FBBF24`):** Designates player ultimate abilities, level-up milestones, win conditions, and legendary tier items. Emits a warm amber inner glow when fully charged.
- **Secondary (Arcane Steel & Mystic Azure - `#0284C7` / `#38BDF8`):** Applied to active skill slots, standard mana/shields, target highlights, and neutral objective states.
- **Tertiary & Danger (Crimson Core - `#EF4444` / `#DC2626` & Fog Purple - `#7C3AED`):** Critical health warnings, hostile cooldown timers, enemy casting indicators, and closing ring/death fog zones.
- **Neutral (Translucent Midnight Slate - `#0F172A` at 85% to 92% opacity):** Backplates and container panels. Keeps the underlying 3D game arena visible while ensuring high contrast for white and gold text overlays.

### Vitality, Resources & Item Rarities
- **Health Vitality:** `#22C55E` with an inner highlight of `#4ADE80` and dark green boundary `#14532D`.
- **Shield & Barrier:** `#38BDF8` overlaying health segment dividers.
- **Common Tier:** `#94A3B8` (Ash Slate).
- **Rare Tier:** `#3B82F6` (Cobalt Prism).
- **Epic Tier:** `#A855F7` (Arcane Amethyst).
- **Legendary Tier:** `#F59E0B` (Sunken Gold).

## Typography

The type system balances sharp mechanical clarity with punchy display headings:
- **Headlines & Combat Announcements (`Space Grotesk`):** Angular, geometric, and aggressive. Used for match kill feeds, objective captures, victory banners, and level up indicators. Always rendered uppercase in critical alerts.
- **Informational Text & Tooltips (`Outfit`):** Highly legible, modern, and clean. Ensures ability descriptions and passive item tooltips are readable instantly without visual clutter.
- **Counters, Timers, Hotkeys & Hitpoints (`JetBrains Mono`):** Monospaced numerals guarantee tabular stability. Cooldown count downs, match clocks, respawn timers, and numerical HP/Mana values do not jitter or cause layout shift when changing values.

## Layout & Spacing

The layout model is anchored to game-screen perimeters via safe-zone anchoring rather than central web documents.

### HUD Anchor Philosophy
- **Lower-Center (Action Console):** Houses hero health bars, mana, spell slots (Q, W, E, R), combat item slots, and trinkets. Elements follow tight horizontal grouping (`space-xs` to `space-sm`) to minimize eye travel.
- **Top-Center (Match Overview & Timers):** Match clock, team scores, and kill/death tracker. Uses `space-md` gaps.
- **Top-Right (Minimap & World Objectives):** Framed hexagonal radar widget anchored 1rem from screen edge with integrated buff timers and game ping wheels.
- **Bottom-Right & Left (Hero Portrait & Stats / Chat):** Collapsible panel hubs with contextual expansion triggers.

### Responsiveness & Safe Zones
- **Desktop (Ultrawide to 16:9):** Content docks within a 5% inset safe area to avoid hardware display bezels.
- **Compact Displays / Handhelds:** HUD scaling automatically increases action slots by 15%, compresses margin down to `0.5rem`, and switches numerical text layers to abbreviated formats (e.g., `2.4k` instead of `2,450`).

## Elevation & Depth

Visual hierarchy does not use soft natural lighting; it uses high-contrast bevels, hard rim-lights, and chromatic luminescence against dark backdrop filters.

### Layer Tiers
1. **Arena Canvas (Level 0):** The raw 3D gameplay layer.
2. **Backplate Panels (Level 1):** `#0F172A` with 85% opacity, `backdrop-filter: blur(12px)`, and a 1.5px metallic slate stroke (`#334155`).
3. **Interactive Sockets & Slots (Level 2):** Inset frames (`box-shadow: inset 0 2px 4px rgba(0,0,0,0.8)`) with 2px solid bronze or runic borders.
4. **Active Ability & Status Glows (Level 3):** Outward radiant bloom (`0 0 12px rgba(245, 158, 11, 0.45)`) signaling ability readiness, cooldown completion, or max-stack status.
5. **Modal & Killstreak Overlays (Level 4):** Heavy dark vignette backing with high-saturation gold and crimson champion cards.

## Shapes

The HUD uses stylized geometric corner cuts (`roundedness: 1` equivalent to `4px` chamfers or micro-radii) mixed with faceted hexagonal silhouettes.
- **Action Slots:** Square shapes with 45-degree corner bevels or standard regular hexagons.
- **Progress Gauges:** Segmented angled bars (12-degree shear/skew) pointing inward toward the center of the display, directing the player's focus toward combat crosshairs.
- **Hotkey Badges:** Octagonal or micro-chamfered pills pinned directly to the bottom right of skill frames.

## Components

### Skill Slots & Spell Cast Buttons
- **Frame:** 56x56px or 64x64px squares with chamfered corners, framed with a 2px dual-tone metal bevel (Top-left: `#FDE68A`, Bottom-right: `#78350F` for Ultimates; Slate/Steel for standard abilities).
- **Cooldown State:** Radial dark sweep overlay (`rgba(15, 23, 42, 0.85)`) over the ability icon, with a prominent centered countdown timer in `label-numeric-lg` font.
- **Ready Pulse:** A one-time outward gold/cyan flare animation on cooldown finish.
- **Hotkey Badge:** A small 18x18px badge pinned to the bottom-center or corner displaying the key (`Q`, `W`, `E`, `R`, `SPACE`) using `hotkey-cap` typography on a dark bronze background.

### Vitality & Resource Meters (Health / Mana / XP)
- **Structure:** Angled horizontal bars sheared at `-12deg`. Divided into 250 HP tick segments for fast burst assessment.
- **Health Fill:** `#22C55E` linear gradient transitioning into `#16A34A` at the baseline. Loss of health leaves a transient white damage ghost bar that drains smoothly over 400ms.
- **Shield Overlay:** Overlapping `#38BDF8` striped pattern overlaying the current HP segment.
- **XP Track:** A thin 4px neon amber line running immediately under the primary ability rack.

### Hexagonal Minimap Frame
- **Silhouette:** Hexagonal or chamfered octagon container framed in dark iron with runic corner studs.
- **Surface:** Radar map overlay set against semi-transparent midnight slate. 
- **Icon Markers:** Sharp diamond icons for heroes (Green = Ally, Red = Hostile, Yellow = Neutral Bosses). Ping indicators display ripple animations on trigger.

### Item & Inventory Slots
- **Visuals:** 40x40px recessed slots. 
- **Rarity Coding:** Outer border color denotes rarity tier (Common: `#94A3B8`, Rare: `#3B82F6`, Epic: `#A855F7`, Legendary: `#F59E0B`). Legendary items feature a subtle ambient particle sheen.
- **Active Items:** Includes an activation hotkey badge and cooldown sweep identical to primary skills.

### Kill Feed & Combat Notifications
- **Banner Layout:** Right-aligned notification stack with slide-in animation.
- **Card Structure:** Chamfered slate ribbons with left-side colored indicators (Red for enemy takedown, Blue for ally takedown, Gold for objective slay). 
- **Typography:** Champion names in `headline-sm` with weapon/skill miniature icon in between.

### Action Prompts & Push Buttons
- **Style:** Chunky 3D game button with a 4px simulated bottom bevel (`box-shadow: 0 4px 0 #78350F` for primary gold, `0 4px 0 #0369A1` for blue).
- **Interaction:** On active press, the button displaces down by 2px with an inner lighting flare, providing tactile feedback without relying on flat touch behaviors.