# Changelog

All notable changes to this project will be documented in this file.

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
