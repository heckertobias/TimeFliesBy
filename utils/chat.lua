local _, tfb = ...

tfb.chat = {}

local DEFAULT_COLOR = { 1.0, 0.82, 0.0 }

function tfb.chat:AddMessage(message, r, g, b)
  -- local rr = r or DEFAULT_COLOR[1]
  -- local gg = g or DEFAULT_COLOR[2]
  -- local bb = b or DEFAULT_COLOR[3]

  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
    DEFAULT_CHAT_FRAME:AddMessage(message, r or 1, g or 1, b or 0)
  end
end

-- Format playtime similar to /played output
-- seconds: total seconds
-- showSeconds: optional boolean, when true shows seconds even if larger units exist
function tfb.chat:FormatPlaytime(seconds, showSeconds)
  local s = tonumber(seconds) or 0
  local days = math.floor(s / 86400)
  s = s % 86400
  local hours = math.floor(s / 3600)
  s = s % 3600
  local minutes = math.floor(s / 60)
  local secs = s % 60

  local parts = {}
  if days > 0 then
    table.insert(parts, days .. (days == 1 and " day" or " days"))
  end
  if hours > 0 then
    table.insert(parts, hours .. (hours == 1 and " hour" or " hours"))
  end
  if minutes > 0 then
    table.insert(parts, minutes .. (minutes == 1 and " minute" or " minutes"))
  end

  -- Only include seconds if explicitly requested or if no larger unit exists
  if secs > 0 and (showSeconds or (#parts == 0)) then
    table.insert(parts, secs .. (secs == 1 and " second" or " seconds"))
  end

  if #parts == 0 then
    return "0 minutes"
  end

  return table.concat(parts, ", ")
end
