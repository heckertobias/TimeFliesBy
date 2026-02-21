local _, tfb = ...

tfb.colors = {}

function tfb.colors:GetClassColor(classToken)
  return GetClassColor(classToken)
end

function tfb.colors:GetExpColor()
  return 0.58, 0.0, 0.55
end

function tfb.colors:GetRestedExpColor()
  return 0.0, 0.39, 0.88 --, 0.6
end

function tfb.colors:GetProfessionColor()
  return 0.89, 0.59, 0.15
end

function tfb.colors:GetFriendshipColor()
  return 0.0, 1.0, 0.5
end

function tfb.colors:GetRenownColor()
  return 0.0, 0.5, 1.0
end

function tfb.colors:GetFactionBarColor(reaction)
  if reaction and FACTION_BAR_COLORS then
    local color = FACTION_BAR_COLORS[reaction]
    if color then
      return color.r, color.g, color.b
    end
  end
  return 1.0, 1.0, 1.0
end
