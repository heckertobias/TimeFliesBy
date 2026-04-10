local _, tfb = ...

tfb.ParagonList = {}

local PADDING = 6
local HEADER_HEIGHT = 18
local ENTRY_HEIGHT = 14
local WIDTH = 220

local testMode = false

local COMPETITIVE_INSTANCE_TYPES = {
  party    = true, -- Dungeons
  raid     = true, -- Raids
  pvp      = true, -- Battlegrounds
  arena    = true, -- Arenas
  scenario = true, -- Delves & Scenarios
}

local function isInCompetitiveContent()
  local inInstance, instanceType = IsInInstance()
  return inInstance and COMPETITIVE_INSTANCE_TYPES[instanceType] == true
end
local TEST_REWARDS = {
  { name = "The Nightfallen",    r = 0.18, g = 0.58, b = 0.78 },
  { name = "Court of Farondis", r = 0.72, g = 0.53, b = 0.26 },
  { name = "Highmountain Tribe", r = 0.58, g = 0.00, b = 0.55 },
}

-- ============================================
-- List Frame
-- ============================================

local container = CreateFrame("Frame", "TFBParagonList", UIParent)
container:SetSize(WIDTH, HEADER_HEIGHT)
container:SetFrameStrata("MEDIUM")
container:Hide()

local bg = container:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(container)
bg:SetColorTexture(0, 0, 0, 0.6)

local header = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
header:SetTextColor(1, 1, 1)
header:SetText("Paragon Rewards")

local entries = {}

local function getEntry(index)
  if not entries[index] then
    entries[index] = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  end
  return entries[index]
end

local function hideEntries(from)
  for i = from, #entries do
    entries[i]:Hide()
  end
end

local function layoutEntries(rewards)
  local align = tfb.db:GetParagonListTextAlign()
  local useFactionColor = tfb.db:GetParagonListUseFactionColor()
  local count = #rewards
  local totalHeight = PADDING + HEADER_HEIGHT + PADDING + count * ENTRY_HEIGHT + PADDING

  container:SetSize(WIDTH, totalHeight)

  -- Header always at top, alignment determines horizontal anchor
  header:ClearAllPoints()
  if align == "RIGHT" then
    header:SetPoint("TOPRIGHT", container, "TOPRIGHT", -PADDING, -PADDING)
  else
    header:SetPoint("TOPLEFT", container, "TOPLEFT", PADDING, -PADDING)
  end

  for i, reward in ipairs(rewards) do
    local entry = getEntry(i)
    entry:ClearAllPoints()
    local yOffset = -(PADDING + HEADER_HEIGHT + PADDING + (i - 1) * ENTRY_HEIGHT)
    if align == "RIGHT" then
      entry:SetPoint("TOPRIGHT", container, "TOPRIGHT", -PADDING, yOffset)
    else
      entry:SetPoint("TOPLEFT", container, "TOPLEFT", PADDING, yOffset)
    end
    if useFactionColor then
      entry:SetTextColor(reward.r, reward.g, reward.b)
    else
      entry:SetTextColor(1, 1, 1)
    end
    entry:SetText(reward.name)
    entry:Show()
  end

  hideEntries(count + 1)
end

function tfb.ParagonList:Reposition()
  local x = tfb.db:GetParagonListX()
  local y = tfb.db:GetParagonListY()

  container:ClearAllPoints()
  if x and y then
    if tfb.db:GetParagonListGrowDirection() == "up" then
      container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
    else
      container:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x, y)
    end
  else
    container:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
  end
end

function tfb.ParagonList:Refresh()
  if not tfb.db:GetParagonListEnabled() then
    container:Hide()
    return
  end

  if tfb.db:GetParagonListHideInCompetitive() and isInCompetitiveContent() then
    container:Hide()
    return
  end

  local rewards = testMode and TEST_REWARDS or tfb.reputation:GetParagonRewards()

  if #rewards == 0 then
    container:Hide()
    return
  end

  if tfb.db:GetParagonListShowBackground() then
    bg:Show()
  else
    bg:Hide()
  end

  layoutEntries(rewards)
  container:Show()
end

function tfb.ParagonList:SetTestMode(enabled)
  testMode = enabled
  tfb.ParagonList:Refresh()
end

function tfb.ParagonList:SetLocked(locked)
  container:SetMovable(not locked)
  container:EnableMouse(not locked)
end

-- Drag
container:RegisterForDrag("LeftButton")
container:SetScript("OnDragStart", function(self)
  if not tfb.db:GetParagonListLocked() then
    self:StartMoving()
  end
end)
container:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  if tfb.db:GetParagonListGrowDirection() == "up" then
    tfb.db:SetParagonListPosition(self:GetLeft(), self:GetBottom())
  else
    tfb.db:SetParagonListPosition(self:GetLeft(), self:GetTop())
  end
end)

container:RegisterEvent("PLAYER_LOGIN")
container:RegisterEvent("PLAYER_ENTERING_WORLD")
container:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    tfb.ParagonList:Reposition()
    local locked = tfb.db:GetParagonListLocked()
    container:SetMovable(not locked)
    container:EnableMouse(not locked)
  elseif event == "PLAYER_ENTERING_WORLD" then
    tfb.ParagonList:Refresh()
  end
end)

-- ============================================
-- Settings Subcategory
-- ============================================

local settingsPanel = CreateFrame("Frame", "TFBParagonSettingsPanel")
settingsPanel:Hide()

local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Paragon Rewards")

-- Enable
local enableCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

local enableLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 2, 0)
enableLabel:SetText("Enable Paragon Rewards List")

enableCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetParagonListEnabled(self:GetChecked())
  tfb.ParagonList:Refresh()
end)

-- Grow Direction
local growLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
growLabel:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 2, -16)
growLabel:SetText("List Direction")

local growDropdown = CreateFrame("DropdownButton", nil, settingsPanel, "WowStyle1DropdownTemplate")
growDropdown:SetPoint("TOPLEFT", growLabel, "BOTTOMLEFT", 0, -5)
growDropdown:SetWidth(200)
growDropdown:SetupMenu(function(_, rootDescription)
  local options = { { "down", "Grow Down" }, { "up", "Grow Up" } }
  for _, opt in ipairs(options) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetParagonListGrowDirection() == opt[1]
    end, function()
      tfb.db:SetParagonListGrowDirection(opt[1])
      tfb.ParagonList:Reposition()
      tfb.ParagonList:Refresh()
    end, opt[1])
  end
end)

-- Text Alignment
local alignLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
alignLabel:SetPoint("TOPLEFT", growDropdown, "BOTTOMLEFT", 0, -20)
alignLabel:SetText("Text Alignment")

local alignDropdown = CreateFrame("DropdownButton", nil, settingsPanel, "WowStyle1DropdownTemplate")
alignDropdown:SetPoint("TOPLEFT", alignLabel, "BOTTOMLEFT", 0, -5)
alignDropdown:SetWidth(200)
alignDropdown:SetupMenu(function(_, rootDescription)
  local options = { { "LEFT", "Left" }, { "RIGHT", "Right" } }
  for _, opt in ipairs(options) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetParagonListTextAlign() == opt[1]
    end, function()
      tfb.db:SetParagonListTextAlign(opt[1])
      tfb.ParagonList:Refresh()
    end, opt[1])
  end
end)

-- Use Faction Color
local colorCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
colorCheckbox:SetPoint("TOPLEFT", alignDropdown, "BOTTOMLEFT", -2, -20)

local colorLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
colorLabel:SetPoint("LEFT", colorCheckbox, "RIGHT", 2, 0)
colorLabel:SetText("Use Faction Color")

local colorDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
colorDesc:SetPoint("TOPLEFT", colorCheckbox, "BOTTOMLEFT", 26, -2)
colorDesc:SetText("When enabled, faction names are shown in their faction color.\nWhen disabled, faction names are shown in white.")
colorDesc:SetJustifyH("LEFT")

colorCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetParagonListUseFactionColor(self:GetChecked())
  tfb.ParagonList:Refresh()
end)

-- Show Background
local bgCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
bgCheckbox:SetPoint("TOPLEFT", colorCheckbox, "BOTTOMLEFT", 0, -38)

local bgLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
bgLabel:SetPoint("LEFT", bgCheckbox, "RIGHT", 2, 0)
bgLabel:SetText("Show Background")

bgCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetParagonListShowBackground(self:GetChecked())
  tfb.ParagonList:Refresh()
end)

-- Test Mode
local testCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
testCheckbox:SetPoint("TOPLEFT", bgCheckbox, "BOTTOMLEFT", 0, -28)

local testLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
testLabel:SetPoint("LEFT", testCheckbox, "RIGHT", 2, 0)
testLabel:SetText("Test Mode")

local testDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
testDesc:SetPoint("TOPLEFT", testCheckbox, "BOTTOMLEFT", 26, -2)
testDesc:SetText("Shows placeholder entries to help with positioning.")
testDesc:SetJustifyH("LEFT")

testCheckbox:SetScript("OnClick", function(self)
  tfb.ParagonList:SetTestMode(self:GetChecked())
end)

-- Hide in Competitive Content
local competitiveCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
competitiveCheckbox:SetPoint("TOPLEFT", testCheckbox, "BOTTOMLEFT", 0, -38)

local competitiveLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
competitiveLabel:SetPoint("LEFT", competitiveCheckbox, "RIGHT", 2, 0)
competitiveLabel:SetText("Hide in Competitive Content")

local competitiveDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
competitiveDesc:SetPoint("TOPLEFT", competitiveCheckbox, "BOTTOMLEFT", 26, -2)
competitiveDesc:SetText("Hides the list inside dungeons, raids, battlegrounds, arenas, and delves.")
competitiveDesc:SetJustifyH("LEFT")

competitiveCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetParagonListHideInCompetitive(self:GetChecked())
  tfb.ParagonList:Refresh()
end)

-- Lock Position
local lockCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
lockCheckbox:SetPoint("TOPLEFT", competitiveCheckbox, "BOTTOMLEFT", 0, -38)

local lockLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lockLabel:SetPoint("LEFT", lockCheckbox, "RIGHT", 2, 0)
lockLabel:SetText("Lock Position")

local lockDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lockDesc:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 26, -2)
lockDesc:SetText("When locked, the list cannot be dragged.")
lockDesc:SetJustifyH("LEFT")

lockCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetParagonListLocked(self:GetChecked())
  tfb.ParagonList:SetLocked(self:GetChecked())
end)

settingsPanel:SetScript("OnShow", function()
  enableCheckbox:SetChecked(tfb.db:GetParagonListEnabled())
  colorCheckbox:SetChecked(tfb.db:GetParagonListUseFactionColor())
  bgCheckbox:SetChecked(tfb.db:GetParagonListShowBackground())
  testCheckbox:SetChecked(testMode)
  competitiveCheckbox:SetChecked(tfb.db:GetParagonListHideInCompetitive())
  lockCheckbox:SetChecked(tfb.db:GetParagonListLocked())
end)

local subCategory = Settings.RegisterCanvasLayoutSubcategory(tfb.settingsCategory, settingsPanel, "Paragon Rewards")
Settings.RegisterAddOnCategory(subCategory)
