local _, tfb = ...

tfb.character = {}

local playerName, realmName

function tfb.character:LoadCharacterData()
  playerName = UnitName("player")
  realmName = GetRealmName()
end

function tfb.character:GetCharKey()
  if not playerName or not realmName then
    return false
  end
  return playerName .. "-" .. realmName
end
