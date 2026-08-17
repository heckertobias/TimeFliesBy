local _, tfb = ...

tfb.instance = {}

local COMPETITIVE_INSTANCE_TYPES = {
  party    = true, -- Dungeons
  raid     = true, -- Raids
  pvp      = true, -- Battlegrounds
  arena    = true, -- Arenas
  scenario = true, -- Delves & Scenarios
}

function tfb.instance:IsInCompetitiveContent()
  local inInstance, instanceType = IsInInstance()
  return inInstance and COMPETITIVE_INSTANCE_TYPES[instanceType] == true
end
