local _, tfb = ...

tfb.WunderBar = {}

local bar = CreateFrame("StatusBar", "WunderBar", UIParent)
bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
bar:SetPoint("TOP", UIParent, "TOP", 0, 0)
bar:SetStatusBarColor(1, 1, 1)
-- Room below the bar for, top to bottom: rested segment, quest XP segments and
-- background.
bar:SetFrameLevel(bar:GetFrameLevel() + 3)
bar:Hide()

local bar2 = CreateFrame("StatusBar", nil, bar)
bar2:SetAllPoints(bar)
bar2:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
bar2:SetFrameLevel(bar:GetFrameLevel() - 1)
bar2:SetStatusBarColor(0.7, 0.7, 0.7)
bar2:Hide()

-- Quest XP segments. Like rested XP they start at the current XP, so they sit
-- below the rested segment instead of being stacked behind it: rested XP stays
-- in front, the quest segments show where they reach beyond it.
local questFrame = CreateFrame("Frame", nil, bar)
questFrame:SetAllPoints(bar)
questFrame:SetFrameLevel(bar2:GetFrameLevel() - 1)
questFrame:Hide()

local questReady = questFrame:CreateTexture(nil, "ARTWORK")
local questOpen = questFrame:CreateTexture(nil, "ARTWORK")

-- Fractions of the bar width, kept so the segments follow size changes.
local questSegments

local function setSegment(texture, from, to)
  local width = bar:GetWidth()
  if to <= from or width <= 0 then
    texture:Hide()
    return
  end
  texture:ClearAllPoints()
  texture:SetPoint("TOPLEFT", bar, "TOPLEFT", width * from, 0)
  texture:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", width * from, 0)
  texture:SetWidth(width * (to - from))
  texture:Show()
end

local function layoutQuestSegments()
  if not questSegments then return end
  setSegment(questReady, questSegments.xp, questSegments.ready)
  setSegment(questOpen, questSegments.ready, questSegments.open)
end

bar:HookScript("OnSizeChanged", layoutQuestSegments)

-- The background sits on its own frame below everything else, so it dims
-- neither the rested nor the quest XP segments.
local bgFrame = CreateFrame("Frame", nil, bar)
bgFrame:SetAllPoints(bar)
bgFrame:SetFrameLevel(questFrame:GetFrameLevel() - 1)

local bg = bgFrame:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(bgFrame)
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

local text3 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text3:SetPoint("TOP", bar, "BOTTOM", 0, -30)
text3:SetTextColor(1, 1, 1)
text3:SetTextHeight(12)
text3:Hide()

-- One more line beyond text2, in the direction the text grows (down below the
-- bar, up above it). Anchored to text2's slot rather than to text2 itself, so it
-- keeps its place while text2 is hidden.
local TEXT_LINE_STEP = 14

local function positionText3()
  local point, relativeTo, relativePoint, x, y = text2:GetPoint(1)
  if not point then return end
  local step = point:find("^TOP") and -TEXT_LINE_STEP or TEXT_LINE_STEP
  text3:ClearAllPoints()
  text3:SetPoint(point, relativeTo, relativePoint, x, y + step)
  text3:SetJustifyH(text2:GetJustifyH())
end

local function HideBlizzStatusBar()
  MainStatusTrackingBarContainer:Hide()
  MainStatusTrackingBarContainer:UnregisterAllEvents()
  StatusTrackingBarManager:Hide()
  StatusTrackingBarManager:UnregisterAllEvents()
end

-- Blizzard's top center widget container (battleground objectives, capture bars)
-- is anchored right below the screen edge and collides with the bar when the
-- "Top" preset is active. Push it down past the bar and its text lines.
local TEXT_LINE_HEIGHT = 12
local TOP_WIDGET_PADDING = 4
local TOP_WIDGET_DEFAULT_DROP = 15

local topWidgetAnchor
local applyingTopWidget = false

-- Distance from the screen top down to the lowest part of our bar (0 if hidden).
local function GetTopOccupiedHeight()
  if not bar:IsShown() then return 0 end

  local yOffset = tfb.db:GetYOffset() or 0
  local depth = -yOffset + tfb.db:GetBarHeight()

  if text1:IsShown() then
    local lineOffset = 2
    if text3:IsShown() then
      lineOffset = 16 + TEXT_LINE_STEP
    elseif text2:IsShown() then
      lineOffset = 16
    end
    local textDepth = depth + lineOffset + TEXT_LINE_HEIGHT
    if not tfb.db:GetTextFollowsOffset() then
      -- Text keeps its original screen position while the bar moves
      textDepth = textDepth + yOffset
    end
    depth = math.max(depth, textDepth)
  end

  return depth
end

local function ShiftTopCenterWidgets()
  local frame = UIWidgetTopCenterContainerFrame
  if not frame or applyingTopWidget then return end

  if tfb.db:GetPositionPreset() ~= 1 then
    if topWidgetAnchor then
      applyingTopWidget = true
      frame:ClearAllPoints()
      frame:SetPoint(topWidgetAnchor[1], topWidgetAnchor[2], topWidgetAnchor[3],
        topWidgetAnchor[4], topWidgetAnchor[5])
      applyingTopWidget = false
      topWidgetAnchor = nil
    end
    return
  end

  if not topWidgetAnchor then
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if point then
      topWidgetAnchor = { point, relativeTo or UIParent, relativePoint or point, x or 0, y or 0 }
    end
  end

  local drop = math.max(TOP_WIDGET_DEFAULT_DROP, GetTopOccupiedHeight() + TOP_WIDGET_PADDING)
  applyingTopWidget = true
  frame:ClearAllPoints()
  frame:SetPoint("TOP", UIParent, "TOP", 0, -drop)
  applyingTopWidget = false
end

local function updateText(fontString, text)
  if text then
    fontString:SetText(text)
    fontString:Show()
  else
    fontString:Hide()
  end
end

function tfb.WunderBar:SetText(str1, str2, str3)
  updateText(text1, str1)
  updateText(text2, str2)
  updateText(text3, str3)
  ShiftTopCenterWidgets()
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
  -- Every other display (playtime, progress gains) would otherwise keep the
  -- quest segments of the XP bar; the XP bar sets them again after this.
  questSegments = nil
  questFrame:Hide()
  ShiftTopCenterWidgets()
end

-- Draws the quest XP segments: readyXP right after the current XP, openXP after
-- that. Call after SetValues, which clears them.
function tfb.WunderBar:SetQuestValues(max, xp, readyXP, openXP)
  if not max or max <= 0 or (readyXP <= 0 and openXP <= 0) then
    questSegments = nil
    questFrame:Hide()
    return
  end

  local function fraction(value)
    return math.max(0, math.min(1, value / max))
  end

  questSegments = {
    xp = fraction(xp),
    ready = fraction(xp + readyXP),
    open = fraction(xp + readyXP + openXP),
  }
  questReady:SetColorTexture(tfb.colors:GetQuestReadyColor())
  questOpen:SetColorTexture(tfb.colors:GetQuestOpenColor())
  layoutQuestSegments()
  questFrame:Show()
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
  positionText3()
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
    ShiftTopCenterWidgets()
    return
  end

  positionText3()

  -- Disable movable for presets 1-3
  bar:SetMovable(false)
  bar:EnableMouse(false)

  ShiftTopCenterWidgets()
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
    -- Blizzard may re-anchor the container on its own (layout changes, other addons)
    if UIWidgetTopCenterContainerFrame then
      hooksecurefunc(UIWidgetTopCenterContainerFrame, "SetPoint", ShiftTopCenterWidgets)
    end
    tfb.WunderBar:Reposition()
    -- Re-apply after zone changes (entering a battleground rebuilds the widgets)
    tfb.events:Register("PLAYER_ENTERING_WORLD", "WunderBarTopWidgets", ShiftTopCenterWidgets)
    -- Enable movable for preset 4
    if tfb.db:GetPositionPreset() == 4 then
      local locked = tfb.db:GetFreePositionLocked()
      bar:SetMovable(not locked)
      bar:EnableMouse(not locked)
    end
  end
end)
