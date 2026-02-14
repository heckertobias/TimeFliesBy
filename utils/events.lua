local _, tfb = ...

tfb.events = {}

local reg = {}
local events = CreateFrame("Frame")

local function runCallbacks(self, event, ...)
  if reg[event] then
    for _, data in ipairs(reg[event]) do
      if type(data[2]) == "function" then
        data[2](...)
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

function tfb.events:Register(event, name, callback)
  if not reg[event] then
    reg[event] = {}
  end
  local index = getEventId(name, event)
  if not index then
    tinsert(reg[event], { name, callback })
    events:RegisterEvent(event)
  elseif callback then
    reg[event][index][2] = callback
  end
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
