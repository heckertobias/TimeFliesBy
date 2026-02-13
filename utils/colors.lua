local _, tfb = ...

tfb.colors = {}

local classColors = {
  WARRIOR     = { 0.78, 0.61, 0.43 },
  PALADIN     = { 0.96, 0.55, 0.73 },
  HUNTER      = { 0.67, 0.83, 0.45 },
  ROGUE       = { 1.00, 0.96, 0.41 },
  PRIEST      = { 1.00, 1.00, 1.00 },
  DEATHKNIGHT = { 0.77, 0.12, 0.23 },
  SHAMAN      = { 0.00, 0.44, 0.87 },
  MAGE        = { 0.41, 0.80, 0.94 },
  WARLOCK     = { 0.58, 0.51, 0.79 },
  MONK        = { 0.00, 1.00, 0.59 },
  DRUID       = { 1.00, 0.49, 0.04 },
  DEMONHUNTER = { 0.64, 0.19, 0.79 },
  EVOKER      = { 0.00, 0.78, 0.95 },
}

function tfb.colors:GetClassColor(classToken)
  local col = classColors[classToken]
  return col[1], col[2], col[3]
end

function tfb.colors:GetExpColor()
  return 0.58, 0.0, 0.55
end

function tfb.colors:GetRestedExpColor()
  return 0.0, 0.39, 0.88 --, 0.6
end
