# Changelog

## [0.4.0] - 2026-02-25
- switch expansion detection from build version string to GetExpansionLevel() API
- expansion tracking now works correctly across pre-patches where the build version doesn't match the active expansion
- migrate existing playtime data from version-string-based keys to expansion-level-based keys (no data loss)
- add DB version system for future-proof migrations
- automatically re-track playtime when expansion level changes (e.g. Midnight launch)
- show raid warning message when a new expansion is detected

## [0.3.1] - 2026-02-25
- hide Blizzard's status tracking bar on tutorial island (thx blizz for using a different ui there)
- refactor color handling in reputation module to use color utility functions

## [0.3.0] - 2026-02-20
- add profession skill-up tracking with bar display
- show profession name, current/max skill and progress on skill-up
- support expansion-specific skill tiers for all professions (including fishing, cooking and archaeology)

## [0.2.0] - 2026-02-19
- add reputation tracking and notifications
- fix some bugs
- it's possible to set an y-offset for the bar with /tfb offset {number} (need to /reload to take affact). I added this a a temporary fix for a user with a macbook and ui shifted below the nodge. This will be removed again in a later version.

## [0.1.3] - 2026-02-15
- fix problem with switching bar from exp to played when reaching max level

## [0.1.2] - 2026-02-15
- Autodetect time played in current expansion based on time played at level. This is not perfect, but should be close enough for most of the max level characters.

## [0.1.0] - 2026-02-14
- First Version
- Add time tracking over expansions
- ExpBar with time to next level
- PlayedBar for max level chars
