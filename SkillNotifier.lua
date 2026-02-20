-- Expansions-Tier SkillLine-IDs für sekundäre Berufe
-- (GetAllProfessionTradeSkillLines gibt nur Hauptberufe zurück)
local SECONDARY_SKILL_LINES = {
  -- Fishing (Parent: 356)
  356, 2592, 2591, 2590, 2589, 2588, 2587, 2586, 2585, 2754, 2826,
  -- Cooking (Parent: 185)
  185, 2548, 2547, 2546, 2545, 2544, 2543, 2542, 2541, 2752, 2824,
  -- Archaeology (altes Skill-System, keine Expansions-Tiers)
  794,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_SKILL")

frame:SetScript("OnEvent", function(self, event, message)
  -- Nutze den offiziellen Blizzard-String
  local pattern = string.gsub(ERR_SKILL_UP_SI, "%%s", "(.+)")
  pattern = string.gsub(pattern, "%%d", "(%%d+)")

  local professionName, skillLevel = string.match(message, pattern)

  if professionName and skillLevel then
    skillLevel = tonumber(skillLevel)

    local maxSkillLevel = 100 -- Fallback

    -- Hauptberufe (API) + sekundäre Berufe (hardcoded) kombinieren
    local skillLinesToCheck = C_TradeSkillUI.GetAllProfessionTradeSkillLines() or {}
    for _, id in ipairs(SECONDARY_SKILL_LINES) do
      skillLinesToCheck[#skillLinesToCheck + 1] = id
    end

    for _, skillLineID in ipairs(skillLinesToCheck) do
      local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
      if info and info.professionName == professionName then
        maxSkillLevel = info.maxSkillLevel
        break
      end
    end

    print(professionName)
    print(skillLevel)
    print(maxSkillLevel)
  end
end)
