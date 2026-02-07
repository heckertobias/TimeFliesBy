local _, tfb = ...

tfb.db = {}

TimeFliesByDB = TimeFliesByDB or {}

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
end
