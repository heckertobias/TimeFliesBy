local _, tfb = ...

tfb.skill = {}

-- SkillLineID → maxSkillLevel for secondary professions
-- (GetProfessionInfoBySkillLineID returns maxSkillLevel=0 for secondary professions)
local SECONDARY_MAX_SKILL = {
  -- Fishing (Parent: 356)
  [2592] = 300,  -- Classic
  [2591] = 75,   -- The Burning Crusade
  [2590] = 75,   -- Wrath of the Lich King
  [2589] = 75,   -- Cataclysm
  [2588] = 75,   -- Mists of Pandaria
  [2587] = 100,  -- Warlords of Draenor
  [2586] = 100,  -- Legion
  [2585] = 175,  -- Battle for Azeroth
  [2754] = 200,  -- Shadowlands
  [2826] = 100,  -- Dragonflight
  [2876] = 300,  -- The War Within
  [2911] = 300,  -- Midnight
  -- Cooking (Parent: 185)
  [2548] = 300,  -- Classic
  [2547] = 75,   -- The Burning Crusade
  [2546] = 75,   -- Wrath of the Lich King
  [2545] = 75,   -- Cataclysm
  [2544] = 75,   -- Mists of Pandaria
  [2543] = 100,  -- Warlords of Draenor
  [2542] = 100,  -- Legion
  [2541] = 175,  -- Battle for Azeroth
  [2752] = 75,   -- Shadowlands
  [2824] = 100,  -- Dragonflight
  [2873] = 100,  -- The War Within
  [2908] = 100,  -- Midnight
  -- Archaeology (old skill system, no expansion tiers)
  [794]  = 950,
}

function tfb.skill:ParseSkillMsg(message)
  local pattern = string.gsub(ERR_SKILL_UP_SI, "%%s", "(.+)")
  pattern = string.gsub(pattern, "%%d", "(%%d+)")

  local professionName, skillLevel = string.match(message, pattern)
  if not professionName or not skillLevel then return nil end

  skillLevel = tonumber(skillLevel)
  local maxSkillLevel = nil

  -- Primary professions: maxSkillLevel from API (works reliably)
  local skillLinesToCheck = C_TradeSkillUI.GetAllProfessionTradeSkillLines() or {}
  for _, skillLineID in ipairs(skillLinesToCheck) do
    local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
    if info and info.professionName == professionName then
      maxSkillLevel = info.maxSkillLevel
      break
    end
  end

  -- Secondary professions: name matching via SkillLineID, maxSkillLevel from lookup table
  if not maxSkillLevel or maxSkillLevel == 0 then
    for skillLineID, max in pairs(SECONDARY_MAX_SKILL) do
      local info = C_TradeSkillUI.GetProfessionInfoBySkillLineID(skillLineID)
      if info and info.professionName == professionName then
        maxSkillLevel = max
        break
      end
    end
  end

  if not maxSkillLevel or maxSkillLevel == 0 then
    maxSkillLevel = math.max(100, math.ceil(skillLevel / 25) * 25)
  end

  return {
    name = professionName,
    current = skillLevel,
    max = maxSkillLevel,
    GetColor = function() return tfb.colors:GetProfessionColor() end,
  }
end
