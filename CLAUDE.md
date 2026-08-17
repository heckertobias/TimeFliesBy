# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development

There is no build step and no test suite. The AddOn loads directly from this directory into WoW. To test changes:
- Reload the UI in-game: `/reload`
- Open settings: `/tfb`
- View playtime output: `/played`

The `.toc` file (`TimeFliesBy.toc`) controls load order and must list any new `.lua` files.

Static analysis comes from the Lua language server (`.vscode/settings.json`): runtime is Lua 5.1 with the standard library disabled, and the WoW API is provided by the `ketho.wow-api` annotations extension. Globals not covered by those annotations (e.g. `MainStatusTrackingBarContainer`, `GameRulesUtil`, `ERR_SKILL_UP_SI`) must be added to `Lua.diagnostics.globals` there or they will show as undefined.

## Releasing

- Version lives in `TimeFliesBy.toc` (`## Version`). `## Interface` must be bumped for each game patch.
- `CHANGELOG.md` is maintained by hand (`pkgmeta.yaml` declares `manual-changelog`), newest entry first.
- Releases are tagged `vX.Y.Z`; the tag is what the CurseForge packager consumes. `pkgmeta.yaml` excludes `.vscode`, `.gitignore`, `CLAUDE.md`, `.claude`, and `tools` from the packaged zip. `media/` **is** packaged.
- `tools/generate_jingle.py` regenerates `media/happy-birthday.ogg` (needs `brew install vorbis-tools` for `oggenc`, plus numpy). Tweak the constants at the top of the script and re-run. Note that WoW indexes addon sound files at client start — a newly added `.ogg` will not play until a full restart, `/reload` is not enough.

## Architecture

All modules share a single addon namespace table `tfb` (the second vararg from `local _, tfb = ...`). Each file declares its module on this table (e.g. `tfb.db = {}`, `tfb.WunderBar = {}`). Files are loaded in the order defined in the `.toc`; load order is load-bearing — `Settings.lua` must run before `ParagonList.lua`, because the latter registers its panel as a subcategory of `tfb.settingsCategory`.

**Module overview:**
- `utils/events.lua` — `tfb.events`: Named event multiplexer wrapping WoW's frame event system. Use `tfb.events:Register(event, name, callback)` / `:Unregister(event, name)` instead of registering directly on frames. (`ParagonList.lua` registers on its own container frame instead; it owns that frame's lifecycle.)
- `utils/db.lua` — `tfb.db`: All reads/writes to `TimeFliesByDB` (the SavedVariables table). Contains DB migration logic. Current schema version: 2. Per-character data is keyed by `"Name-Realm"`.
- `utils/character.lua` — `tfb.character`: Player identity helpers (char key, class token, max level check).
- `utils/colors.lua` — `tfb.colors`: Class, XP/rested, faction, renown and friendship bar colors.
- `utils/gameVersion.lua` — `tfb.gameVersion`: Maps expansion levels (integers from `GetExpansionLevel()`) to names. Legacy version-string-based lookup exists only for DB migration.
- `utils/chat.lua` — `tfb.chat`: Chat output and playtime formatting.
- `utils/reputation.lua` — `tfb.reputation`: `GetReputationChange()` walks all factions and returns the one whose value changed since the last call (renown / friendship / classic / paragon are normalized to `{name, standing, current, max, GetColor}`); the first call only primes the cache. `GetParagonRewards()` lists factions with an unclaimed paragon box.
- `utils/skill.lua` — `tfb.skill`: Parses `CHAT_MSG_SKILL` for skill progress display.
- `utils/housing.lua` — `tfb.housing`: Tracks housing XP (favor) changes.
- `utils/instance.lua` — `tfb.instance`: `IsInCompetitiveContent()` — true inside dungeons, raids, battlegrounds, arenas and delves/scenarios. Shared by the Paragon list and the birthday jingle.
- `utils/birthday.lua` — `tfb.birthday`: Fires a jingle each time the character's total played time crosses a 24 h multiple. Stays silent until the first `TIME_PLAYED_MSG` of the session, because until then the DB still holds the value written at the *previous* login and can be hours stale. Its `TIME_PLAYED_MSG` callback uses the event payload rather than the DB, since it runs before the one in `TimeFliesBy.lua` that persists it.
- `WunderBar.lua` — `tfb.WunderBar`: The status bar UI. Two overlapping StatusBar frames (`bar` + `bar2` for rested XP). Supports 4 position presets (Top, Bottom, Below Chat, Free). Free position is draggable and persisted. `HideBlizzStatusBar()` hides *and* unregisters events on `MainStatusTrackingBarContainer`, so it is one-way until `/reload`.
- `Settings.lua` — Blizzard AddOn Settings panel (`/tfb`), a hand-built canvas layout. Registers `tfb.settingsCategory`. Reads/writes via `tfb.db` and calls `tfb.WunderBar:Reposition()` on change.
- `BirthdayJingle.lua` — Canvas settings subcategory for the birthday jingle (enable, sound channel, play-in-competitive, test button). Must load after `Settings.lua`.
- `ParagonList.lua` — `tfb.ParagonList`: Standalone draggable list of factions with a pending paragon reward, plus its own canvas settings subcategory. Refreshed on `UPDATE_FACTION`, `PLAYER_ENTERING_WORLD`, and at init. Auto-hides when empty, disabled, or (optionally) inside instanced competitive content.
- `TimeFliesBy.lua` — Entry point. Orchestrates bar mode (XP vs. playtime vs. reputation/skill/housing). On `PLAYER_LOGIN`, runs DB migration, then waits 3 s before calling `RequestTimePlayed()` (giving other addons a chance to trigger it first, avoiding duplicate `/played` chat spam) and initializing the bar.

**Bar mode logic (TimeFliesBy.lua):**
- At max level → playtime bar (class color, 24 h cycle), driven by a 5 s ticker, with temporary overrides for reputation/skill/housing gain events (60 s display window guarded by the `alternativeWatch` timestamp).
- While leveling → XP bar (with rested XP as bar2) plus a "Next Level in" estimate from a rolling 15-minute XP-rate window that survives level-ups.
- If `useBlizzardExpBar` is set → skip the custom XP bar entirely; use the max-level playtime bar regardless of level.
- `UPDATE_EXPANSION_LEVEL` re-evaluates the mode (e.g. dropping out of max level when a new expansion raises the cap).

**SavedVariables schema (`TimeFliesByDB`):**
- `dbVersion` — schema version; `tfb.db:Migrate()` applies the `migrations` table entry per version step.
- `data[charKey].expansions[expansionLevel].{createdAt, lastUpdate}` — playtime in seconds at the time of each `/played` request. Time played *in* an expansion is `lastUpdate - createdAt`.
- `data[charKey].lastCelebratedDay` — how many full played days the birthday jingle has already fired for. `nil` means "not primed yet" and must never be defaulted to `0`: that distinction is what stops an existing character celebrating every day it already played.
- Settings live as flat top-level keys (`positionPreset`, `barHeight`, `paragonListGrowDirection`, …). There is no defaults table: each `tfb.db:GetX()` accessor inlines its own default for `nil`, so new settings need a Get/Set pair following that pattern rather than a schema change.

## Conventions

- Code comments in English only.
- Blizzard removes FrameXML globals between patches. Nil-guard any such API and fall back through alternatives — see `tfb.character:IsMaxLevel()` for the established pattern.
