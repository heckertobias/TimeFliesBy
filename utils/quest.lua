local _, tfb = ...

tfb.quest = {}

-- Sums the XP rewards of all quests in the log that still have to be turned in.
-- Returns readyXP (objectives done, only the turn-in is missing) and openXP
-- (objectives still in progress). Bonus objectives and world quests (tasks) are
-- left out: they are only in the log while in their area and reward on their
-- own without a turn-in.
function tfb.quest:GetQuestXP()
  local readyXP, openXP = 0, 0

  if not C_QuestLog or not C_QuestLog.GetNumQuestLogEntries or not GetQuestLogRewardXP then
    return readyXP, openXP
  end

  for i = 1, C_QuestLog.GetNumQuestLogEntries() do
    local info = C_QuestLog.GetInfo(i)
    if info and not info.isHeader and not info.isHidden and not info.isTask and not info.isBounty
        and info.questID and info.questID > 0 then
      -- Can be 0 until the quest data has loaded; QUEST_LOG_UPDATE follows then.
      local xp = GetQuestLogRewardXP(info.questID) or 0
      if xp > 0 then
        if C_QuestLog.IsComplete(info.questID) then
          readyXP = readyXP + xp
        else
          openXP = openXP + xp
        end
      end
    end
  end

  return readyXP, openXP
end
