local _, tfb = ...

tfb.events = {}

local reg = {}
local events = CreateFrame("Frame")

local function runCallbacks(self, event, ...)
  if reg[event] then
    for _, data in ipairs(reg[event]) do
      if type(data[2]) == "function" then
        data[2](event, ...)
      end
    end
  end
end
events:SetScript("OnEvent", runCallbacks)

local function getEventId(name, event)
  if reg[event] then
    for index, data in pairs(reg[event]) do
      if data[1] == name then
        return index
      end
    end
  end
end

-- Registering an event the client does not know throws. Forever runs the retail
-- API on Vanilla content, so retail-only events can be missing there; a failed
-- registration drops the callback silently instead of erroring out the caller.
function tfb.events:Register(event, name, callback)
  local index = reg[event] and getEventId(name, event)
  if index then
    if callback then
      reg[event][index][2] = callback
    end
    return
  end

  if not reg[event] then
    if not pcall(events.RegisterEvent, events, event) then
      return
    end
    reg[event] = {}
  end

  tinsert(reg[event], { name, callback })
end

function tfb.events:Unregister(event, name)
  if not reg[event] then
    return
  end

  local index = getEventId(name, event)
  if index then
    tremove(reg[event], index)

    if #reg[event] == 0 then
      reg[event] = nil
      events:UnregisterEvent(event)
    end
  end
end
