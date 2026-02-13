local _, tfb = ...

tfb.db = {}

TimeFliesByDB = TimeFliesByDB or {}

local lastDbWrite

local function initNewVersion(charKey, versionString, playedTime)
  TimeFliesByDB["data"][charKey].currentVersionString = versionString
  TimeFliesByDB["data"][charKey].expansions[versionString] = {
    createdAt = playedTime,
    lastUpdate = playedTime
  }
end

local function initCharKey(charKey, versionString, playedTime)
  TimeFliesByDB["data"][charKey] = {
    initialPlayedTime = playedTime,
    currentVersionString = versionString,
    expansions = {}
  }
  initNewVersion(charKey, versionString, playedTime)
end

function tfb.db:WriteTime(charKey, versionString, playedTime)
  if not TimeFliesByDB["data"][charKey] then
    initCharKey(charKey, versionString, playedTime)
    return
  end

  -- update based on the last stored versionString
  -- since the version should only change when not logges in
  -- all previous time played was on the old version
  local lastVersion = TimeFliesByDB["data"][charKey].currentVersionString
  TimeFliesByDB["data"][charKey].expansions[lastVersion].lastUpdate = playedTime

  -- new version detected
  if versionString ~= lastVersion then
    initNewVersion(charKey, versionString, playedTime)
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
  local currentVersion = TimeFliesByDB["data"][charKey].currentVersionString
  local expansionData = TimeFliesByDB["data"][charKey].expansions[currentVersion]

  return expansionData.lastUpdate + timeSinceWrite
end

function tfb.db:GetTotalPlaytime()
  local total = 0

  for _, charData in pairs(TimeFliesByDB["data"]) do
    local currentVersion = charData.currentVersionString
    local expansionData = charData.expansions[currentVersion]
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
  local currentVersion = charData.currentVersionString
  local currentExpansion = tfb.gameVersion:GetExpansionNameByVersion(currentVersion)

  local total = 0

  -- Sum playtime for all versions that belong to the same expansion
  for versionString, expansionData in pairs(charData.expansions) do
    local expansion = tfb.gameVersion:GetExpansionNameByVersion(versionString)
    if expansion == currentExpansion then
      total = total + (expansionData.lastUpdate - expansionData.createdAt)
    end
  end

  return total
end
