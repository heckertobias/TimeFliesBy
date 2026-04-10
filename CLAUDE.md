# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development

There is no build step. The AddOn loads directly from this directory into WoW. To test changes:
- Reload the UI in-game: `/reload`
- Open settings: `/tfb`
- View playtime output: `/played`

The `.toc` file (`TimeFliesBy.toc`) controls load order and must list any new `.lua` files.

## Architecture

All modules share a single addon namespace table `tfb` (the second vararg from `local _, tfb = ...`). Each file declares its module on this table (e.g. `tfb.db = {}`, `tfb.WunderBar = {}`). Files are loaded in the order defined in the `.toc`.

**Module overview:**
- `utils/events.lua` — `tfb.events`: Named event multiplexer wrapping WoW's frame event system. Use `tfb.events:Register(event, name, callback)` / `:Unregister(event, name)` instead of registering directly on frames.
- `utils/db.lua` — `tfb.db`: All reads/writes to `TimeFliesByDB` (the SavedVariables table). Contains DB migration logic. Current schema version: 2. Per-character data is keyed by `"Name-Realm"`.
- `utils/character.lua` — `tfb.character`: Player identity helpers (char key, class token, max level check).
- `utils/gameVersion.lua` — `tfb.gameVersion`: Maps expansion levels (integers from `GetExpansionLevel()`) to names. Legacy version-string-based lookup exists only for DB migration.
- `utils/chat.lua` — `tfb.chat`: Chat output and playtime formatting.
- `utils/reputation.lua` — `tfb.reputation`: Detects reputation changes for bar display.
- `utils/skill.lua` — `tfb.skill`: Parses `CHAT_MSG_SKILL` for skill progress display.
- `utils/housing.lua` — `tfb.housing`: Tracks housing XP (favor) changes.
- `WunderBar.lua` — `tfb.WunderBar`: The status bar UI. Two overlapping StatusBar frames (`bar` + `bar2` for rested XP). Supports 4 position presets (Top, Bottom, Below Chat, Free). Free position is draggable and persisted.
- `Settings.lua` — Blizzard AddOn Settings panel (`/tfb`). Reads/writes via `tfb.db` and calls `tfb.WunderBar:Reposition()` on change.
- `TimeFliesBy.lua` — Entry point. Orchestrates bar mode (XP vs. playtime vs. reputation/skill/housing). On `PLAYER_LOGIN`, waits 3 s then calls `RequestTimePlayed()` and initializes the bar.

**Bar mode logic (TimeFliesBy.lua):**
- At max level → playtime bar (class color, 24 h cycle), with temporary overrides for reputation/skill/housing gain events (60 s display window).
- While leveling → XP bar (with rested XP as bar2) and XP/hour estimate.
- If `useBlizzardExpBar` is set → skip custom XP bar entirely; use max-level playtime bar regardless of level.

**SavedVariables schema (`TimeFliesByDB`):**
- `data[charKey].expansions[expansionLevel].{createdAt, lastUpdate}` — playtime in seconds at the time of each `/played` request.
- Top-level keys for settings: `positionPreset`, `yOffset`, `barHeight`, `barWidth`, `freePositionX/Y`, `freePositionLocked`, `textPosition`, `textAlignment`, `textFollowsOffset`, `useBlizzardExpBar`.
