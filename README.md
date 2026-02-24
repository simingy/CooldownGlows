# CooldownGlows

Highlights action bar buttons with a proc glow when spell/item cooldowns finish.

## Features

- **Spell tracking** — Add spells by ID, glow when cooldown ends
- **Charge-aware** — Spells with charges only glow when all charges are full
- **Item tracking** — Add items by ID, glow when usable and off cooldown
- **Glow colors** — Choose from 10 colors (Default, White, Red, Green, Blue, Yellow, Orange, Purple, Pink, Cyan)
- **Per-class profiles** — Separate spell/item lists per class
- **Per-character profiles** — Override class profile for specific characters
- **Duration control** — Auto-hide glow after configurable seconds
- **Combat-only mode** — Suppress glows outside combat
- **Spell/Item helpers** — Browse spellbook or action bar items to find IDs
- **Combat-safe** — No taint-prone API calls; uses visual cooldown state for reliable in-combat tracking

## Usage

Type `/cdg` or `/cooldownglows` in-game to open the settings panel (this is deferred if you are in combat).

- **General tab** — Combat-only toggle, active profile info
- **Class tab** — Edit spell/item list for your class
- **Character tab** — Create/delete a character-specific override

Each tracked entry has an **Edit** ⚙ button to modify duration and color, and a **Remove** ✕ button to delete it.

## Behavior

When a tracked spell or item's cooldown finishes (goes from on-cooldown to ready), the addon detects it and triggers a glow on its action bar button for a configurable number of seconds `x` before fading out.

**Important Note on Spells with Charges:** If a spell has multiple charges, it will **only** glow when it reaches maximum charges. This is a known limitation of the new Blizzard API secret/taint system, as current charge counts are no longer readable via the API while in combat.

## Install

Copy `CooldownGlows/` into your `Interface/AddOns/` folder, or install via [CurseForge](https://www.curseforge.com/wow/addons/cooldownglows).

**Requires:** [LibCustomGlow-1.0](https://www.curseforge.com/wow/addons/libcustomglow) (bundled in `Libs/`).

**Compatibility:** WoW 12.0+ (The War Within and beyond)
