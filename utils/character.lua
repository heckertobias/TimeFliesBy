local _, tfb = ...

tfb.character = {}

local playerName, realmName, surname, englishRace, classToken

-- WoW Forever 1.60.1 replaced realms with regionally unique names: UnitName returns
-- the surname where retail returns the realm, and GetRealmName() answers "". A
-- realm-based key degrades to "Name-". Retail does not have this function.
function tfb.character:HasRegionalNames()
  return RegionalUniqueNamesEnabled ~= nil and RegionalUniqueNamesEnabled() == true
end

local function joinSurname(name, last)
  local consts = Constants and Constants.CharacterNameSeparatorConsts
  local separator = consts and consts.CHARACTERNAME_SURNAME_SEPARATOR or " "
  return name .. separator .. last
end

-- "Name-Realm" on retail, "Name Surname" under regional names. Nil while the surname
-- is not known yet: a key without it would be shared by every character with that
-- first name.
function tfb.character:GetCharKey()
  if tfb.character:HasRegionalNames() then
    if not surname then
      local name, last = UnitName("player")
      if not name or not last or last == "" then
        return nil
      end
      playerName, surname = name, last
    end
    return joinSurname(playerName, surname)
  end

  if not playerName or not realmName then
    playerName = UnitName("player")
    realmName = GetRealmName()
  end

  return playerName .. "-" .. realmName
end

-- Prefix of the keys this character was stored under before regional names:
-- "Name-<realm>", and "Name-" from versions that ran after the switch.
function tfb.character:GetLegacyKeyPrefix()
  if not tfb.character:HasRegionalNames() or not tfb.character:GetCharKey() then
    return nil
  end
  return playerName .. "-"
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
