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

function tfb.db:SetYOffset(offset)
  TimeFliesByDB["yOffset"] = offset
end

function tfb.db:GetYOffset()
  return TimeFliesByDB["yOffset"]
end
