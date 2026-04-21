# Changelog

All notable changes to this project will be documented in this file.

## [2.1.1] - 2026-04-21

### Fixed
- **Secret Number Crash**: Fixed a Lua error when comparing cooldown timing values in tainted execution environments (introduced by 12.0.5 manual GCD detection). Re-implemented `isOnGCD` check using the safe boolean field provided by `C_Spell.GetSpellCooldown`.
- **Max Charges Logic**: Fixed a bug where multi-charge spells would incorrectly glow during the GCD even if they only had 1/2 charges available. The "Glow at Max Charges Only" behavior is now strictly enforced even during Global Cooldown transitions.
- **Item Safety**: Wrapped item cooldown magnitude comparisons in `pcall` to ensure stability if item cooldowns also become restricted in future 12.x patches.

## [2.1.0] - 2026-04-21

### Added
- **Charge Caching Optimization**: Implemented a performance-critical cache that identifies non-charge spells (like interrupts) during spellbook scans. This allows the addon to skip redundant `C_Spell.GetSpellCharges` API calls during the high-precision polling loop, significantly reducing CPU overhead.
- **State-Locking Logic**: Added a detection layer to prevents "invisible" or flickering glows caused by rapid state oscillation. The addon now ensures a glow animation completes its burst cycle before any logic-driven restarts are allowed.

### Changed
- **WoW 12.0.5 Compatibility**: Refactored core cooldown tracking to handle the new return structure of `C_Spell.GetSpellCooldown(spellID)`, which now returns a table instead of individual values.
- **Precision GCD Protection**: Implemented a manual GCD detection mechanism by comparing current cooldown durations against the dummy GCD spell (ID 61304), accurately replacing the deprecated `isOnGCD` field in the `C_Spell` namespace.
- **Ultra-High Visibility**: Elevated glow frames to the `TOOLTIP` strata and `+50` internal frame level. This ensures glows remain visible over the top of the refactored 12.0.5 action bar HUD textures.
- **Namespace Migration**: Ported all `IsSpellTrackable` functions to the modern `C_SpellBook` namespace to align with Blizzard's 12.0 API deprecations.

## [2.0.0] - 2026-03-29

### Changed
- **Architecture Overhaul**: Transitioned from a reactionary `SPELL_UPDATE_COOLDOWN` event-driven model to a continuous `0.1s` precision background polling loop. This completely eliminates 2-3 second API throttling delays that previously prevented glows from appearing instantly when an ability returned from cooldown.
- **Static Action Configurations**: The addon no longer attempts to dynamically scan the user's action bars to guess button locations. Users must now explicitly define which `Action Button` a tracked spell or item should anchor its glow to during registration via the UI.
- **Dynamic Spec Evaluation**: Replaced giant spellbook scanning caches with immediate, real-time `IsSpellTrackable` evaluations. Cooldown loops intelligently skip tracking abilities the player is currently not assigned/specced into, driving CPU overhead down to near zero.

### Fixed
- Fixed visual layout clipping in the Options UI where the unlearned text would squish underneath action buttons.
- Fixed UI formatting logic expanding the horizontal tracking grid layout from `470px` to `540px` seamlessly.
- Fixed an edge case where `/cdg test` glows would be instantly cleared by the new `0.1s` active background suppression sweeps.

## [1.3.0] - 2026-03-29

### Changed
- **Zero-Dependency Glow System**: Removed LibCustomGlow-1.0 and LibStub. The addon now includes a self-contained proc glow system ported directly from LibCustomGlow's ProcGlow logic. This eliminates all cross-addon library conflicts and "nil value" errors.
- **Combat Performance**: Completely reworked event handling during combat. Structural updates (spellbook rescans, action bar cache rebuilds) are now fully deferred during combat, except for stance/mount changes which get a single throttled pass every 5 seconds.
- **WoW 12.0+ Only**: Removed all legacy 11.x/10.x fallback code. The addon now exclusively targets WoW 12.0 (Midnight) and later.

### Added
- **`/cdg test` command**: Triggers glows on all tracked buttons for immediate visual verification. Respects configured durations and colors.
- **`/cdg cache` command**: Displays the spell/item → button mapping for debugging.
- **Debug toggle**: Toggleable debug logging in the General settings tab.
- **Custom glow colors**: Desaturation + VertexColor technique for accurate custom colors on Blizzard's native flipbook textures.

### Fixed
- **Taint error**: Fixed `attempt to compare field 'currentCharges' (a secret number value)` by switching to `isActive` (a NeverSecret boolean).
- **Item duration shadowing**: Fixed a bug where item glow durations used the API cooldown duration instead of the user's configured value.
- **Combat spam**: Eliminated excessive "Scanned spellbook" and "Caches invalidated" log spam during encounters.
- **Settings in combat**: `/cdg` now gracefully defers opening settings until combat ends.

### Removed
- LibCustomGlow-1.0 dependency
- LibStub dependency
- `Libs/` directory and `make libs` build step
- Legacy `CDglowDB` migration code

## [1.2.1] - 2026-02-24

### Fixed
- **Race Condition**: Fixed a bug where glows would flicker off during the Global Cooldown (GCD).
- **Usability Logic**: Removed resource/usability detection (mana, runes, etc.) to simplify behavior. Glows now persist through temporary "unusable" states like GCD or resource dips.
- **Combat Only Bug**: Fixed a bug where entering combat would cause every spell to glow if "Combat Only" mode was enabled.
- **Persistence**: Fixed a bug where glows would sometimes re-trigger after the timer expired.
- **Item Tracking**: Improved item cooldown detection to be more robust.

### Changed
- Refactored core glow transition logic to be purely cooldown-driven.
- Glows now trigger exactly once when a spell/item finishes its real cooldown and will only stop when the timer expires or the spell is cast again.
- Relying on Blizzard's `isOnGCD` flag for cleaner major cooldown detection.

## [1.2.0] - 2026-02-24

### Added
- **Spell/Item Helper UI**: New searchable interface to easily add tracked entries from your spellbook or action bars.
- **Extended Documentation**: Comprehensive `README.md` and `DESIGN.md` documentation.

### Fixed
- UI layout fixes in the Options panel.
- Improved button cache invalidation on talent changes.

## [1.1.0] - 2026-02-24

### Changed
- **Taint Safety**: Major refactor of cooldown tracking to avoid protected API calls and ensure compatibility with WoW 12.0 (Midnight).
- **Charge Logic**: Simplified charge handling to rely on visual button state for multi-charge spells.

### Fixed
- Fixed potential memory leaks related to button scanning.
- Improved performance of the core `OnUpdate` loop.

## [1.0.0] - 2026-02-03

### Added
- Initial release.
- Core spell and item cooldown tracking.
- Proc glow integration for action bar buttons.
- Class and Character profile system.
- Basic configuration UI for duration and glow colors.
