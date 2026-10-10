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

-- Forever brings back the Vanilla skill window, backed by C_SkillInfo (absent
-- on retail). Its entries carry the real cap (maxRank) and the header they sit
-- under, which is the only language-independent way to tell weapon skills
-- (Defense and Feral Combat included) from professions.
local WEAPON_SKILLS_CATEGORY_ID = 6

-- Skill name -> skillID. GetSkillLineInfo only walks the lines that are visible
-- in the skill window, so a name seen once is looked up by ID afterwards, even
-- when its header has been collapsed since.
local skillIDs = {}

local function findSkillLine(skillName)
  if not C_SkillInfo or not C_SkillInfo.GetNumSkillLines then
    return nil
  end

  local skillID = skillIDs[skillName]
  if skillID and C_SkillInfo.GetSkillLineInfoByID then
    local info = C_SkillInfo.GetSkillLineInfoByID(skillID)
    if info then
      return info
    end
  end

  for i = 1, C_SkillInfo.GetNumSkillLines() do
    local info = C_SkillInfo.GetSkillLineInfo(i)
    -- Child lines (parentSkillLineID ~= 0) duplicate their profession.
    if info and not info.isHeader and info.parentSkillLineID == 0 then
      skillIDs[info.name] = info.skillID
      if info.name == skillName then
        return info
      end
    end
  end

  return nil
end

-- Primes the name -> ID cache while the skill window is still fully expanded.
function tfb.skill:Init()
  findSkillLine(nil)
end

-- Returns { name, current, max, isWeaponSkill, GetColor } or nil.
function tfb.skill:ParseSkillMsg(message)
  local skillUp = ERR_SKILL_UP_SI or SKILL_RANK_UP
  if not skillUp then return nil end

  local pattern = string.gsub(skillUp, "%%s", "(.+)")
  pattern = string.gsub(pattern, "%%d", "(%%d+)")

  local professionName, skillLevel = string.match(message, pattern)
  if not professionName or not skillLevel then return nil end

  skillLevel = tonumber(skillLevel)

  local skillLine = findSkillLine(professionName)
  if skillLine and skillLine.maxRank and skillLine.maxRank > 0 then
    local isWeaponSkill = skillLine.skillLineCategoryID == WEAPON_SKILLS_CATEGORY_ID
    return {
      name = professionName,
      current = skillLevel,
      max = skillLine.maxRank,
      isWeaponSkill = isWeaponSkill,
      GetColor = function()
        if isWeaponSkill then
          return tfb.colors:GetWeaponSkillColor()
        end
        return tfb.colors:GetProfessionColor()
      end,
    }
  end

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
