# CooldownGlows — Design Notes & Constraints

Lessons learned building this addon. Reference if recreating.

## Core Architecture

**Event-driven, cache-first.** Cooldown events (`SPELL_UPDATE_COOLDOWN`, `SPELL_UPDATE_CHARGES`, `BAG_UPDATE_COOLDOWN`) trigger a 100ms debounced check via `OnUpdate`. The `OnUpdate` handler self-disables (`SetScript("OnUpdate", nil)`) when not active to avoid per-frame waste. Cache rebuilds happen on bar-change events (`ACTIONBAR_SLOT_CHANGED`, etc.) with a 0.5s debounce.

**Data format.** Profile entries are `{duration=N, color="key"}` tables. Old number-format entries (`spells[id] = 3`) are auto-migrated on load.

**State-transition glows, not instant.** Glows only fire on the transition from on-cooldown → off-cooldown (via `cdStates` / `itemCdStates` tables). Without this, entering combat with a ready ability triggers an unwanted glow.

**Profile resolution: char > class.** Character profiles (`char:Name-Realm`) override class profiles (`DEATHKNIGHT`). Stored in `CooldownGlowsDB`. If no char profile, falls back to class. Profile switches wipe glow state and cancel active timers.

**Charge handling.** Spells with charges (e.g. Fire Blast) only glow when they reach maximum charges. This is determined purely through visual UI state — `btn.chargeCooldown:IsShown()` — which avoids calling any taint-restricted API. No custom charge threshold support; max charges only.

## What Works

- **`C_ActionBar.FindSpellActionButtons(spellID)`** — reliable for mapping spells to action slots
- **`GetActionInfo(slot)` with `actionType == "item"`** — reliable for direct item slots
- **`btn.cooldown:IsShown()`** — simple, universal cooldown check for both spells and items (not protected)
- **`btn.chargeCooldown:IsShown()`** — visual charge cooldown check (not protected, doesn't trigger for GCD)
- **`C_Spell.GetSpellCooldown(spellID).isOnGCD`** — needed to distinguish real CDs from GCD. The `.isOnGCD` field is `NeverSecret = true` per API docs, so it's safe to read in combat even though the parent struct is secret-restricted
- **`C_Spell.IsSpellUsable(spellID)`** — usability check, `SecretArguments = "AllowedWhenTainted"` (our addon is always tainted), no `SecretWhenSpellCooldownRestricted`, safe in combat
- **`C_Item.GetItemCount(id) > 0 and C_Item.IsUsableItem(id)`** — item readiness check
- **LibCustomGlow `ProcGlow_Start/Stop`** with a `key` parameter — allows coexistence with other glow addons
- **`ProcGlow_Start` `options.color = {r,g,b,a}`** — desaturates texture and applies vertex color; nil = default gold
- **`btn["_ProcGlow" .. key]`** — LibCustomGlow sets this on the button; use it to check if already glowing
- **`InCombatLockdown()` guard** before `ScanActionBarItems()` — `GetActionInfo` can taint in combat
- **`C_Timer.After`** for glow duration auto-hide — clean, cancellable
- **`SetScript("OnUpdate", handler)` toggling** for debouncing — enables only when needed, zero cost when idle. Cheaper than a persistent boolean-flag OnUpdate since it avoids per-frame Lua calls entirely
- **Settings API**: `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` (WoW 12.0+)

## What Doesn't Work

- **`C_Spell.GetSpellCastCount(spellID)`** — `SecretWhenSpellCooldownRestricted = true`. Returns a secret number in combat; any math or comparison on it causes a Lua error. Cannot be used for custom charge tracking.
- **`C_Spell.GetSpellCharges(spellID)`** — Same restriction. Returns secret struct in combat. `currentCharges` and `maxCharges` are secret numbers. Cannot read charge counts in combat.
- **`C_ActionBar.GetActionDisplayCount(slot)`** — `SecretWhenActionCooldownRestricted = true`. Also returns secret values in combat.
- **`pcall` around secret values** — Does NOT help. The error occurs when the secret value is *used* (compared, stored), not when the API is called. `pcall` catches the call but not subsequent usage.
- **`btn.Count:GetText()` for charge scraping** — Works for display but unreliable for glow logic. The UI text may not be updated when events fire, leading to race conditions.
- **Custom charge thresholds** — Removed. No reliable way to read current charge count in combat. The addon now only supports "max charges" via the visual `chargeCooldown:IsShown()` approach.
- **`GetMacroItem(macroIndex)`** — unreliable for detecting items inside macros; returns nil for conditional macros
- **`InterfaceOptionsFrame_OpenToCategory`** — removed in WoW 12.0. Use `Settings.OpenToCategory(category:GetID())` directly
- **`InterfaceOptions_AddCategory`** — removed in WoW 12.0. Use `Settings.RegisterCanvasLayoutCategory`
- **`UIDropDownMenuTemplate`** — still functional via compat layer in 12.0, but deprecated. Consider migrating to `MenuUtil` in a future version

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
- **`ActionBarButtonEventsFrame.frames`** — primary button source, but also scan `_G["ButtonPrefix"..i]` as fallback for addon bars. Deduplicate with a `seen` set. **Always verify `type(button) == "table"`**, as poorly-written addons can pollute this array.
- **`C_Item.GetItemInfo`** is async — may return nil on first call. Fine for display; items resolve on next refresh.
- **SavedVariables** (`CooldownGlowsDB`) — not available until `ADDON_LOADED`. Don't init globals before that. Unregister `ADDON_LOADED` after processing.
- **`wipe(table)`** instead of reassigning — preserves references held by other code.

## File Responsibilities

| File | Role | Key constraint |
|------|------|---------------|
| `Core.lua` | Events, profile init, migration, slash cmds | Loaded last (depends on all others). Unregisters ADDON_LOADED after init. |
| `Glows.lua` | Color palette, LCG wrapper, `ApplyGlowTransition` | Loaded first after libs |
| `ActionBars.lua` | Spell/item → button cache | No combat scanning (`InCombatLockdown` guard) |
| `Cooldowns.lua` | CD state tracking, charge detection, glow triggers | State-transition only. Uses visual cooldown state, not protected APIs. |
| `OptionsUI.lua` | Tab UI, color dropdowns, profile editing | Stores `addon.OptionsFrame` for helper hooks |
| `SpellHelperUI.lua` | Spellbook browser | Filters passives, sorts alpha. Single event frame for SPELLS_CHANGED. |
| `ItemHelperUI.lua` | Action bar item browser | Only shows `actionType=="item"` |
