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
  lastDbWrite = time()
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
