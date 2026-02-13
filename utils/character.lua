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

function tfb.character:IsMaxLevel()
  return IsPlayerAtEffectiveMaxLevel()
end

function tfb.character:GetClassToken()
  if not classToken then
    _, classToken = UnitClass("player")
  end
  return classToken
end
