local _, tfb = ...

tfb.gameVersion = {}

-- Maps expansion level (from GetExpansionLevel API) to expansion name
local expansionLevelMap = {
  [0]  = "Classic",
  [1]  = "The Burning Crusade",
  [2]  = "Wrath of the Lich King",
  [3]  = "Cataclysm",
  [4]  = "Mists of Pandaria",
  [5]  = "Warlords of Draenor",
  [6]  = "Legion",
  [7]  = "Battle for Azeroth",
  [8]  = "Shadowlands",
  [9]  = "Dragonflight",
  [10] = "The War Within",
  [11] = "Midnight",
}

-- Legacy map: version strings to expansion info (used for migration of old data)
local expansionGameVersionMap = {
  { version = "1.0.0",  name = "Classic",                level = 0 },
  { version = "2.0.1",  name = "The Burning Crusade",    level = 1 },
  { version = "3.0.2",  name = "Wrath of the Lich King", level = 2 },
  { version = "4.0.3",  name = "Cataclysm",              level = 3 },
  { version = "5.0.4",  name = "Mists of Pandaria",      level = 4 },
  { version = "6.0.2",  name = "Warlords of Draenor",    level = 5 },
  { version = "7.0.3",  name = "Legion",                 level = 6 },
  { version = "8.0.1",  name = "Battle for Azeroth",     level = 7 },
  { version = "9.0.1",  name = "Shadowlands",            level = 8 },
  { version = "10.0.2", name = "Dragonflight",            level = 9 },
  { version = "11.0.2", name = "The War Within",          level = 10 },
  { version = "12.0.2", name = "Midnight",                level = 11 }
}

local function parseGameVersion(versionString)
  local major, minor, patch = string.match(versionString, "^(%d+)%.(%d+)%.(%d+)")

  major = tonumber(major)
  minor = tonumber(minor)
  patch = tonumber(patch)

  return major, minor, patch
end

function tfb.gameVersion:GetCurrentExpansionLevel()
  return GetExpansionLevel()
end

function tfb.gameVersion:GetExpansionNameByLevel(level)
  return expansionLevelMap[level] or "Unknown"
end

function tfb.gameVersion:GetCurrentExpansionName()
  return tfb.gameVersion:GetExpansionNameByLevel(GetExpansionLevel())
end

-- Legacy: used for migration of old version-string-based DB entries
function tfb.gameVersion:GetExpansionNameByVersion(versionString)
  local major, minor, patch = parseGameVersion(versionString)

  for i = #expansionGameVersionMap, 1, -1 do
    local mapMajor, mapMinor, mapPatch = parseGameVersion(expansionGameVersionMap[i].version)

    if mapMajor < major or
        (mapMajor == major and mapMinor < minor) or
        (mapMajor == major and mapMinor == minor and mapPatch <= patch) then
      return expansionGameVersionMap[i].name, expansionGameVersionMap[i].level
    end
  end

  return "Unknown", nil
end

-- Legacy: used for migration of old version-string-based DB entries
function tfb.gameVersion:GetExpansionLevelByVersion(versionString)
  local _, level = tfb.gameVersion:GetExpansionNameByVersion(versionString)
  return level
end
