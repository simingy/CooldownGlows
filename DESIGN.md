# CooldownGlows — Design Notes & Constraints

Lessons learned building this addon. Reference if recreating.

## Core Architecture

**Polling-driven precision.** Relies entirely on a constant 10 Hz (0.1s interval) background evaluation loop inside `Core.lua`. The reactionary `SPELL_UPDATE_COOLDOWN` event paradigm inherently falls victim to throttling lag queues (2-3 second delays); evaluating natively guarantees perfect timing mappings without missing edge frames.

**Data format.** Profile entries are `{duration=N, color="key"}` tables.

**State-transition glows, not instant.** Glows only fire on the transition from on-cooldown → off-cooldown (via `cdStates` / `itemCdStates` tables). Without this, entering combat with a ready ability triggers an unwanted glow.

**Profile resolution: char > class.** Character profiles (`char:Name-Realm`) override class profiles (`DEATHKNIGHT`). Stored in `CooldownGlowsDB`. If no char profile, falls back to class. Profile switches wipe glow state and cancel active timers.

**Charge handling.** Spells with charges (e.g. Fire Blast) only glow when maximum charges are reached. This is determined via the `isActive` boolean on `C_Spell.GetSpellCharges()`, which is `NeverSecret` and safe to read in combat. No custom charge threshold support; max charges only.

**Self-contained glow system.** The addon includes its own proc glow implementation in `Glows.lua`, ported from LibCustomGlow-1.0's ProcGlow logic. It uses Blizzard's native Flipbook atlases (`UI-HUD-ActionBar-Proc-Start-Flipbook`, `UI-HUD-ActionBar-Proc-Loop-Flipbook`) with `SetDesaturated(1)` + `SetVertexColor()` for custom colors. Glow frames are managed via `CreateFramePool` for memory efficiency.

## What Works

- **Explicit Assignment Hooks** — Eliminates native action bar UI scanning completely; users statically build mapping caches associating spell IDs with absolute Frame strings (`MultiBarBottomRightButton10`). This entirely eliminates `C_ActionBar.GetActionDisplayCount` dependencies and native UI latency.
- **Dynamic Spec Check Bypass** — Evaluates active specialization status and omits background processing for currently inactive array bindings cleanly.
- **`C_Spell.GetSpellCooldown(spellID).isOnGCD`** — `NeverSecret = true`, safe to read in combat
- **`C_Spell.GetSpellCooldown(spellID).isActive`** — `NeverSecret = true`, safe boolean for CD state
- **`C_Spell.GetSpellCharges(spellID).isActive`** — `NeverSecret = true`, safe boolean for charge state
- **`C_Item.GetItemCooldown(itemID)`** — returns start, duration, enable
- **Self-contained ProcGlow** with `SetDesaturated(1)` + `SetVertexColor()` — accurate custom colors, no library conflicts
- **`CreateFramePool("Frame", UIParent, nil, resetter)`** — efficient glow frame pooling
- **`InCombatLockdown()` guard** before `ScanActionBarItems()` — `GetActionInfo` can taint in combat
- **`C_Timer.NewTimer`** for glow duration auto-hide — cancellable
- **`SetScript("OnUpdate", handler)` toggling** for debouncing — zero cost when idle
- **Settings API**: `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` (WoW 12.0+)

## What Doesn't Work

- **`C_Spell.GetSpellCastCount(spellID)`** — `SecretWhenSpellCooldownRestricted = true`. Returns a secret number in combat; any math or comparison causes a Lua error.
- **`C_Spell.GetSpellCharges(spellID).currentCharges`** — Secret number in combat. Cannot read charge counts.
- **`C_ActionBar.GetActionDisplayCount(slot)`** — `SecretWhenActionCooldownRestricted = true`. Secret in combat.
- **`pcall` around secret values** — Does NOT help. The error occurs when the value is *used*, not when the API is called.
- **`btn.Count:GetText()` for charge scraping** — Unreliable timing, race conditions with UI updates.
- **`GetMacroItem(macroIndex)`** — unreliable for conditional macros, returns nil.
- **LibCustomGlow as shared library** — Version conflicts and initialization bugs (`lib` variable shadowing) cause `ProcGlow_Start` to be nil when multiple addons share the library. Solved by inlining the glow logic.
- **`ActionButton_ShowOverlayGlow`** — Removed in WoW 12.0. Replaced by `ActionButtonSpellAlertManager`.
- **`InterfaceOptionsFrame_OpenToCategory`** — Removed in WoW 12.0. Use `Settings.OpenToCategory()`.

## Combat Event Strategy

| Event | Out of Combat | In Combat |
|-------|---------------|-----------|
| `SPELL_UPDATE_COOLDOWN` / `SPELL_UPDATE_CHARGES` | 50ms debounced check | 50ms debounced check |
| `SPELLS_CHANGED` / `PLAYER_TALENT_UPDATE` | Immediate rescan | Deferred to `PLAYER_REGEN_ENABLED` |
| `ACTIONBAR_SLOT_CHANGED` | Immediate rescan | Deferred to `PLAYER_REGEN_ENABLED` |
| `UPDATE_BONUS_ACTIONBAR` (stance/mount) | Immediate rescan | One pass allowed (5s throttle) |
| `PLAYER_REGEN_ENABLED` | — | Flushes all pending updates |

## UI Constraints

- **Tab-based settings page**: General | Class Profile | Character Profile. Active profile gets green `(Active)` badge.
- **Spell/Item rows are rendered in split tables**: Spells list on top, Items list below, each with column headers (Name, ID, Duration, Color, Action) and Add buttons.
- **Color swatches** in tracked list are static display only; default colors show the text "Default".
- **Helper popups** (Spell/Item) anchor to right of SettingsPanel, are draggable, click-to-fill, and manage both Add and Edit states.
- **Edit flow**: Clicking an Edit button in the tracked lists opens the corresponding Helper UI in Edit Mode, pre-filled, with a "Save" button to overwrite the entry.
- **Tracked list**: spells white, items gold, unknown spells and off-bar items grayed with status text.

## WoW 12 API Notes

- **`C_SpellBook`** — `GetSpellBookSkillLineInfo`, `GetSpellBookItemType` with `Enum.SpellBookSpellBank.Player`
- **`SpellCooldownInfo.isOnGCD`** — `NeverSecret = true`. Safe to read even when the rest of the struct is secret.
- **`SpellCooldownInfo.isActive`** — `NeverSecret = true`. Boolean indicating whether a cooldown is active.
- **Explicit UI Overrides** — `ActionBarButtonEventsFrame` scanning logic has been aggressively deprecated from Core engine checks due to performance leaks.
- **`C_Item.GetItemInfo`** is async — may return nil on first call. Items resolve on next refresh.
- **SavedVariables** (`CooldownGlowsDB`) — not available until `ADDON_LOADED`. Unregister after processing.
- **`wipe(table)`** instead of reassigning — preserves references held by other code.

## File Responsibilities

| File | Role | Key constraint |
|------|------|---------------|
| `Core.lua` | Events, profile init, slash cmds | Loaded last (depends on all others). Unregisters ADDON_LOADED after init. |
| `Glows.lua` | Color palette, self-contained proc glow, `ApplyGlowTransition` | Loaded first. Zero dependencies. |
| `ActionBars.lua` | (DEPRECATED) Legacy auto-discovery cache framework. Functionality migrated natively to Options Profile registrations. |
| `Cooldowns.lua` | CD state tracking, charge detection, glow triggers | State-transition only. Uses `isActive` boolean, not secret numbers. |
| `OptionsUI.lua` | Tab UI, color dropdowns, profile editing | Stores `addon.OptionsFrame` for helper hooks |
| `SpellHelperUI.lua` | Spellbook browser | Filters passives, sorts alpha. |
| `ItemHelperUI.lua` | Action bar item browser | Only shows `actionType=="item"` |
