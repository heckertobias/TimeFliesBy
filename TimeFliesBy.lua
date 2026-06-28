local _, tfb = ...

local initialTimeChecked = false
local WunderBar = tfb.WunderBar

local specialBarVisibleTime = 60

local alternativeWatch = 0
local function updateMaxLvlBar(event, ...)
  if event == "UPDATE_FACTION" then
    local faction = tfb.reputation:GetReputationChange()
    if faction ~= nil then
      WunderBar:SetBar1Color(faction.GetColor())
      if faction.max and faction.max > 0 then
        WunderBar:SetValues(faction.max, faction.current)
        local perc = floor((faction.current / faction.max) * 100)
        WunderBar:SetText(string.format("%s - %d / %d (%d%%)", faction.name, faction.current, faction.max, perc), faction.standing)
      else
        -- Max standing reached (e.g. Exalted): full bar, no raw 0/0 numbers
        WunderBar:SetValues(1, 1)
        WunderBar:SetText(string.format("%s - %s", faction.name, faction.standing))
      end
      alternativeWatch = time() + specialBarVisibleTime
    end
  end

  if event == "CHAT_MSG_SKILL" then
    local message = ...
    local skill = tfb.skill:ParseSkillMsg(message)
    if skill ~= nil then
      WunderBar:SetBar1Color(skill.GetColor())
      WunderBar:SetValues(skill.max, skill.current)
      local perc = floor((skill.current / skill.max) * 100)
      WunderBar:SetText(string.format("%s - %d / %d (%d%%)", skill.name, skill.current, skill.max, perc))
      alternativeWatch = time() + specialBarVisibleTime
    end
  end

  if event == "HOUSE_LEVEL_FAVOR_UPDATED" then
    local houseLevelFavor = ...
    local housing = tfb.housing:GetHousingChange(houseLevelFavor.houseLevel, houseLevelFavor.houseFavor, houseLevelFavor.houseGUID)
    if housing ~= nil then
      WunderBar:SetBar1Color(housing.GetColor())
      WunderBar:SetValues(housing.max, housing.current)
      local perc = floor((housing.current / housing.max) * 100)
      WunderBar:SetText(string.format("%s - %d / %d (%d%%)", housing.name, housing.current, housing.max, perc), "Level " .. housing.level)
      alternativeWatch = time() + specialBarVisibleTime
    end
  end

  if (alternativeWatch < time()) then
    local currentTime = tfb.db:GetCurrentPlayed(tfb.character:GetCharKey())
    WunderBar:SetBar1Color(tfb.colors:GetClassColor(tfb.character:GetClassToken()))
    WunderBar:SetValues(86400, currentTime % 86400)
    WunderBar:SetText(tfb.chat:FormatPlaytime(currentTime))
  end
end

local function initMaxLvlBar()
  updateMaxLvlBar()
  C_Timer.NewTicker(5, updateMaxLvlBar)
  tfb.reputation:GetReputationChange() -- init
  tfb.events:Register("UPDATE_FACTION", "maxLvlBar", updateMaxLvlBar)
  tfb.events:Register("CHAT_MSG_SKILL", "maxLvlBar", updateMaxLvlBar)
  tfb.events:Register("HOUSE_LEVEL_FAVOR_UPDATED", "maxLvlBar", updateMaxLvlBar)
end

-- Rolling-window XP rate tracker.
-- Records recent XP gains as { t = timestamp, amount = gained } and returns the
-- average XP per second over the last XP_WINDOW seconds. Survives level-ups and
-- reflects the player's current pace rather than the whole-session average.
local XP_WINDOW = 900 -- 15 minutes
local xpSamples = {}
local lastXP, lastMax

local function recordXPAndGetRate(xp, max)
  local now = time()

  -- Record XP gained since the last update, accounting for level-ups.
  if lastXP ~= nil then
    local gained
    if xp >= lastXP then
      gained = xp - lastXP
    else
      -- Leveled up: finished the remainder of the previous level + new progress.
      gained = (lastMax - lastXP) + xp
    end
    if gained > 0 then
      table.insert(xpSamples, { t = now, amount = gained })
    end
  end
  lastXP = xp
  lastMax = max

  -- Drop samples that have aged out of the window.
  local cutoff = now - XP_WINDOW
  while xpSamples[1] and xpSamples[1].t < cutoff do
    table.remove(xpSamples, 1)
  end

  -- Need at least two samples; exclude the oldest amount so the numerator and
  -- denominator cover the same interval (now - oldest.t).
  if #xpSamples < 2 then
    return nil
  end
  local span = now - xpSamples[1].t
  if span <= 0 then
    return nil
  end

  local total = 0
  for i = 2, #xpSamples do
    total = total + xpSamples[i].amount
  end
  if total <= 0 then
    return nil
  end

  return total / span -- XP per second
end

local function checkPlayerReachedMaxLvl()
  if tfb.character:IsMaxLevel() then
    tfb.events:Unregister("PLAYER_XP_UPDATE", "updateXP")
    tfb.events:Unregister("PLAYER_LEVEL_UP", "updateXP")
    tfb.events:Unregister("UPDATE_EXHAUSTION", "updateXP")

    WunderBar:HideBlizzStatusBar()
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

  local xpPerSec = recordXPAndGetRate(xp, max)
  local timeTilNextLvlStr
  if xpPerSec and xpPerSec > 0 then
    local remaining = max - xp
    if remaining > 0 then
      local secTilNextLvl = ceil(remaining / xpPerSec)
      timeTilNextLvlStr = "Next Level in: " .. tfb.chat:FormatPlaytime(secTilNextLvl)
    end
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
  if tfb.db:GetUseBlizzardExpBar() then
    -- Blizzard handles XP, WunderBar shows playtime
    initMaxLvlBar()
  else
    WunderBar:HideBlizzStatusBar()
    if tfb.character:IsMaxLevel() then
      initMaxLvlBar()
    else
      initExpBar()
    end
  end
end

local function init()
  tfb.db:Migrate()

  tfb.events:Register("UPDATE_FACTION", "paragonList", function()
    tfb.ParagonList:Refresh()
  end)

  -- we wait 3 seconds to check the played time
  -- this gives other addons time to do this for us
  -- and pevents spamming the chatframe with /played
  C_Timer.After(3.0, function()
    if not initialTimeChecked then
      RequestTimePlayed()
    end
    initWunderBar()
    tfb.ParagonList:Refresh()
  end)
end
tfb.events:Register("PLAYER_LOGIN", "init", init)

local function addTimeMessage(charKey)
  local expansionTime = tfb.db:GetCharPlaytimeCurrentExpansion(charKey)
  local totalTime = tfb.db:GetTotalPlaytime()
  local currentExpansion = tfb.gameVersion:GetCurrentExpansionName()

  local expansionLevel = tfb.gameVersion:GetCurrentExpansionLevel()
  local allCharsExpansionTime = tfb.db:GetAllCharsPlaytimeCurrentExpansion(expansionLevel)

  tfb.chat:AddMessage("Time played in " .. currentExpansion .. ": " .. tfb.chat:FormatPlaytime(expansionTime))
  tfb.chat:AddMessage("Time played in " .. currentExpansion .. " on all characters: " .. tfb.chat:FormatPlaytime(allCharsExpansionTime))
  tfb.chat:AddMessage("Time played on all characters: " .. tfb.chat:FormatPlaytime(totalTime))
end

local function writeTime(_, ...)
  local totalTimePlayed, timePlayedAtLevel = ...
  local expansionLevel = tfb.gameVersion:GetCurrentExpansionLevel()
  local charKey = tfb.character:GetCharKey()

  tfb.db:WriteTime(charKey, expansionLevel, totalTimePlayed, timePlayedAtLevel)
  C_Timer.After(0.1, function()
    addTimeMessage(charKey)
  end)

  initialTimeChecked = true
end
tfb.events:Register("TIME_PLAYED_MSG", "writeTime", writeTime)

local function onExpansionLevelChanged()
  local expansionName = tfb.gameVersion:GetCurrentExpansionName()
  RaidNotice_AddMessage(RaidWarningFrame, "Time Flies By: Welcome to " .. expansionName .. "!", ChatTypeInfo["RAID_WARNING"])

  -- Switch back to exp bar if player is no longer max level
  if not tfb.character:IsMaxLevel() then
    tfb.events:Unregister("UPDATE_FACTION", "maxLvlBar")
    tfb.events:Unregister("CHAT_MSG_SKILL", "maxLvlBar")
    tfb.events:Unregister("HOUSE_LEVEL_FAVOR_UPDATED", "maxLvlBar")
    initExpBar()
  end

  C_Timer.After(5, RequestTimePlayed)
end
tfb.events:Register("UPDATE_EXPANSION_LEVEL", "expansionChange", onExpansionLevelChanged)

SLASH_TFB1 = "/tfb"
SlashCmdList["TFB"] = function()
  Settings.OpenToCategory(tfb.settingsCategory:GetID())
end
