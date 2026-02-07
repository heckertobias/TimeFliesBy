local _, tfb = ...

local initialTimeChecked = false

local function init()
  tfb.character:LoadCharacterData()

  -- we wait 3 seconds to check the played time
  -- this gives other addons time to do this for us
  -- and pevents spamming the chatframe with /played
  C_Timer.After(3.0, function()
    if not initialTimeChecked then
      RequestTimePlayed()
    end
  end)
end
tfb.events:Register("PLAYER_LOGIN", "init", init)

local function addTimeMessage(charKey)
  local expansionTime = tfb.db:GetCharPlaytimeCurrentExpansion(charKey)
  local totalTime = tfb.db:GetTotalPlaytime()
  local currentExpansion = tfb.gameVersion:GetCurrentExpansionName()

  tfb.chat:AddMessage("Total time played in " .. currentExpansion .. ": " .. tfb.chat:FormatPlaytime(expansionTime))
  tfb.chat:AddMessage("Total time played over all charaters: " .. tfb.chat:FormatPlaytime(totalTime))
end

local function writeTime(...)
  local totalTimePlayed = ...
  local versionString = tfb.gameVersion:GetCurrentGameVersionString()
  local charKey = tfb.character:GetCharKey()

  tfb.db:WriteTime(charKey, versionString, totalTimePlayed)
  addTimeMessage(charKey)

  initialTimeChecked = true
end
tfb.events:Register("TIME_PLAYED_MSG", "writeTime", writeTime)

-- SLASH_TIMEFLIESBY1 = "/tfb"
-- SLASH_TIMEFLIESBY2 = "/timefliesby"
-- SlashCmdList["TIMEFLIESBY"] = function(msg)
--   print("Time Files By")
--   --print(tfb.gameVersion:GetExpansionNameByVersion(msg))
--   --print(tfb.character:GetCharKey())
-- end
