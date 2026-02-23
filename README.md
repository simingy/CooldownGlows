# CooldownGlows

Highlights action bar buttons with a proc glow when spell/item cooldowns finish.

## Features

- **Spell tracking** — Add spells by ID, glow when cooldown ends
- **Item tracking** — Add items by ID, glow when usable and off cooldown
- **Glow colors** — Choose from 10 colors (Default, White, Red, Green, Blue, Yellow, Orange, Purple, Pink, Cyan)
- **Per-class profiles** — Separate spell/item lists per class
- **Per-character profiles** — Override class profile for specific characters
- **Duration control** — Auto-hide glow after configurable seconds
- **Combat-only mode** — Suppress glows outside combat
- **Spell/Item helpers** — Browse spellbook or action bar items to find IDs

## Usage

- `/cdg` — Open settings (deferred if in combat)
- **General tab** — Combat-only toggle, active profile info
- **Class tab** — Edit spell/item list for your class
- **Character tab** — Create/delete a character-specific override

Each tracked entry has a **color swatch** you can click to cycle colors inline.

## Install

Copy `CooldownGlows/` into your `Interface/AddOns/` folder.

**Requires:** [LibCustomGlow-1.0](https://www.curseforge.com/wow/addons/libcustomglow) (bundled in `Libs/`).

## Architecture

| File | Purpose |
|------|---------|
| `Core.lua` | Event handling, profile resolution, data migration, slash commands |
| `Glows.lua` | Color palette, LibCustomGlow wrapper, shared glow transition logic |
| `ActionBars.lua` | Button-to-slot caching for spells and items |
| `Cooldowns.lua` | Cooldown state tracking, glow triggers |
| `OptionsUI.lua` | Tab-based settings UI with color dropdowns |
| `SpellHelperUI.lua` | Spellbook browser popup |
| `ItemHelperUI.lua` | Action bar item browser popup |
