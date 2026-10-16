local _, tfb = ...

tfb.db = {}

TimeFliesByDB = TimeFliesByDB or {}

local DB_VERSION = 2
local lastDbWrite

-- Migration v1 -> v2: version-string-based keys to expansion-level-based keys
local function migrateV1ToV2()
  if not TimeFliesByDB["data"] then return end

  for _, charData in pairs(TimeFliesByDB["data"]) do
    if not charData.currentVersionString then break end

    local newExpansions = {}
    for versionString, data in pairs(charData.expansions) do
      local level = tfb.gameVersion:GetExpansionLevelByVersion(versionString)
      if level then
        if newExpansions[level] then
          newExpansions[level].createdAt = math.min(newExpansions[level].createdAt, data.createdAt)
          newExpansions[level].lastUpdate = math.max(newExpansions[level].lastUpdate, data.lastUpdate)
        else
          newExpansions[level] = {
            createdAt = data.createdAt,
            lastUpdate = data.lastUpdate,
          }
        end
      end
    end

    charData.expansions = newExpansions
    charData.currentExpansionLevel = tfb.gameVersion:GetExpansionLevelByVersion(charData.currentVersionString)
    charData.currentVersionString = nil
  end
end

local migrations = {
  [2] = migrateV1ToV2,
}

local function runMigrations()
  local currentVersion = TimeFliesByDB["dbVersion"] or 1

  for version = currentVersion + 1, DB_VERSION do
    if migrations[version] then
      migrations[version]()
    end
  end

  TimeFliesByDB["dbVersion"] = DB_VERSION
end

local function initNewExpansion(charKey, expansionLevel, playedTime)
  TimeFliesByDB["data"][charKey].currentExpansionLevel = expansionLevel
  TimeFliesByDB["data"][charKey].expansions[expansionLevel] = {
    createdAt = playedTime,
    lastUpdate = playedTime
  }
end

local function initCharKey(charKey, expansionLevel, playedTime, timePlayedAtLevel)
  if not TimeFliesByDB["data"] then
    TimeFliesByDB["data"] = {}
  end

  TimeFliesByDB["data"][charKey] = {
    initialPlayedTime = playedTime - timePlayedAtLevel,
    currentExpansionLevel = expansionLevel,
    expansions = {
      [expansionLevel] = {
        createdAt = playedTime - timePlayedAtLevel,
        lastUpdate = playedTime
      }
    }
  }
end

function tfb.db:Migrate()
  runMigrations()
end

function tfb.db:WriteTime(charKey, expansionLevel, playedTime, timePlayedAtLevel)
  -- Set before the initCharKey branch: GetCurrentPlayed extrapolates from this
  -- timestamp, so leaving it unset on a brand new character freezes the reported
  -- playtime for the rest of the session.
  lastDbWrite = time()

  if not TimeFliesByDB["data"] or not TimeFliesByDB["data"][charKey] then
    initCharKey(charKey, expansionLevel, playedTime, timePlayedAtLevel)
    return
  end

  local lastExpansion = TimeFliesByDB["data"][charKey].currentExpansionLevel
  TimeFliesByDB["data"][charKey].expansions[lastExpansion].lastUpdate = playedTime

  -- new expansion detected
  if expansionLevel ~= lastExpansion then
    initNewExpansion(charKey, expansionLevel, playedTime)
  end
end

function tfb.db:GetCurrentPlayed(charKey)
  if not TimeFliesByDB["data"][charKey] then
    return 0
  end

  local timeSinceWrite
  if not lastDbWrite then
    timeSinceWrite = 0
  else
    timeSinceWrite = time() - lastDbWrite
  end
  local currentLevel = TimeFliesByDB["data"][charKey].currentExpansionLevel
  local expansionData = TimeFliesByDB["data"][charKey].expansions[currentLevel]

  return expansionData.lastUpdate + timeSinceWrite
end

function tfb.db:GetTotalPlaytime()
  local total = 0

  for _, charData in pairs(TimeFliesByDB["data"]) do
    local currentLevel = charData.currentExpansionLevel
    local expansionData = charData.expansions[currentLevel]
    if expansionData then
      total = total + expansionData.lastUpdate
    end
  end

  return total
end

function tfb.db:GetCharPlaytimeCurrentExpansion(charKey)
  if not TimeFliesByDB["data"][charKey] then
    return 0
  end

  local charData = TimeFliesByDB["data"][charKey]
  local currentLevel = charData.currentExpansionLevel
  local expansionData = charData.expansions[currentLevel]

  if expansionData then
    return expansionData.lastUpdate - expansionData.createdAt
  end

  return 0
end

function tfb.db:GetAllCharsPlaytimeCurrentExpansion(expansionLevel)
  local total = 0

  for _, charData in pairs(TimeFliesByDB["data"]) do
    local expansionData = charData.expansions[expansionLevel]
    if expansionData then
      total = total + expansionData.lastUpdate - expansionData.createdAt
    end
  end

  return total
end

function tfb.db:SetYOffset(offset)
  TimeFliesByDB["yOffset"] = offset
end

function tfb.db:GetYOffset()
  return TimeFliesByDB["yOffset"]
end

function tfb.db:GetPositionPreset()
  return TimeFliesByDB["positionPreset"] or 1
end

function tfb.db:SetPositionPreset(preset)
  TimeFliesByDB["positionPreset"] = preset
end

function tfb.db:GetTextFollowsOffset()
  if TimeFliesByDB["textFollowsOffset"] == nil then
    return false
  end
  return TimeFliesByDB["textFollowsOffset"]
end

function tfb.db:SetTextFollowsOffset(value)
  TimeFliesByDB["textFollowsOffset"] = value
end

function tfb.db:GetUseBlizzardExpBar()
  if TimeFliesByDB["useBlizzardExpBar"] == nil then
    return false
  end
  return TimeFliesByDB["useBlizzardExpBar"]
end

function tfb.db:SetUseBlizzardExpBar(value)
  TimeFliesByDB["useBlizzardExpBar"] = value
end

function tfb.db:GetTrackJourneyProgress()
  if TimeFliesByDB["trackJourneyProgress"] == nil then
    return true
  end
  return TimeFliesByDB["trackJourneyProgress"]
end

function tfb.db:SetTrackJourneyProgress(value)
  TimeFliesByDB["trackJourneyProgress"] = value
end

function tfb.db:GetTrackReputation()
  if TimeFliesByDB["trackReputation"] == nil then
    return true
  end
  return TimeFliesByDB["trackReputation"]
end

function tfb.db:SetTrackReputation(value)
  TimeFliesByDB["trackReputation"] = value
end

function tfb.db:GetTrackProfessions()
  if TimeFliesByDB["trackProfessions"] == nil then
    return true
  end
  return TimeFliesByDB["trackProfessions"]
end

function tfb.db:SetTrackProfessions(value)
  TimeFliesByDB["trackProfessions"] = value
end

function tfb.db:GetTrackWeaponSkills()
  if TimeFliesByDB["trackWeaponSkills"] == nil then
    return true
  end
  return TimeFliesByDB["trackWeaponSkills"]
end

function tfb.db:SetTrackWeaponSkills(value)
  TimeFliesByDB["trackWeaponSkills"] = value
end

function tfb.db:GetTrackHousing()
  if TimeFliesByDB["trackHousing"] == nil then
    return true
  end
  return TimeFliesByDB["trackHousing"]
end

function tfb.db:SetTrackHousing(value)
  TimeFliesByDB["trackHousing"] = value
end

-- Seconds a progress gain stays on the bar before the playtime bar returns.
function tfb.db:GetProgressDuration()
  return TimeFliesByDB["progressDuration"] or 60
end

function tfb.db:SetProgressDuration(seconds)
  TimeFliesByDB["progressDuration"] = seconds
end

function tfb.db:GetShowProgressWhileLeveling()
  if TimeFliesByDB["showProgressWhileLeveling"] == nil then
    return true
  end
  return TimeFliesByDB["showProgressWhileLeveling"]
end

function tfb.db:SetShowProgressWhileLeveling(value)
  TimeFliesByDB["showProgressWhileLeveling"] = value
end

-- Seconds a progress gain stays on the bar before the XP bar returns.
function tfb.db:GetLevelingProgressDuration()
  return TimeFliesByDB["levelingProgressDuration"] or 60
end

function tfb.db:SetLevelingProgressDuration(seconds)
  TimeFliesByDB["levelingProgressDuration"] = seconds
end

-- Optional per-source override of the display duration, separately for max
-- level (playtime bar) and leveling (XP bar). nil means the source follows the
-- duration of the mode.
-- source: "reputation", "professions", "weaponSkills", "housing", "journey"
local function sourceDurationKey(source, leveling)
  return (leveling and "levelingProgressDuration_" or "progressDuration_") .. source
end

function tfb.db:GetSourceDuration(source, leveling)
  return TimeFliesByDB[sourceDurationKey(source, leveling)]
end

function tfb.db:SetSourceDuration(source, leveling, seconds)
  TimeFliesByDB[sourceDurationKey(source, leveling)] = seconds
end

function tfb.db:GetShowQuestXP()
  return TimeFliesByDB["showQuestXP"] == true
end

function tfb.db:SetShowQuestXP(value)
  TimeFliesByDB["showQuestXP"] = value
end

-- Which quest groups the quest XP display includes.
function tfb.db:GetShowQuestXPReady()
  if TimeFliesByDB["showQuestXPReady"] == nil then
    return true
  end
  return TimeFliesByDB["showQuestXPReady"]
end

function tfb.db:SetShowQuestXPReady(value)
  TimeFliesByDB["showQuestXPReady"] = value
end

function tfb.db:GetShowQuestXPOpen()
  if TimeFliesByDB["showQuestXPOpen"] == nil then
    return true
  end
  return TimeFliesByDB["showQuestXPOpen"]
end

function tfb.db:SetShowQuestXPOpen(value)
  TimeFliesByDB["showQuestXPOpen"] = value
end

-- "both", "bar" or "text"
function tfb.db:GetQuestXPDisplay()
  return TimeFliesByDB["questXPDisplay"] or "both"
end

function tfb.db:SetQuestXPDisplay(value)
  TimeFliesByDB["questXPDisplay"] = value
end

-- LibDBIcon keeps its own state (hide flag, minimap angle) in the table it is
-- handed, so this one setting is a subtable rather than a flat key.
function tfb.db:GetMinimapIconDB()
  if not TimeFliesByDB["minimapIcon"] then
    TimeFliesByDB["minimapIcon"] = {}
  end
  return TimeFliesByDB["minimapIcon"]
end

function tfb.db:GetBarHeight()
  return TimeFliesByDB["barHeight"] or 5
end

function tfb.db:SetBarHeight(height)
  TimeFliesByDB["barHeight"] = height
end

function tfb.db:GetFreePositionX()
  return TimeFliesByDB["freePositionX"]
end

function tfb.db:GetFreePositionY()
  return TimeFliesByDB["freePositionY"]
end

function tfb.db:SetFreePosition(x, y)
  TimeFliesByDB["freePositionX"] = x
  TimeFliesByDB["freePositionY"] = y
end

function tfb.db:GetFreePositionLocked()
  if TimeFliesByDB["freePositionLocked"] == nil then
    return false
  end
  return TimeFliesByDB["freePositionLocked"]
end

function tfb.db:SetFreePositionLocked(value)
  TimeFliesByDB["freePositionLocked"] = value
end

function tfb.db:GetBarWidth()
  return TimeFliesByDB["barWidth"] or 400
end

function tfb.db:SetBarWidth(width)
  TimeFliesByDB["barWidth"] = width
end

function tfb.db:GetTextPosition()
  return TimeFliesByDB["textPosition"] or "bottom"
end

function tfb.db:SetTextPosition(value)
  TimeFliesByDB["textPosition"] = value
end

function tfb.db:GetTextAlignment()
  return TimeFliesByDB["textAlignment"] or "CENTER"
end

function tfb.db:SetTextAlignment(value)
  TimeFliesByDB["textAlignment"] = value
end

function tfb.db:GetParagonListX()
  return TimeFliesByDB["paragonListX"]
end

function tfb.db:GetParagonListY()
  return TimeFliesByDB["paragonListY"]
end

function tfb.db:SetParagonListPosition(x, y)
  TimeFliesByDB["paragonListX"] = x
  TimeFliesByDB["paragonListY"] = y
end

function tfb.db:GetParagonListLocked()
  if TimeFliesByDB["paragonListLocked"] == nil then
    return false
  end
  return TimeFliesByDB["paragonListLocked"]
end

function tfb.db:SetParagonListLocked(value)
  TimeFliesByDB["paragonListLocked"] = value
end

function tfb.db:GetParagonListGrowDirection()
  return TimeFliesByDB["paragonListGrowDirection"] or "down"
end

function tfb.db:SetParagonListGrowDirection(value)
  TimeFliesByDB["paragonListGrowDirection"] = value
end

function tfb.db:GetParagonListUseFactionColor()
  if TimeFliesByDB["paragonListUseFactionColor"] == nil then
    return true
  end
  return TimeFliesByDB["paragonListUseFactionColor"]
end

function tfb.db:SetParagonListUseFactionColor(value)
  TimeFliesByDB["paragonListUseFactionColor"] = value
end

function tfb.db:GetParagonListShowBackground()
  if TimeFliesByDB["paragonListShowBackground"] == nil then
    return true
  end
  return TimeFliesByDB["paragonListShowBackground"]
end

function tfb.db:SetParagonListShowBackground(value)
  TimeFliesByDB["paragonListShowBackground"] = value
end

function tfb.db:GetParagonListEnabled()
  if TimeFliesByDB["paragonListEnabled"] == nil then
    return true
  end
  return TimeFliesByDB["paragonListEnabled"]
end

function tfb.db:SetParagonListEnabled(value)
  TimeFliesByDB["paragonListEnabled"] = value
end

function tfb.db:GetParagonListHideInCompetitive()
  if TimeFliesByDB["paragonListHideInCompetitive"] == nil then
    return false
  end
  return TimeFliesByDB["paragonListHideInCompetitive"]
end

function tfb.db:SetParagonListHideInCompetitive(value)
  TimeFliesByDB["paragonListHideInCompetitive"] = value
end

function tfb.db:GetParagonListTextAlign()
  return TimeFliesByDB["paragonListTextAlign"] or "LEFT"
end

function tfb.db:SetParagonListTextAlign(value)
  TimeFliesByDB["paragonListTextAlign"] = value
end

function tfb.db:GetBirthdayJingleEnabled()
  if TimeFliesByDB["birthdayJingleEnabled"] == nil then
    return false
  end
  return TimeFliesByDB["birthdayJingleEnabled"]
end

function tfb.db:SetBirthdayJingleEnabled(value)
  TimeFliesByDB["birthdayJingleEnabled"] = value
end

function tfb.db:GetBirthdayJingleChannel()
  return TimeFliesByDB["birthdayJingleChannel"] or "Master"
end

function tfb.db:SetBirthdayJingleChannel(value)
  TimeFliesByDB["birthdayJingleChannel"] = value
end

function tfb.db:GetBirthdayJinglePlayInCompetitive()
  if TimeFliesByDB["birthdayJinglePlayInCompetitive"] == nil then
    return false
  end
  return TimeFliesByDB["birthdayJinglePlayInCompetitive"]
end

function tfb.db:SetBirthdayJinglePlayInCompetitive(value)
  TimeFliesByDB["birthdayJinglePlayInCompetitive"] = value
end

-- Per-character counter of how many full played days have already been celebrated.
-- nil means "not primed yet" and must not trigger a celebration.
function tfb.db:GetLastCelebratedDay(charKey)
  local charData = TimeFliesByDB["data"] and TimeFliesByDB["data"][charKey]
  if not charData then
    return nil
  end
  return charData.lastCelebratedDay
end

function tfb.db:SetLastCelebratedDay(charKey, days)
  local charData = TimeFliesByDB["data"] and TimeFliesByDB["data"][charKey]
  if not charData then
    return
  end
  charData.lastCelebratedDay = days
end

-- True once WriteTime has stored playtime for this character.
function tfb.db:HasCharData(charKey)
  return TimeFliesByDB["data"] ~= nil and TimeFliesByDB["data"][charKey] ~= nil
end
