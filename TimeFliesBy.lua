local _, tfb = ...

local initialTimeChecked = false
local WunderBar = tfb.WunderBar

-- Which bar is currently the base display: "xp" while leveling, "playtime" at
-- max level or when Blizzard's XP bar is used. Progress gains temporarily
-- replace either one.
local barMode
local maxLvlTicker

-- GetTime() until which a progress gain stays on the bar.
local progressVisibleUntil = 0

local function isProgressVisible()
  return progressVisibleUntil > GetTime()
end

-- Polls the source behind the event. Every source is polled even when it is not
-- going to be shown, so its cache stays current and the first gain after a
-- setting is turned on is not swallowed.
local function getProgressChange(event, ...)
  -- MAJOR_FACTION_RENOWN_LEVEL_CHANGED is a second trigger for journey tracks,
  -- which are not part of the reputation list. GetReputationChange() polls all
  -- sources anyway, so the event only decides when to look. The reputation and
  -- journey toggles are applied in there.
  if event == "UPDATE_FACTION" or event == "MAJOR_FACTION_RENOWN_LEVEL_CHANGED" then
    return tfb.reputation:GetReputationChange()
  end

  if event == "CHAT_MSG_SKILL" then
    local message = ...
    local skill = tfb.skill:ParseSkillMsg(message)
    if not skill then
      return nil
    end
    if skill.isWeaponSkill then
      skill.source = "weaponSkills"
      return tfb.db:GetTrackWeaponSkills() and skill or nil
    end
    skill.source = "professions"
    return tfb.db:GetTrackProfessions() and skill or nil
  end

  if event == "HOUSE_LEVEL_FAVOR_UPDATED" then
    local houseLevelFavor = ...
    local housing = tfb.housing:GetHousingChange(houseLevelFavor.houseLevel, houseLevelFavor.houseFavor, houseLevelFavor.houseGUID)
    if housing and tfb.db:GetTrackHousing() then
      housing.standing = "Level " .. housing.level
      housing.source = "housing"
      return housing
    end
    return nil
  end

  return nil
end

local function showPlaytime()
  local currentTime = tfb.db:GetCurrentPlayed(tfb.character:GetCharKey())
  WunderBar:SetBar1Color(tfb.colors:GetClassColor(tfb.character:GetClassToken()))
  WunderBar:SetValues(86400, currentTime % 86400)
  WunderBar:SetText(tfb.chat:FormatPlaytime(currentTime))
end

local function updatePlaytimeBar()
  if barMode ~= "playtime" or isProgressVisible() then
    return
  end
  showPlaytime()
end

-- Assigned once the XP bar functions below exist.
local updateXP

local function onProgressGain(event, ...)
  local progress = getProgressChange(event, ...)
  -- reputation.lua reports nothing for factions at max standing, so max is
  -- always > 0 here - the guard only keeps a bad API value off the bar.
  if not progress or not progress.max or progress.max <= 0 then
    return
  end

  local duration
  if barMode == "xp" then
    if not tfb.db:GetShowProgressWhileLeveling() then
      return
    end
    duration = tfb.db:GetSourceDuration(progress.source, true) or tfb.db:GetLevelingProgressDuration()
  elseif barMode == "playtime" then
    duration = tfb.db:GetSourceDuration(progress.source, false) or tfb.db:GetProgressDuration()
  else
    return
  end

  WunderBar:SetBar1Color(progress.GetColor())
  -- No third value: this hides the rested XP overlay while progress is shown.
  WunderBar:SetValues(progress.max, progress.current)
  local perc = floor((progress.current / progress.max) * 100)
  WunderBar:SetText(string.format("%s - %d / %d (%d%%)", progress.name, progress.current, progress.max, perc), progress.standing)

  progressVisibleUntil = GetTime() + duration

  -- The playtime bar comes back on its own ticker. The XP bar is only redrawn on
  -- XP events, so it needs a timer. Every gain starts its own timer; only the
  -- one that fires after the latest deadline finds the window expired.
  if barMode == "xp" then
    C_Timer.After(duration, function()
      if barMode == "xp" and not isProgressVisible() then
        updateXP()
      end
    end)
  end
end

local function initProgressTracking()
  tfb.reputation:GetReputationChange() -- init
  tfb.skill:Init()
  tfb.events:Register("UPDATE_FACTION", "progressGain", onProgressGain)
  tfb.events:Register("CHAT_MSG_SKILL", "progressGain", onProgressGain)
  if tfb.gameVersion:HasModernFactionSystems() then
    tfb.events:Register("MAJOR_FACTION_RENOWN_LEVEL_CHANGED", "progressGain", onProgressGain)
  end
  if tfb.gameVersion:HasHousing() then
    tfb.events:Register("HOUSE_LEVEL_FAVOR_UPDATED", "progressGain", onProgressGain)
  end
end

local function initMaxLvlBar()
  barMode = "playtime"
  progressVisibleUntil = 0
  showPlaytime()
  if not maxLvlTicker then
    maxLvlTicker = C_Timer.NewTicker(5, updatePlaytimeBar)
  end
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
    tfb.events:Unregister("QUEST_LOG_UPDATE", "updateXP")

    WunderBar:HideBlizzStatusBar()
    initMaxLvlBar()
    return true
  end

  return false
end

updateXP = function()
  if checkPlayerReachedMaxLvl() then
    return
  end

  local xp = UnitXP("player")
  local max = UnitXPMax("player")
  local rested = GetXPExhaustion() or 0

  -- Always record, so the rate stays accurate while a progress gain is shown.
  local xpPerSec = recordXPAndGetRate(xp, max)
  if isProgressVisible() then
    return
  end

  WunderBar:SetBar1Color(tfb.colors:GetExpColor())
  WunderBar:SetValues(max, xp, xp + rested)
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

  local mainText = string.format("%d / %d (%d%%)%s", xp, max, perc, restedText)

  -- The quest line takes the second line and pushes "Next Level in" to the
  -- third. It keeps that slot even while there is nothing to show, so the lines
  -- below do not jump around.
  if tfb.db:GetShowQuestXP() then
    local readyXP, openXP = tfb.quest:GetQuestXP()
    -- A group that is turned off is left out of both the bar and the text.
    local showReady, showOpen = tfb.db:GetShowQuestXPReady(), tfb.db:GetShowQuestXPOpen()
    if not showReady then readyXP = 0 end
    if not showOpen then openXP = 0 end
    local display = tfb.db:GetQuestXPDisplay()
    if display ~= "text" then
      WunderBar:SetQuestValues(max, xp, readyXP, openXP)
    end
    if display ~= "bar" then
      local questText
      if (readyXP > 0 or openXP > 0) and max > 0 then
        local parts = {}
        if showReady then
          table.insert(parts, string.format("+%d (%d%%)", readyXP, floor((readyXP / max) * 100)))
        end
        if showOpen then
          table.insert(parts, string.format("+%d (%d%%)", openXP, floor((openXP / max) * 100)))
        end
        -- "||" renders as a single "|"; a lone pipe starts an escape sequence.
        questText = "Quests: " .. table.concat(parts, " || ")
      end
      WunderBar:SetText(mainText, questText, timeTilNextLvlStr)
      return
    end
  end

  WunderBar:SetText(mainText, timeTilNextLvlStr)
end

-- Redraws the XP bar after a setting change; no-op outside the XP bar.
function tfb.RefreshXPBar()
  if barMode == "xp" and not isProgressVisible() then
    updateXP()
  end
end

local function initExpBar()
  barMode = "xp"
  progressVisibleUntil = 0
  WunderBar:SetBar2Color(tfb.colors:GetRestedExpColor())
  updateXP()

  tfb.events:Register("PLAYER_XP_UPDATE", "updateXP", updateXP)
  tfb.events:Register("PLAYER_LEVEL_UP", "updateXP", updateXP)
  tfb.events:Register("UPDATE_EXHAUSTION", "updateXP", updateXP)
  tfb.events:Register("QUEST_LOG_UPDATE", "updateXP", updateXP)
end

local function initWunderBar()
  initProgressTracking()

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

  if tfb.gameVersion:HasModernFactionSystems() then
    tfb.events:Register("UPDATE_FACTION", "paragonList", function()
      tfb.ParagonList:Refresh()
    end)
  end

  -- we wait 3 seconds to check the played time
  -- this gives other addons time to do this for us
  -- and pevents spamming the chatframe with /played
  C_Timer.After(3.0, function()
    if not initialTimeChecked then
      RequestTimePlayed()
    end
    initWunderBar()
    tfb.ParagonList:Refresh()

    -- Own ticker instead of reusing the max level one: that ticker does not exist
    -- while the XP bar is shown, and initMaxLvlBar can run more than once per
    -- session. This one is mode independent and runs for the whole session.
    C_Timer.NewTicker(30, function()
      tfb.birthday:Check()
    end)
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
  if barMode == "playtime" and not tfb.db:GetUseBlizzardExpBar() and not tfb.character:IsMaxLevel() then
    initExpBar()
  end

  C_Timer.After(5, RequestTimePlayed)
end
tfb.events:Register("UPDATE_EXPANSION_LEVEL", "expansionChange", onExpansionLevelChanged)

SLASH_TFB1 = "/tfb"
SlashCmdList["TFB"] = function()
  Settings.OpenToCategory(tfb.settingsCategory:GetID())
end
