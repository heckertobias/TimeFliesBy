local _, tfb = ...

tfb.housing = {}

local favorCache = {}

function tfb.housing:GetHousingChange(houseLevel, houseFavor, houseGUID)
  if not houseLevel or not houseFavor then
    return nil
  end

  local maxHouseLevel = C_Housing.GetMaxHouseLevel()
  if houseLevel >= maxHouseLevel then
    return nil
  end

  local maxFavor = C_Housing.GetHouseLevelFavorForLevel(houseLevel + 1)
  if not maxFavor or maxFavor <= 0 then
    return nil
  end

  local cached = favorCache[houseGUID]
  if cached then
    if cached == houseFavor then
      return nil
    end
    favorCache[houseGUID] = houseFavor
  else
    favorCache[houseGUID] = houseFavor
    return nil
  end

  local r, g, b = tfb.colors:GetHousingColor()

  return {
    name = "Housing",
    level = houseLevel,
    current = houseFavor,
    max = maxFavor,
    GetColor = function() return r, g, b end,
  }
end
