# Antigravity Guidelines for CooldownGlows

These guidelines ensure consistency, performance, and compatibility for the CooldownGlows project.

## 1. Version Support (WoW 12.0+ / Midnight Only)
- **MIDNIGHT ONLY**: This addon exclusively supports WoW version 12.0+ (Midnight and onwards). 
- **NO LEGACY CODE**: Do not include fallbacks for 10.x or 11.x APIs. Use the most modern `C_Spell`, `C_Item`, and `C_ActionBar` namespaces for all logic.
- **TOC**: Maintain `Interface: 1200XX` in the `.toc` file.

## 2. Dependencies & Libraries
- **ZERO EXTERNAL DEPENDENCIES**: This addon has no external library dependencies. Do not introduce `LibStub`, `LibCustomGlow`, or similar shared libraries.
- **SELF-CONTAINED GLOW**: The proc glow system is ported directly from LibCustomGlow's ProcGlow logic into `Glows.lua`. It uses Blizzard's Flipbook atlases with Desaturation + VertexColor for custom colors. All glow logic lives in this single file.
- **NO `Libs/` DIRECTORY**: The build system does not fetch any external libraries. If a `Libs/` folder exists, it is stale and should be deleted.

## 3. WoW API Compatibility (12.0/Midnight)
- **Secret Values**: In WoW 12.0, certain UI data (spell charges, cooldown durations) can be "Secret". Comparing these values directly causes taint errors.
  - **Rule**: Use `NeverSecret` fields like `isActive` or `isOnGCD` whenever possible.
  - **Rule**: Never compare secret numbers with `<` or `>`. Use boolean fields instead.
- **Data-Driven API**: Prefer `C_Spell` and `C_Item` APIs over UI frame inspection for cooldown detection.

## 4. Performance & Combat Safety
- **Event Strategy**: Due to heavy internal throttling of standard Blizzard events like `SPELL_UPDATE_COOLDOWN` producing multi-second lag queues:
  - We exclusively rely on an active background `0.1s` (10Hz) polling loop tied to the `OnUpdate` handler.
  - Native Event bindings are purely restricted to explicit UI refresh hooks (`SPELLS_CHANGED`, `PLAYER_ENTERING_WORLD`) forcing cache rebuilds outside of combat.
- **Cooldown Polling**: CD checks natively utilize explicit Button frame strings assigned mathematically in the SV tables rather than trying to perform `C_ActionBar` loop lookups, making `10Hz` polling virtually frictionless logic sweeps.
- **Debug Logging**: All debug prints gated behind `addon.Profile.debug` and `addon.Print` helper. Never spam during combat.

## 5. UI & Aesthetics
- **Glow Frame Level**: Proc glow frames use `button:GetFrameLevel() + 8` to appear above action bar overlays.
- **Color System**: Colors are defined in `addon.GLOW_COLORS` (array) and `addon.GLOW_COLOR_MAP` (lookup). Custom colors use `SetDesaturated(1)` + `SetVertexColor()`. `nil` color = default Blizzard yellow.

## 6. Troubleshooting Tools
- `/cdg cache` — View spell/item → button mappings.
- `/cdg test` — Trigger all tracked glows with configured durations and colors.
- Debug toggle in General settings tab.

## 7. File Responsibilities

| File | Role |
|------|------|
| `Glows.lua` | Color palette, self-contained glow system, `ApplyGlowTransition`. Loaded first. |
| `ActionBars.lua` | Spell/item → button cache. `InCombatLockdown` guard on item scans. |
| `Cooldowns.lua` | CD state tracking, charge detection, glow triggers. State-transition only. |
| `SpellHelperUI.lua` | Spellbook browser for adding tracked spells. |
| `ItemHelperUI.lua` | Action bar item browser for adding tracked items. |
| `OptionsUI.lua` | Tab-based settings UI, color dropdowns, profile editing. |
| `Core.lua` | Events, profile init, slash commands. Loaded last. |
