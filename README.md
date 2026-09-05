# CooldownGlows

Highlights action bar buttons with a proc glow when spell/item cooldowns finish.

## Features

- **Spell tracking** — Add spells by ID, glow when cooldown ends
- **Charge-aware** — Spells with charges only glow when all charges are full
- **Item tracking** — Add items by ID, glow when off cooldown
- **Glow colors** — Choose from 10 colors (Default, White, Red, Green, Blue, Yellow, Orange, Purple, Pink, Cyan)
- **Per-class profiles** — Separate spell/item lists per class
- **Per-character profiles** — Override class profile for specific characters
- **Duration control** — Auto-hide glow after configurable seconds
- **Combat-only mode** — Suppress glows outside combat
- **Manual Assignment** — Precisely map abilities strictly to your expected UI layout targets.
- **Precision Tracking** — Operates natively on a `.05s (20Hz)` active background evaluation hook for maximum accuracy bypassing broken throttled Events.
- **Combat-safe** — No taint-prone API calls; uses visual cooldown state and static assignment mappings for unbreakable in-combat stability.
- **Zero dependencies** — Self-contained proc glow system, no external libraries required
- **Debug tools** — `/cdg cache` and `/cdg test` for troubleshooting

## Usage

Type `/cdg` or `/cooldownglows` in-game to open the settings panel (deferred automatically if you are in combat).

| Command | Description |
|---------|-------------|
| `/cdg` | Open settings |
| `/cdg test` | Trigger glows on all tracked buttons |
| `/cdg cache` | View spell/item → button mappings |

- **General tab** — Combat-only toggle, debug mode, active profile info
- **Class tab** — Edit spell/item list for your class
- **Character tab** — Create/delete a character-specific override

Each tracked entry has an **Edit** ⚙ button to modify duration and color, and a **Remove** ✕ button to delete it.

## Behavior

When a tracked spell or item's cooldown finishes (transitions from on-cooldown to ready), the addon triggers a proc glow on its action bar button for a configurable number of seconds before fading out.

**Spells with Charges:** Only glow when maximum charges are reached. This is a known limitation of the WoW 12.0 API, as current charge counts are restricted ("secret") values in combat.

## Install

Copy `CooldownGlows/` into your `Interface/AddOns/` folder, or install via [CurseForge](https://www.curseforge.com/wow/addons/cooldownglows).

**No external dependencies required.** The addon includes its own self-contained glow system.

**Compatibility:** WoW 12.0+ (Midnight) and later.
