# Changelog

## [1.1.0] - 2026-04-10
- add Paragon Rewards list: shows factions with a pending paragon reward box
- list is only visible when rewards are available, hidden otherwise
- list is draggable and freely positionable on screen
- add settings under /tfb > Paragon Rewards:
  - enable/disable the list entirely
  - grow direction: list grows down (header top) or up (anchor bottom, header top)
  - text alignment: left or right
  - faction color or white for faction names
  - show/hide background
  - hide in competitive content (dungeons, raids, battlegrounds, arenas, delves)
  - lock position to prevent accidental dragging
  - test mode: shows placeholder entries for positioning

## [1.0.0] - 2026-03-06
- add Blizzard AddOn Options Panel (accessible via /tfb or ESC > Options > AddOns)
- add bar position presets: Top of Screen, Bottom of Screen, Below Chat Window, Free Position
- add free positioning mode with drag & drop support and lock option
- add configurable bar height and bar width (free position mode)
- add Y-Offset slider with manual input field for precise positioning
- add text position (top/bottom) and text alignment (left/center/right) options for free position mode
- add option to keep the Blizzard experience bar while showing the playtime bar simultaneously
- add option to control whether text follows the Y-Offset or stays at default position

## [0.6.0] - 2026-03-05
- add housing XP (favor) tracking with bar display at max level
- show house level, current/max favor and progress percentage for 60 seconds on favor gain

## [0.5.0] - 2026-03-02
- show total playtime across all characters for the current expansion on /played
- fix reputation bar not showing for factions marked as headers (e.g. Silvermoon Court)

## [0.4.2] - 2026-03-02
- fix max skill level display for secondary professions (Fishing, Cooking, Archaeology) using per-expansion lookup table

## [0.4.1] - 2026-02-25
- switch from max level bar back to exp bar when a new expansion starts

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
