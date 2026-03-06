local _, tfb = ...

tfb.WunderBar = {}

local bar = CreateFrame("StatusBar", "WunderBar", UIParent)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
bar:SetPoint("TOP", UIParent, "TOP", 0, 0)
bar:SetStatusBarColor(1, 1, 1)
bar:Hide()

local bar2 = CreateFrame("StatusBar", nil, bar)
bar2:SetAllPoints(bar)
bar2:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
bar2:SetFrameLevel(bar:GetFrameLevel() - 1)
bar2:SetStatusBarColor(0.7, 0.7, 0.7)
bar2:Hide()

local bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(bar)
bg:SetColorTexture(0, 0, 0, 0.5)

local text1 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text1:SetPoint("TOP", bar, "BOTTOM", 0, -2)
text1:SetTextColor(1, 1, 1)
text1:SetTextHeight(12)

local text2 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text2:SetPoint("TOP", bar, "BOTTOM", 0, -16)
text2:SetTextColor(1, 1, 1)
text2:SetTextHeight(12)
text2:Hide()

local function HideBlizzStatusBar()
  MainStatusTrackingBarContainer:Hide()
  MainStatusTrackingBarContainer:UnregisterAllEvents()
  StatusTrackingBarManager:Hide()
  StatusTrackingBarManager:UnregisterAllEvents()
end

local function updateText(fontString, text)
  if text then
    fontString:SetText(text)
    fontString:Show()
  else
    fontString:Hide()
  end
end

function tfb.WunderBar:SetText(str1, str2)
  updateText(text1, str1)
  updateText(text2, str2)
end

function tfb.WunderBar:SetValues(max, value1, value2)
  if max and max > 0 then
    bar:SetMinMaxValues(0, max)
    bar:SetValue(value1 or 0)
    bar:Show()

    if value2 and value2 > (value1 or 0) then
      bar2:SetMinMaxValues(0, max)
      bar2:SetValue(value2)
      bar2:Show()
    else
      bar2:Hide()
    end
  else
    bar:Hide()
    bar2:Hide()
  end
end

function tfb.WunderBar:SetBar1Color(r, g, b)
  bar:SetStatusBarColor(r, g, b)
end

function tfb.WunderBar:SetBar2Color(r, g, b)
  bar2:SetStatusBarColor(r, g, b)
end

local function positionText(textPos, alignment)
  text1:ClearAllPoints()
  text2:ClearAllPoints()
  text1:SetJustifyH(alignment)
  text2:SetJustifyH(alignment)

  local anchorH = alignment
  local barAnchorH = alignment
  local xOff = 0
  if alignment == "LEFT" then
    anchorH = "LEFT"
    barAnchorH = "LEFT"
    xOff = 2
  elseif alignment == "RIGHT" then
    anchorH = "RIGHT"
    barAnchorH = "RIGHT"
    xOff = -2
  end

  if textPos == "top" then
    if alignment == "CENTER" then
      text1:SetPoint("BOTTOM", bar, "TOP", 0, 2)
      text2:SetPoint("BOTTOM", bar, "TOP", 0, 16)
    else
      text1:SetPoint("BOTTOM" .. anchorH, bar, "TOP" .. barAnchorH, xOff, 2)
      text2:SetPoint("BOTTOM" .. anchorH, bar, "TOP" .. barAnchorH, xOff, 16)
    end
  else
    if alignment == "CENTER" then
      text1:SetPoint("TOP", bar, "BOTTOM", 0, -2)
      text2:SetPoint("TOP", bar, "BOTTOM", 0, -16)
    else
      text1:SetPoint("TOP" .. anchorH, bar, "BOTTOM" .. barAnchorH, xOff, -2)
      text2:SetPoint("TOP" .. anchorH, bar, "BOTTOM" .. barAnchorH, xOff, -16)
    end
  end
end

function tfb.WunderBar:Reposition()
  local preset = tfb.db:GetPositionPreset()
  local yOffset = tfb.db:GetYOffset() or 0
  local textFollows = tfb.db:GetTextFollowsOffset()

  bar:ClearAllPoints()
  text1:ClearAllPoints()
  text2:ClearAllPoints()
  text1:SetJustifyH("CENTER")
  text2:SetJustifyH("CENTER")

  if preset == 1 then
    -- Top of screen (default)
    bar:SetSize(GetScreenWidth(), tfb.db:GetBarHeight())
    bar:SetPoint("TOP", UIParent, "TOP", 0, yOffset)
    if textFollows then
      text1:SetPoint("TOP", bar, "BOTTOM", 0, -2)
      text2:SetPoint("TOP", bar, "BOTTOM", 0, -16)
    else
      text1:SetPoint("TOP", bar, "BOTTOM", 0, -2 - yOffset)
      text2:SetPoint("TOP", bar, "BOTTOM", 0, -16 - yOffset)
    end

  elseif preset == 2 then
    -- Bottom of screen, text above bar
    bar:SetSize(GetScreenWidth(), tfb.db:GetBarHeight())
    bar:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, -yOffset)
    if textFollows then
      text1:SetPoint("BOTTOM", bar, "TOP", 0, 2)
      text2:SetPoint("BOTTOM", bar, "TOP", 0, 16)
    else
      text1:SetPoint("BOTTOM", bar, "TOP", 0, 2 + yOffset)
      text2:SetPoint("BOTTOM", bar, "TOP", 0, 16 + yOffset)
    end

  elseif preset == 3 then
    -- Below main chat window
    bar:SetHeight(tfb.db:GetBarHeight())
    bar:SetPoint("TOPLEFT", ChatFrame1Background, "BOTTOMLEFT", 0, yOffset)
    bar:SetPoint("TOPRIGHT", ChatFrame1Background, "BOTTOMRIGHT", 0, yOffset)
    if textFollows then
      text1:SetPoint("TOP", bar, "BOTTOM", 0, -2)
      text2:SetPoint("TOP", bar, "BOTTOM", 0, -16)
    else
      text1:SetPoint("TOP", bar, "BOTTOM", 0, -2 - yOffset)
      text2:SetPoint("TOP", bar, "BOTTOM", 0, -16 - yOffset)
    end

  elseif preset == 4 then
    -- Free position
    local x = tfb.db:GetFreePositionX()
    local y = tfb.db:GetFreePositionY()
    bar:SetSize(tfb.db:GetBarWidth(), tfb.db:GetBarHeight())
    if x and y then
      bar:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
      -- Default: center of screen
      bar:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    positionText(tfb.db:GetTextPosition(), tfb.db:GetTextAlignment())
    return
  end

  -- Disable movable for presets 1-3
  bar:SetMovable(false)
  bar:EnableMouse(false)
end

function tfb.WunderBar:SetLocked(locked)
  if tfb.db:GetPositionPreset() ~= 4 then return end
  bar:SetMovable(not locked)
  bar:EnableMouse(not locked)
end

function tfb.WunderBar:HideBlizzStatusBar()
  HideBlizzStatusBar()
end

-- Drag handlers
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", function(self)
  if tfb.db:GetPositionPreset() == 4 and not tfb.db:GetFreePositionLocked() then
    self:StartMoving()
  end
end)
bar:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  if tfb.db:GetPositionPreset() == 4 then
    tfb.db:SetFreePosition(self:GetLeft(), self:GetTop())
  end
end)

bar:RegisterEvent("PLAYER_LOGIN")
bar:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    tfb.WunderBar:Reposition()
    -- Enable movable for preset 4
    if tfb.db:GetPositionPreset() == 4 then
      local locked = tfb.db:GetFreePositionLocked()
      bar:SetMovable(not locked)
      bar:EnableMouse(not locked)
    end
  end
end)
