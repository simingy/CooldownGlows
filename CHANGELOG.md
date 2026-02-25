# Changelog

All notable changes to this project will be documented in this file.

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
- **Improved Tooling**: Added `Makefile` for automated build and library fetching.
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
