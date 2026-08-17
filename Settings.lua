local _, tfb = ...

local panel = CreateFrame("Frame", "TFBSettingsPanel")
panel:Hide()

-- Title
local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Time Flies By")

-- Bar Position
local posLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
posLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
posLabel:SetText("Bar Position")

local presetNames = {
  [1] = "Top of Screen",
  [2] = "Bottom of Screen",
  [3] = "Below Chat Window",
  [4] = "Free Position",
}

local dropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
dropdown:SetPoint("TOPLEFT", posLabel, "BOTTOMLEFT", 0, -5)
dropdown:SetWidth(200)

-- Bar Height (always visible, anchored to dropdown)
local heightLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
heightLabel:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -20)
heightLabel:SetText("Bar Height")

local heightSlider = CreateFrame("Slider", "TFBHeightSlider", panel, "OptionsSliderTemplate")
heightSlider:SetPoint("TOPLEFT", heightLabel, "BOTTOMLEFT", 0, -20)
heightSlider:SetWidth(300)
heightSlider:SetMinMaxValues(1, 20)
heightSlider:SetValueStep(1)
heightSlider:SetObeyStepOnDrag(true)
heightSlider.Low:SetText("1")
heightSlider.High:SetText("20")
heightSlider.Text:SetText("")

local heightEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
heightEditBox:SetSize(60, 22)
heightEditBox:SetPoint("LEFT", heightSlider, "RIGHT", 20, 0)
heightEditBox:SetAutoFocus(false)

heightSlider:SetScript("OnValueChanged", function(_, value)
  value = math.floor(value + 0.5)
  heightEditBox:SetText(tostring(value))
  tfb.db:SetBarHeight(value)
  tfb.WunderBar:Reposition()
end)

heightEditBox:SetScript("OnEnterPressed", function(self)
  local val = tonumber(self:GetText())
  if val then
    val = math.floor(math.max(1, math.min(20, val)) + 0.5)
    heightSlider:SetValue(val)
  else
    self:SetText(tostring(math.floor(heightSlider:GetValue() + 0.5)))
  end
  self:ClearFocus()
end)

heightEditBox:SetScript("OnEscapePressed", function(self)
  self:SetText(tostring(math.floor(heightSlider:GetValue() + 0.5)))
  self:ClearFocus()
end)

-- ============================================
-- Controls for Preset 1-3 (Fixed Position)
-- ============================================

-- Y-Offset
local offsetLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
offsetLabel:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -20)
offsetLabel:SetText("Y-Offset")

local slider = CreateFrame("Slider", "TFBOffsetSlider", panel, "OptionsSliderTemplate")
slider:SetPoint("TOPLEFT", offsetLabel, "BOTTOMLEFT", 0, -20)
slider:SetWidth(300)
slider:SetMinMaxValues(-200, 200)
slider:SetValueStep(1)
slider:SetObeyStepOnDrag(true)
slider.Low:SetText("-200")
slider.High:SetText("200")
slider.Text:SetText("")

local editBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
editBox:SetSize(60, 22)
editBox:SetPoint("LEFT", slider, "RIGHT", 20, 0)
editBox:SetAutoFocus(false)

slider:SetScript("OnValueChanged", function(_, value)
  value = math.floor(value + 0.5)
  editBox:SetText(tostring(value))
  tfb.db:SetYOffset(value)
  tfb.WunderBar:Reposition()
end)

editBox:SetScript("OnEnterPressed", function(self)
  local val = tonumber(self:GetText())
  if val then
    val = math.floor(math.max(-200, math.min(200, val)) + 0.5)
    slider:SetValue(val)
  else
    self:SetText(tostring(math.floor(slider:GetValue() + 0.5)))
  end
  self:ClearFocus()
end)

editBox:SetScript("OnEscapePressed", function(self)
  self:SetText(tostring(math.floor(slider:GetValue() + 0.5)))
  self:ClearFocus()
end)

-- Text Follows Offset
local textFollowsCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
textFollowsCheckbox:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", -2, -20)

local textFollowsLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textFollowsLabel:SetPoint("LEFT", textFollowsCheckbox, "RIGHT", 2, 0)
textFollowsLabel:SetText("Text Follows Offset")

local textFollowsDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
textFollowsDesc:SetPoint("TOPLEFT", textFollowsCheckbox, "BOTTOMLEFT", 26, -2)
textFollowsDesc:SetText("When enabled, the text moves with the bar offset.")
textFollowsDesc:SetJustifyH("LEFT")

textFollowsCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetTextFollowsOffset(self:GetChecked())
  tfb.WunderBar:Reposition()
end)

-- Collect fixed-position controls for visibility toggling
local fixedControls = { offsetLabel, slider, editBox, textFollowsCheckbox, textFollowsLabel, textFollowsDesc }

-- ============================================
-- Controls for Preset 4 (Free Position)
-- ============================================

-- Lock Position
local lockCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
lockCheckbox:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", -2, -20)

local lockLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lockLabel:SetPoint("LEFT", lockCheckbox, "RIGHT", 2, 0)
lockLabel:SetText("Lock Position")

local lockDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
lockDesc:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 26, -2)
lockDesc:SetText("When locked, the bar cannot be dragged.")
lockDesc:SetJustifyH("LEFT")

lockCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetFreePositionLocked(self:GetChecked())
  tfb.WunderBar:SetLocked(self:GetChecked())
end)

-- Bar Width
local widthLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
widthLabel:SetPoint("TOPLEFT", lockCheckbox, "BOTTOMLEFT", 2, -25)
widthLabel:SetText("Bar Width")

local widthSlider = CreateFrame("Slider", "TFBWidthSlider", panel, "OptionsSliderTemplate")
widthSlider:SetPoint("TOPLEFT", widthLabel, "BOTTOMLEFT", 0, -20)
widthSlider:SetWidth(300)
widthSlider:SetMinMaxValues(50, 2000)
widthSlider:SetValueStep(1)
widthSlider:SetObeyStepOnDrag(true)
widthSlider.Low:SetText("50")
widthSlider.High:SetText("2000")
widthSlider.Text:SetText("")

local widthEditBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
widthEditBox:SetSize(60, 22)
widthEditBox:SetPoint("LEFT", widthSlider, "RIGHT", 20, 0)
widthEditBox:SetAutoFocus(false)

widthSlider:SetScript("OnValueChanged", function(_, value)
  value = math.floor(value + 0.5)
  widthEditBox:SetText(tostring(value))
  tfb.db:SetBarWidth(value)
  tfb.WunderBar:Reposition()
end)

widthEditBox:SetScript("OnEnterPressed", function(self)
  local val = tonumber(self:GetText())
  if val then
    val = math.floor(math.max(50, math.min(2000, val)) + 0.5)
    widthSlider:SetValue(val)
  else
    self:SetText(tostring(math.floor(widthSlider:GetValue() + 0.5)))
  end
  self:ClearFocus()
end)

widthEditBox:SetScript("OnEscapePressed", function(self)
  self:SetText(tostring(math.floor(widthSlider:GetValue() + 0.5)))
  self:ClearFocus()
end)

-- Text Position (Top / Bottom)
local textPosLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textPosLabel:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -20)
textPosLabel:SetText("Text Position")

local textPosDropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
textPosDropdown:SetPoint("TOPLEFT", textPosLabel, "BOTTOMLEFT", 0, -5)
textPosDropdown:SetWidth(200)
textPosDropdown:SetupMenu(function(_, rootDescription)
  local options = { { "bottom", "Bottom" }, { "top", "Top" } }
  for _, opt in ipairs(options) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetTextPosition() == opt[1]
    end, function()
      tfb.db:SetTextPosition(opt[1])
      tfb.WunderBar:Reposition()
    end, opt[1])
  end
end)

-- Text Alignment (Left / Center / Right)
local textAlignLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
textAlignLabel:SetPoint("TOPLEFT", textPosDropdown, "BOTTOMLEFT", 0, -20)
textAlignLabel:SetText("Text Alignment")

local textAlignDropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
textAlignDropdown:SetPoint("TOPLEFT", textAlignLabel, "BOTTOMLEFT", 0, -5)
textAlignDropdown:SetWidth(200)
textAlignDropdown:SetupMenu(function(_, rootDescription)
  local options = { { "LEFT", "Left" }, { "CENTER", "Center" }, { "RIGHT", "Right" } }
  for _, opt in ipairs(options) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetTextAlignment() == opt[1]
    end, function()
      tfb.db:SetTextAlignment(opt[1])
      tfb.WunderBar:Reposition()
    end, opt[1])
  end
end)

-- Collect free-position controls for visibility toggling
local freeControls = { lockCheckbox, lockLabel, lockDesc, widthLabel, widthSlider, widthEditBox, textPosLabel, textPosDropdown, textAlignLabel, textAlignDropdown }

-- ============================================
-- Use Blizzard Experience Bar (always visible)
-- ============================================

local blizzExpCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
-- Anchor will be set dynamically by updateControlVisibility

local blizzExpLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
blizzExpLabel:SetPoint("LEFT", blizzExpCheckbox, "RIGHT", 2, 0)
blizzExpLabel:SetText("Use Blizzard Experience Bar")

local blizzExpDesc = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
blizzExpDesc:SetPoint("TOPLEFT", blizzExpCheckbox, "BOTTOMLEFT", 26, -2)
blizzExpDesc:SetText("Show the default Blizzard XP bar while leveling.\nThe playtime bar is shown automatically at max level.\nRequires /reload to take effect.")
blizzExpDesc:SetJustifyH("LEFT")

blizzExpCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetUseBlizzardExpBar(self:GetChecked())
end)

-- ============================================
-- Visibility toggling
-- ============================================

local function updateControlVisibility()
  local preset = tfb.db:GetPositionPreset()
  local isFree = preset == 4

  for _, ctrl in ipairs(fixedControls) do
    if isFree then ctrl:Hide() else ctrl:Show() end
  end
  for _, ctrl in ipairs(freeControls) do
    if isFree then ctrl:Show() else ctrl:Hide() end
  end

  -- Reanchor blizzExpCheckbox below the last visible control group
  blizzExpCheckbox:ClearAllPoints()
  if isFree then
    blizzExpCheckbox:SetPoint("TOPLEFT", textAlignDropdown, "BOTTOMLEFT", -2, -20)
  else
    blizzExpCheckbox:SetPoint("TOPLEFT", textFollowsCheckbox, "BOTTOMLEFT", 0, -30)
  end
end

-- Setup dropdown with visibility update
dropdown:SetupMenu(function(_, rootDescription)
  for i = 1, 4 do
    rootDescription:CreateRadio(presetNames[i], function()
      return tfb.db:GetPositionPreset() == i
    end, function()
      tfb.db:SetPositionPreset(i)
      tfb.WunderBar:Reposition()
      if i == 4 then
        local locked = tfb.db:GetFreePositionLocked()
        tfb.WunderBar:SetLocked(locked)
      end
      updateControlVisibility()
    end, i)
  end
end)

-- Initialize controls when panel is shown
panel:SetScript("OnShow", function()
  slider:SetValue(tfb.db:GetYOffset() or 0)
  heightSlider:SetValue(tfb.db:GetBarHeight())
  widthSlider:SetValue(tfb.db:GetBarWidth())
  textFollowsCheckbox:SetChecked(tfb.db:GetTextFollowsOffset())
  lockCheckbox:SetChecked(tfb.db:GetFreePositionLocked())
  blizzExpCheckbox:SetChecked(tfb.db:GetUseBlizzardExpBar())
  updateControlVisibility()
end)

-- Register with Blizzard Settings
local category = Settings.RegisterCanvasLayoutCategory(panel, "Time Flies By")
tfb.settingsCategory = category
Settings.RegisterAddOnCategory(category)
