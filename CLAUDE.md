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

All modules share a single addon namespace table `tfb` (the second vararg from `local _, tfb = ...`). Each file declares its module on this table (e.g. `tfb.db = {}`, `tfb.WunderBar = {}`). Files are loaded in the order defined in the `.toc`; load order is load-bearing — `Settings.lua` must run before `BarContent.lua`, `ParagonList.lua` and `BirthdayJingle.lua`, because those register their panels as subcategories of `tfb.settingsCategory`. The bundled libraries in `libs/` (LibStub, CallbackHandler-1.0, LibDataBroker-1.1, LibDBIcon-1.0) load first; they are vendored copies, not `pkgmeta` externals, so the symlinked dev checkout works without a packaging step. `libs/` is in `Lua.workspace.ignoreDir`.

**Module overview:**
- `utils/events.lua` — `tfb.events`: Named event multiplexer wrapping WoW's frame event system. Use `tfb.events:Register(event, name, callback)` / `:Unregister(event, name)` instead of registering directly on frames. (`ParagonList.lua` registers on its own container frame instead; it owns that frame's lifecycle.)
- `utils/db.lua` — `tfb.db`: All reads/writes to `TimeFliesByDB` (the SavedVariables table). Contains DB migration logic. Current schema version: 2. Per-character data is keyed by `"Name-Realm"`.
- `utils/character.lua` — `tfb.character`: Player identity helpers (char key, class token, max level check).
- `utils/colors.lua` — `tfb.colors`: Class, XP/rested, faction, renown and friendship bar colors.
- `utils/gameVersion.lua` — `tfb.gameVersion`: Maps expansion levels (integers from `GetExpansionLevel()`) to names. Legacy version-string-based lookup exists only for DB migration.
- `utils/chat.lua` — `tfb.chat`: Chat output and playtime formatting.
- `utils/reputation.lua` — `tfb.reputation`: `GetReputationChange()` walks all factions and returns the one whose value or standing changed since the last call (renown / friendship / classic / paragon are normalized to `{name, standing, current, max, GetColor}`); the first call only primes the cache. `GetParagonRewards()` lists factions with an unclaimed paragon box. Journey tracks (`Delves: Season N`, `Preyhunter's Journey`) live in the Adventure Guide. They are major factions, but the reputation list omits them and `C_Reputation.GetFactionDataByID` returns `nil` for them, so they are collected by ID via `C_MajorFactions.ShouldDisplayMajorFactionAsJourney` (plus `C_DelvesUI.GetDelvesFactionForSeason` as a fallback) and read straight from `C_MajorFactions.GetMajorFactionData`. They are always cached but only reported when `trackJourneyProgress` is enabled (regular factions likewise with `trackReputation`) — skipping the cache update instead would swallow the first gain after the setting is turned on.
- `utils/skill.lua` — `tfb.skill`: Parses `CHAT_MSG_SKILL` for skill progress display. On Forever it reads the Vanilla skill window via `C_SkillInfo` (absent on retail): `maxRank` is the real cap, and `skillLineCategoryID == 6` (the "Weapon Skills" header, incl. Defense / Feral Combat) marks weapon skills, which are their own `weaponSkills` source. `GetSkillLineInfo(i)` only sees lines under expanded headers, so names are cached to `skillID` (primed by `tfb.skill:Init()`) and looked up via `GetSkillLineInfoByID` afterwards. Retail falls back to the `C_TradeSkillUI` path.
- `utils/housing.lua` — `tfb.housing`: Tracks housing XP (favor) changes.
- `utils/quest.lua` — `tfb.quest`: `GetQuestXP()` sums the reward XP of the quests in the log, split into ready to turn in and still in progress (tasks/bounties excluded). Drawn by `WunderBar:SetQuestValues()` as semi-transparent segments starting at the current XP, behind the rested segment (both start at the current XP, so they overlap instead of stacking; rested stays in front). `SetValues()` clears them, so every non-XP display drops them automatically. The quest text takes the second text line and pushes "Next Level in" to the third (`text3`, anchored one step beyond `text2`'s slot by `positionText3()`), keeping that slot even while empty.
- `utils/instance.lua` — `tfb.instance`: `IsInCompetitiveContent()` — true inside dungeons, raids, battlegrounds, arenas and delves/scenarios. Shared by the Paragon list and the birthday jingle.
- `utils/birthday.lua` — `tfb.birthday`: Fires a jingle each time the character's total played time crosses a 24 h multiple. Stays silent until the first `TIME_PLAYED_MSG` of the session, because until then the DB still holds the value written at the *previous* login and can be hours stale. Its `TIME_PLAYED_MSG` callback uses the event payload rather than the DB, since it runs before the one in `TimeFliesBy.lua` that persists it.
- `WunderBar.lua` — `tfb.WunderBar`: The status bar UI. Two overlapping StatusBar frames (`bar` + `bar2` for rested XP). Supports 4 position presets (Top, Bottom, Below Chat, Free). Free position is draggable and persisted. `HideBlizzStatusBar()` hides *and* unregisters events on `MainStatusTrackingBarContainer`, so it is one-way until `/reload`.
- `Settings.lua` — Blizzard AddOn Settings panel (`/tfb`), a hand-built canvas layout. Registers `tfb.settingsCategory`. Reads/writes via `tfb.db` and calls `tfb.WunderBar:Reposition()` on change.
- `BarContent.lua` — Canvas settings subcategory "Bar Content": which progress sources may take over the bar (reputation, professions, weapon skills on Forever, housing, journey), the display duration at max level, and whether/how long gains also replace the XP bar while leveling. Each source can override both durations separately (`progressDuration_<source>` / `levelingProgressDuration_<source>`, `nil` = mode default). The page sits in a scroll frame because the per-source sliders make it taller than the settings canvas.
- `MinimapIcon.lua` — `tfb.MinimapIcon`: LibDBIcon launcher (left click opens `/tfb`, tooltip shows playtime). Registered on `PLAYER_LOGIN` because LibDBIcon keeps a reference to `TimeFliesByDB.minimapIcon`, which only exists once SavedVariables are loaded. Toggled from the main settings panel.
- `BirthdayJingle.lua` — Canvas settings subcategory for the birthday jingle (enable, sound channel, play-in-competitive, test button). Must load after `Settings.lua`.
- `ParagonList.lua` — `tfb.ParagonList`: Standalone draggable list of factions with a pending paragon reward, plus its own canvas settings subcategory. Refreshed on `UPDATE_FACTION`, `PLAYER_ENTERING_WORLD`, and at init. Auto-hides when empty, disabled, or (optionally) inside instanced competitive content.
- `TimeFliesBy.lua` — Entry point. Orchestrates bar mode (XP vs. playtime vs. reputation/skill/housing). On `PLAYER_LOGIN`, runs DB migration, then waits 3 s before calling `RequestTimePlayed()` (giving other addons a chance to trigger it first, avoiding duplicate `/played` chat spam) and initializing the bar.

**Bar mode logic (TimeFliesBy.lua):**
- `barMode` is `"playtime"` or `"xp"`. Progress gains (reputation/journey, skill, housing; events registered once as `"progressGain"` for both modes) temporarily replace either bar until `progressVisibleUntil` (a `GetTime()` deadline). Every source is polled on its event even when its toggle is off, so caches stay primed.
- At max level → playtime bar (class color, 24 h cycle), driven by a 5 s ticker that no-ops outside playtime mode or while progress is visible. Duration: the source's `progressDuration_<source>` override, else `progressDuration`.
- While leveling → XP bar (with rested XP as bar2) plus a "Next Level in" estimate from a rolling 15-minute XP-rate window that survives level-ups. Progress gains replace it only if `showProgressWhileLeveling` is on, for `levelingProgressDuration_<source>`, else `levelingProgressDuration`; a `C_Timer.After` restores the XP bar, and `updateXP` keeps recording XP but skips drawing meanwhile.
- If `useBlizzardExpBar` is set → skip the custom XP bar entirely; use the max-level playtime bar regardless of level.
- `UPDATE_EXPANSION_LEVEL` re-evaluates the mode (e.g. dropping out of max level when a new expansion raises the cap).

**SavedVariables schema (`TimeFliesByDB`):**
- `dbVersion` — schema version; `tfb.db:Migrate()` applies the `migrations` table entry per version step.
- `data[charKey].expansions[expansionLevel].{createdAt, lastUpdate}` — playtime in seconds at the time of each `/played` request. Time played *in* an expansion is `lastUpdate - createdAt`.
- `data[charKey].lastCelebratedDay` — how many full played days the birthday jingle has already fired for. `nil` means "not primed yet" and must never be defaulted to `0`: that distinction is what stops an existing character celebrating every day it already played.
- Settings live as flat top-level keys (`positionPreset`, `barHeight`, `paragonListGrowDirection`, …). The one exception is `minimapIcon`, a subtable owned by LibDBIcon. There is no defaults table: each `tfb.db:GetX()` accessor inlines its own default for `nil`, so new settings need a Get/Set pair following that pattern rather than a schema change.

## Game versions

The AddOn runs on retail and on **World of Warcraft: Forever**. Forever is the *retail* client (all 269 `C_*` namespaces, Edit Mode, the modern Settings API) running Vanilla content, but it reports a Vanilla-era interface number — client 1.60.1 is interface `16001`, while retail is 100000+. `## Interface` therefore lists both (`16001, 120100`), Forever first. It has its own project ID, `WOW_PROJECT_ID == 18` (not `WOW_PROJECT_MAINLINE`), which is what separates it from the Classic clients in the same low interface range.

Consequences for the code:
- The usual "am I on modern WoW" test `select(4, GetBuildInfo()) >= 100000` is **false** on Forever. `tfb.gameVersion:IsForever()` is the check — interface number below 100000 *and* project ID 18.
- Retail-only *APIs* all exist on Forever; they just never return data. So renown, journey tracks, paragon and housing are gated by feature (`tfb.gameVersion:HasModernFactionSystems()`, `:HasHousing()`), not nil-guarded. Those gates also keep the Housing and Journey checkboxes out of `BarContent.lua` and make `ParagonList.lua` bail out before it builds any frame or settings subcategory.
- Registering an event the client does not know **throws**. `tfb.events:Register()` wraps `RegisterEvent` in `pcall` and drops the callback when it fails, so a retail-only event costs nothing on Forever.
- Forever has no expansions, so playtime is bucketed per content patch: `tfb.gameVersion:GetCurrentExpansionLevel()` returns the interface number with the build digits cut off (`16001 -> 16000`) instead of an expansion level. That key can never collide with the expansion levels 0-11, and `GetExpansionNameByLevel()` renders it as `Forever Patch 1.60`. SavedVariables are per client anyway, so the two never share a DB.

## Conventions

- Code comments in English only.
- Blizzard removes FrameXML globals between patches. Nil-guard any such API and fall back through alternatives — see `tfb.character:IsMaxLevel()` for the established pattern.
