local _, tfb = ...

local initialTimeChecked = false
local WunderBar = tfb.WunderBar

local function updateXP()
  local xp = UnitXP("player")
  local max = UnitXPMax("player")
  local rested = GetXPExhaustion() or 0
  WunderBar:SetValues(max, xp, xp + rested)

  local perc = 0
  if max > 0 then
    perc = floor((xp / max) * 100)
  end
  if rested > 0 then
    local restedPerc = floor((rested / max) * 100)
    WunderBar:SetText(string.format("%d / %d (%d%%) +%d%%", xp, max, perc, restedPerc))
  else
    WunderBar:SetText(string.format("%d / %d (%d%%)", xp, max, perc))
  end
end

local function updateMaxLvlBar()
  local currentTime = tfb.db:GetCurrentPlayed(tfb.character:GetCharKey())
  WunderBar:SetValues(86400, currentTime % 86400)
  WunderBar:SetText(tfb.chat:FormatPlaytime(currentTime))
end

local function initWunderBar()
  if tfb.character:IsMaxLevel() then
    WunderBar:SetBar1Color(tfb.colors:GetClassColor(tfb.character:GetClassToken()))
    updateMaxLvlBar()
    C_Timer.NewTicker(5, updateMaxLvlBar)
  else
    WunderBar:SetBar1Color(tfb.colors:GetExpColor())
    WunderBar:SetBar2Color(tfb.colors:GetRestedExpColor())
    updateXP()

    tfb.events:Register("PLAYER_XP_UPDATE", "expUpdate", updateXP)
    tfb.events:Register("PLAYER_LEVEL_UP", "lvlUp", updateXP)
    tfb.events:Register("UPDATE_EXHAUSTION", "restedUpdate", updateXP)
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
  local totalTimePlayed = ...
  local versionString = tfb.gameVersion:GetCurrentGameVersionString()
  local charKey = tfb.character:GetCharKey()

  tfb.db:WriteTime(charKey, versionString, totalTimePlayed)
  C_Timer.After(0.1, function()
    addTimeMessage(charKey)
  end)

  initialTimeChecked = true
end
tfb.events:Register("TIME_PLAYED_MSG", "writeTime", writeTime)
