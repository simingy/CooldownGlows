# CooldownGlows — Design Notes & Constraints

Lessons learned building this addon. Reference if recreating.

## Core Architecture

**Event-driven, cache-first.** Cooldown events (`SPELL_UPDATE_COOLDOWN`, `BAG_UPDATE_COOLDOWN`) only *read* cached button lookups. Cache rebuilds happen on bar-change events (`ACTIONBAR_SLOT_CHANGED`, etc.) with a 0.5s debounce via `OnUpdate`. The `OnUpdate` self-disables when not dirty to avoid per-frame waste.

**Data format.** Profile entries are `{duration=N, color="key"}` tables. Old number-format entries (`spells[id] = 3`) are auto-migrated on load.

**State-transition glows, not instant.** Glows only fire on the transition from on-cooldown → off-cooldown (via `cdStates` / `itemCdStates` tables). Without this, entering combat with a ready ability triggers an unwanted glow.

**Profile resolution: char > class.** Character profiles (`char:Name-Realm`) override class profiles (`DEATHKNIGHT`). Stored in `CooldownGlowsDB`. If no char profile, falls back to class.

## What Works

- **`C_ActionBar.FindSpellActionButtons(spellID)`** — reliable for mapping spells to action slots
- **`GetActionInfo(slot)` with `actionType == "item"`** — reliable for direct item slots
- **`btn.cooldown:IsShown()`** — simple, universal cooldown check for both spells and items
- **`C_Spell.GetSpellCooldown(spellID).isOnGCD`** — needed to distinguish real CDs from GCD
- **`C_Item.GetItemCount(id) > 0 and C_Item.IsUsableItem(id)`** — item readiness check (matches ProcGlows)
- **LibCustomGlow `ProcGlow_Start/Stop`** with a `key` parameter — allows coexistence with other glow addons
- **`ProcGlow_Start` `options.color = {r,g,b,a}`** — desaturates texture and applies vertex color; nil = default gold
- **`btn["_ProcGlow" .. key]`** — LibCustomGlow sets this on the button; use it to check if already glowing
- **`InCombatLockdown()` guard** before `ScanActionBarItems()` — `GetActionInfo` can taint in combat
- **`C_Timer.After`** for glow duration auto-hide — clean, cancellable
- **`OnUpdate` frame for High-Frequency Debouncing** — Using `C_Timer.NewTimer` to debounce `SPELL_UPDATE_COOLDOWN` generates massive Lua garbage in M+ combat. A persistent `OnUpdate` frame with a boolean flag creates zero garbage allocations.
- **`UIDropDownMenuTemplate`** — works well for color pickers with small fixed palettes
- **WoW Settings API**: `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` for TWW

## What Doesn't Work

- **`GetMacroItem(macroIndex)`** — unreliable for detecting items inside macros; returns nil for conditional macros. Tried `C_TooltipInfo.GetAction(slot)` fallback too — also inconsistent. Just use manual Item ID input.
- **`and/or` ternary for booleans** — `x and func() or default` breaks when `func()` returns `false`. Use explicit `if/else`. Burned us on `IsItemOnActionBar`.
- **`UIDropDownMenuTemplate`** for item selection — worked but user preferred manual ID input + helper popup for consistency with spell workflow.
- **Submenu pages per class** — cluttered the settings panel. Tab-based single page is cleaner.
- **`UnitName` + `GetRealmName` for char keys** — reliable after `ADDON_LOADED`; store as `"char:Name-Realm"` prefix.
- **`InterfaceOptionsFrame_OpenToCategory`** — deprecated in TWW, use `Settings.OpenToCategory(category:GetID())` with fallback.

## UI Constraints

- **Tab-based settings page**: General | Class Profile | Character Profile. Active profile gets green `(Active)` badge.
- **Spell/Item rows are rendered in split tables**: Spells list on top, Items list below, each with headers and Add buttons.
- **Color swatches** in tracked list are static display only; default colors show the text "Default".
- **Helper popups** (Spell/Item) anchor to right of SettingsPanel, are draggable, click-to-fill, and manage both Add and Edit states.
- **Edit flow**: Clicking an Edit button in the tracked lists opens the corresponding Helper UI in Edit Mode, pre-filled, with a "Save" button to overwrite the entry.
- **Tracked list**: spells white, items gold, unknown spells and off-bar items grayed with status text.

## WoW API Gotchas

- **`C_SpellBook` is TWW-only** — `GetSpellBookSkillLineInfo`, `GetSpellBookItemType` with `Enum.SpellBookSpellBank.Player`
- **`ActionBarButtonEventsFrame.frames`** — primary button source, but also scan `_G["ButtonPrefix"..i]` as fallback for addon bars. Deduplicate with a `seen` set. **Always verify `type(button) == "table"`**, as poorly-written addons can pollute this array with strings or booleans, causing instant taint crashes.
- **`C_Item.GetItemInfo`** is async — may return nil on first call. Fine for display; items resolve on next refresh.
- **SavedVariables** (`CooldownGlowsDB`) — not available until `ADDON_LOADED`. Don't init globals before that.
- **`wipe(table)`** instead of reassigning — preserves references held by other code.

## File Responsibilities

| File | Role | Key constraint |
|------|------|---------------|
| `Core.lua` | Events, profile init, migration, slash cmds | Loaded last (depends on all others) |
| `Glows.lua` | Color palette, LCG wrapper, `ApplyGlowTransition` | Loaded first after libs |
| `ActionBars.lua` | Spell/item → button cache | No combat scanning |
| `Cooldowns.lua` | CD state tracking, glow triggers | State-transition only |
| `OptionsUI.lua` | Tab UI, color dropdowns, profile editing | No per-class subpages |
| `SpellHelperUI.lua` | Spellbook browser | Filters passives, sorts alpha |
| `ItemHelperUI.lua` | Action bar item browser | Only shows `actionType=="item"` |
