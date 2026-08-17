local _, tfb = ...

tfb.character = {}

local playerName, realmName, englishRace, classToken

function tfb.character:GetCharKey()
  if not playerName or not realmName then
    playerName = UnitName("player")
    realmName = GetRealmName()
  end

  return playerName .. "-" .. realmName
end

function tfb.character:GetRace()
  if not englishRace then
    _, englishRace = UnitRace("player")
  end
  return englishRace
end

-- Blizzard removed the IsPlayerAtEffectiveMaxLevel / IsLevelAtEffectiveMaxLevel
-- FrameXML globals in 12.1.0, so every source is nil-guarded. GameRulesUtil is the
-- accurate one (it accounts for Timerunning levels above the purchased max), the
-- expansion getters are the backstop.
function tfb.character:IsMaxLevel()
  local level = UnitLevel("player") or 0

  local maxLevel
  if GameRulesUtil and GameRulesUtil.GetEffectiveMaxLevelForPlayer then
    maxLevel = GameRulesUtil.GetEffectiveMaxLevelForPlayer()
  end
  if not maxLevel and GetMaxLevelForPlayerExpansion then
    maxLevel = GetMaxLevelForPlayerExpansion()
  end
  if not maxLevel and GetMaxPlayerLevel then
    maxLevel = GetMaxPlayerLevel()
  end

  return maxLevel ~= nil and level >= maxLevel
end

function tfb.character:GetClassToken()
  if not classToken then
    _, classToken = UnitClass("player")
  end
  return classToken
end
