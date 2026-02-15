local _, tfb = ...

local initialTimeChecked = false
local WunderBar = tfb.WunderBar

local function updateMaxLvlBar()
  local currentTime = tfb.db:GetCurrentPlayed(tfb.character:GetCharKey())
  WunderBar:SetValues(86400, currentTime % 86400)
  WunderBar:SetText(tfb.chat:FormatPlaytime(currentTime))
end

local function initMaxLvlBar()
  WunderBar:SetBar1Color(tfb.colors:GetClassColor(tfb.character:GetClassToken()))
  updateMaxLvlBar()
  C_Timer.NewTicker(5, updateMaxLvlBar)
end

local sessionStart, sessionStartExp
local function getExpPerHour(exp)
  if not sessionStartExp or sessionStartExp > exp then
    sessionStart = time()
    sessionStartExp = exp
  end
  if sessionStart and sessionStart > 0 then
    local sessionTime = time() - sessionStart
    local coeff = sessionTime / 3600
    local sessionExp = exp - sessionStartExp
    if coeff > 0 and sessionExp > 0 then
      return ceil(sessionExp / coeff)
    end
  end
end

local function checkPlayerReachedMaxLvl()
  if tfb.character:IsMaxLevel() then
    tfb.events:Unregister("PLAYER_XP_UPDATE", "updateXP")
    tfb.events:Unregister("PLAYER_LEVEL_UP", "updateXP")
    tfb.events:Unregister("UPDATE_EXHAUSTION", "updateXP")

    initMaxLvlBar()
    return true
  end

  return false
end

local function updateXP()
  if checkPlayerReachedMaxLvl() then
    return
  end

  local xp = UnitXP("player")
  local max = UnitXPMax("player")
  local rested = GetXPExhaustion() or 0
  WunderBar:SetValues(max, xp, xp + rested)

  local expPerHour = getExpPerHour(xp)
  local timeTilNextLvlStr
  if expPerHour then
    local secTilNextLvl = ceil((max / expPerHour) * 3600)
    timeTilNextLvlStr = "Next Level in: " .. tfb.chat:FormatPlaytime(secTilNextLvl)
  end

  local perc = 0
  if max > 0 then
    perc = floor((xp / max) * 100)
  end
  local restedText = ""
  if rested > 0 then
    local restedPerc = floor((rested / max) * 100)
    if restedPerc > 0 then
      restedText = string.format(" +%d%%", restedPerc)
    end
  end
  WunderBar:SetText(string.format("%d / %d (%d%%)%s", xp, max, perc, restedText), timeTilNextLvlStr)
end

local function initExpBar()
  WunderBar:SetBar1Color(tfb.colors:GetExpColor())
  WunderBar:SetBar2Color(tfb.colors:GetRestedExpColor())
  updateXP()

  tfb.events:Register("PLAYER_XP_UPDATE", "updateXP", updateXP)
  tfb.events:Register("PLAYER_LEVEL_UP", "updateXP", updateXP)
  tfb.events:Register("UPDATE_EXHAUSTION", "updateXP", updateXP)
end

local function initWunderBar()
  if tfb.character:IsMaxLevel() then
    initMaxLvlBar()
  else
    initExpBar()
  end
end

local function init()
  -- we wait 3 seconds to check the played time
  -- this gives other addons time to do this for us
  -- and pevents spamming the chatframe with /played
  C_Timer.After(3.0, function()
    if not initialTimeChecked then
      RequestTimePlayed()
    end
    initWunderBar()
  end)
end
tfb.events:Register("PLAYER_LOGIN", "init", init)

local function addTimeMessage(charKey)
  local expansionTime = tfb.db:GetCharPlaytimeCurrentExpansion(charKey)
  local totalTime = tfb.db:GetTotalPlaytime()
  local currentExpansion = tfb.gameVersion:GetCurrentExpansionName()

  tfb.chat:AddMessage("Time played in " .. currentExpansion .. ": " .. tfb.chat:FormatPlaytime(expansionTime))
  tfb.chat:AddMessage("Time played on all charaters: " .. tfb.chat:FormatPlaytime(totalTime))
end

local function writeTime(...)
  local totalTimePlayed, timePlayedAtLevel = ...
  local versionString = tfb.gameVersion:GetCurrentGameVersionString()
  local charKey = tfb.character:GetCharKey()

  tfb.db:WriteTime(charKey, versionString, totalTimePlayed, timePlayedAtLevel)
  C_Timer.After(0.1, function()
    addTimeMessage(charKey)
  end)

  initialTimeChecked = true
end
tfb.events:Register("TIME_PLAYED_MSG", "writeTime", writeTime)
