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

-- World of Warcraft: Forever runs the retail API (the full set of C_* namespaces)
-- on Vanilla content, but reports a Vanilla-era interface number: client 1.60.1
-- -> 16001, while retail sits at 100000+. It also has its own project ID (18),
-- which tells it apart from the Classic clients that share the low interface
-- range.
local FOREVER_MAX_INTERFACE = 100000
local FOREVER_PROJECT_ID = 18

-- Forever has no expansions, so playtime is bucketed per content patch instead.
-- The bucket key is the interface number with the build digits cut off
-- (16001 -> 16000), which keeps 1.60.0 and 1.60.1 in the same bucket and can
-- never collide with the expansion levels 0-11 used on retail.
local PATCH_KEY_MIN = 10000

local foreverChecked = false
local isForever = false
local foreverPatchKey

local function detectForever()
  if foreverChecked then
    return
  end
  foreverChecked = true

  local _, _, _, interfaceVersion = GetBuildInfo()
  if not interfaceVersion or interfaceVersion >= FOREVER_MAX_INTERFACE then
    return
  end

  -- Nil-guarded: the project constant is absent on some clients, and an
  -- interface number below the retail range already implies Forever there.
  if WOW_PROJECT_ID and WOW_PROJECT_ID ~= FOREVER_PROJECT_ID then
    return
  end

  isForever = true
  foreverPatchKey = math.floor(interfaceVersion / 100) * 100
end

function tfb.gameVersion:IsForever()
  detectForever()
  return isForever
end

-- Renown, Journey tracks and Paragon reputations are Legion/Dragonflight+
-- systems. Their APIs exist on Forever (it is the retail client) but never
-- return data, so the features are gated instead of nil-guarded.
function tfb.gameVersion:HasModernFactionSystems()
  return not tfb.gameVersion:IsForever()
end

-- Weapon skills (and Defense) were removed from retail in Cataclysm; Forever
-- brings them back.
function tfb.gameVersion:HasWeaponSkills()
  return tfb.gameVersion:IsForever()
end

function tfb.gameVersion:HasHousing()
  return not tfb.gameVersion:IsForever()
end

-- Returns the expansion level on retail, or the patch bucket key on Forever.
function tfb.gameVersion:GetCurrentExpansionLevel()
  if tfb.gameVersion:IsForever() then
    return foreverPatchKey
  end

  return GetExpansionLevel()
end

function tfb.gameVersion:GetExpansionNameByLevel(level)
  if level and level >= PATCH_KEY_MIN then
    return string.format("Forever Patch %d.%d", math.floor(level / 10000), math.floor(level / 100) % 100)
  end

  return expansionLevelMap[level] or "Unknown"
end

function tfb.gameVersion:GetCurrentExpansionName()
  return tfb.gameVersion:GetExpansionNameByLevel(tfb.gameVersion:GetCurrentExpansionLevel())
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
