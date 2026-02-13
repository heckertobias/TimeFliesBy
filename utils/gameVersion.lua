local _, tfb = ...

tfb.gameVersion = {}

local expansionGameVersionMap = {
  { version = "1.0.0",  name = "Classic" },
  { version = "2.0.1",  name = "The Burning Crusade" },
  { version = "3.0.2",  name = "Wrath of the Lich King" },
  { version = "4.0.3",  name = "Cataclysm" },
  { version = "5.0.4",  name = "Mists of Pandaria" },
  { version = "6.0.2",  name = "Warlords of Draenor" },
  { version = "7.0.3",  name = "Legion" },
  { version = "8.0.1",  name = "Battle for Azeroth" },
  { version = "9.0.1",  name = "Shadowlands" },
  { version = "10.0.2", name = "Dragonflight" },
  { version = "11.0.2", name = "The War Within" },
  { version = "12.0.2", name = "Midnight" }
}

local function parseGameVersion(versionString)
  local major, minor, patch = string.match(versionString, "^(%d+)%.(%d+)%.(%d+)")

  major = tonumber(major)
  minor = tonumber(minor)
  patch = tonumber(patch)

  return major, minor, patch
end

function tfb.gameVersion:GetCurrentGameVersionString()
  local versionString = GetBuildInfo()
  return versionString
end

function tfb.gameVersion:GetCurrentGameVersion()
  local versionString = tfb.gameVersion:GetCurrentGameVersionString()
  return parseGameVersion(versionString)
end

function tfb.gameVersion:VersionLowerEqualCurrent(versionString)
  local currMajor, currMinor, currPatch = tfb.gameVersion:GetCurrentGameVersion()
  local major, minor, patch = parseGameVersion(versionString)

  if major > currMajor then
    return false
  end

  if minor > currMinor then
    return false
  end

  if patch > currPatch then
    return false
  end
end

function tfb.gameVersion:GetExpansionNameByVersion(versionString)
  local major, minor, patch = parseGameVersion(versionString)

  for i = #expansionGameVersionMap, 1, -1 do
    local mapMajor, mapMinor, mapPatch = parseGameVersion(expansionGameVersionMap[i].version)

    if mapMajor < major or
        (mapMajor == major and mapMinor < minor) or
        (mapMajor == major and mapMinor == minor and mapPatch <= patch) then
      return expansionGameVersionMap[i].name
    end
  end

  return "Unknown"
end

function tfb.gameVersion:GetCurrentExpansionName()
  local versionString = tfb.gameVersion:GetCurrentGameVersionString()
  return tfb.gameVersion:GetExpansionNameByVersion(versionString)
end
