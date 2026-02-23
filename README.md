# CooldownGlows

A lightweight World of Warcraft addon that highlights action bar buttons with a proc glow when spells come off cooldown.

## Features

### Core
- **Cooldown Glow Tracking** — Action bar buttons glow when a tracked spell finishes its cooldown or regains charges. GCD activations are ignored to prevent false positives.
- **Configurable Glow Duration** — Set how long the glow persists (in seconds) per spell. A duration of `0` means it glows indefinitely until the spell is cast again.
- **Combat Only Mode** — Optionally restrict glows to combat only, keeping your UI clean in towns.

### Profiles & Configuration
- **Per-Class Profiles** — Each class gets its own independent spell list, managed automatically based on your character's class.
- **Native Settings Integration** — Fully integrated into the Blizzard Addon Settings panel with a main page and per-class subcategories.
- **Profile Management** — View all saved class profiles from the main settings page with active/off-spec indicators, spell counts, and the ability to delete profiles.
- **Spell Helper** — A built-in searchable spellbook browser that lists all your active, non-passive spells with their IDs. Click a spell to auto-fill the input fields.

### UI Polish
- **Class-Colored Titles** — Profile headers use your class color for quick identification.
- **Column Headers & Sorting** — Spell lists display with labeled columns (Spell, ID, Duration) and are sorted alphabetically.
- **Known Spell Indicators** — Spells not currently learned on your character are grayed out with a "(not learned)" tag.
- **Empty State Messaging** — Helpful prompt when a profile has no spells configured yet.
- **Optimistic UI Loading** — Spell lists render instantly from the database; spellbook validation runs in the background without blocking the UI.

### Performance
- **Action Bar Cache Throttling** — The button scanner is throttled to avoid UI stutter when rapidly changing action bars, mounting vehicles, or swapping specs.
- **Timer Safety** — Glow timers are properly cancelled before re-application to prevent overlapping timers and memory leaks.

## Usage

```
/cooldownglows  or  /cdg
```

Opens the settings panel. Click your class profile to add or remove tracked spells.

To add a spell manually: enter its **Spell ID** and a **duration** (seconds), then click **Add**. Use the **Spell Helper** button to browse your spellbook if you don't know the ID.

## File Structure

| File | Purpose |
|------|---------|
| `Core.lua` | Initialization, event handling, slash commands |
| `Glows.lua` | LibCustomGlow wrapper functions and timer management |
| `ActionBars.lua` | Action bar scanning and button lookup cache |
| `Cooldowns.lua` | Cooldown tracking engine and known-spell synchronization |
| `SpellHelperUI.lua` | Searchable spellbook browser window |
| `OptionsUI.lua` | Settings panel, profile management, and spell list UI |

## Requirements

Bundled dependencies (no additional downloads needed):
- `LibStub`
- `LibCustomGlow-1.0`
