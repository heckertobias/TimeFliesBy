local _, tfb = ...

local DURATION_MIN = 5
local DURATION_MAX = 300
local DURATION_STEP = 5

local settingsPanel = CreateFrame("Frame", "TFBBarContentSettingsPanel")
settingsPanel:Hide()

-- The per-source sliders make the page taller than the settings canvas, so the
-- content lives in a scroll frame.
local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 0, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -28, 4)

local content = CreateFrame("Frame", nil, scrollFrame)
content:SetSize(1, 1)
scrollFrame:SetScrollChild(content)
scrollFrame:SetScript("OnSizeChanged", function(_, width)
  content:SetWidth(width)
end)

local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -12)
title:SetText("Bar Content")

local intro = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
intro:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
intro:SetText("Progress gains briefly take over the bar, then it returns to playtime or XP.")
intro:SetJustifyH("LEFT")

-- ============================================
-- Duration sliders
-- ============================================

local function snapDuration(value)
  value = math.max(DURATION_MIN, math.min(DURATION_MAX, value))
  return math.floor(value / DURATION_STEP + 0.5) * DURATION_STEP
end

-- onChange receives the snapped value.
local function createDurationSlider(name, onChange)
  local slider = CreateFrame("Slider", name, content, "OptionsSliderTemplate")
  slider:SetWidth(300)
  slider:SetMinMaxValues(DURATION_MIN, DURATION_MAX)
  slider:SetValueStep(DURATION_STEP)
  slider:SetObeyStepOnDrag(true)
  slider.Low:SetText(DURATION_MIN .. " s")
  slider.High:SetText(DURATION_MAX .. " s")
  slider.Text:SetText("")

  -- Parented to the slider so it is shown and hidden along with it.
  local editBox = CreateFrame("EditBox", nil, slider, "InputBoxTemplate")
  editBox:SetSize(60, 22)
  editBox:SetPoint("LEFT", slider, "RIGHT", 20, 0)
  editBox:SetAutoFocus(false)

  slider:SetScript("OnValueChanged", function(_, value)
    value = snapDuration(value)
    editBox:SetText(tostring(value))
    onChange(value)
  end)

  editBox:SetScript("OnEnterPressed", function(self)
    local val = tonumber(self:GetText())
    if val then
      slider:SetValue(snapDuration(val))
    end
    self:SetText(tostring(snapDuration(slider:GetValue())))
    self:ClearFocus()
  end)

  editBox:SetScript("OnEscapePressed", function(self)
    self:SetText(tostring(snapDuration(slider:GetValue())))
    self:ClearFocus()
  end)

  slider.editBox = editBox
  return slider
end

-- SetValue alone leaves the edit box empty when the value does not change.
local function setSliderValue(slider, value)
  slider:SetValue(value)
  slider.editBox:SetText(tostring(snapDuration(value)))
end

local durationLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
durationLabel:SetPoint("TOPLEFT", intro, "BOTTOMLEFT", 0, -20)
durationLabel:SetText("Display Duration (seconds)")

local durationSlider = createDurationSlider("TFBProgressDurationSlider", function(value)
  tfb.db:SetProgressDuration(value)
end)
durationSlider:SetPoint("TOPLEFT", durationLabel, "BOTTOMLEFT", 0, -20)

-- ============================================
-- While leveling
-- ============================================

local levelingCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
levelingCheckbox:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", -2, -30)

local levelingLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelingLabel:SetPoint("LEFT", levelingCheckbox, "RIGHT", 2, 0)
levelingLabel:SetText("Show Progress While Leveling")

local levelingDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
levelingDesc:SetPoint("TOPLEFT", levelingCheckbox, "BOTTOMLEFT", 26, -2)
levelingDesc:SetText("Progress gains also replace the XP bar for a while.\nXP keeps being counted for the \"Next Level in\" estimate meanwhile.")
levelingDesc:SetJustifyH("LEFT")

levelingCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetShowProgressWhileLeveling(self:GetChecked())
end)

local levelingDurationLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
levelingDurationLabel:SetPoint("TOPLEFT", levelingDesc, "BOTTOMLEFT", -24, -20)
levelingDurationLabel:SetText("Display Duration While Leveling (seconds)")

local levelingDurationSlider = createDurationSlider("TFBLevelingProgressDurationSlider", function(value)
  tfb.db:SetLevelingProgressDuration(value)
end)
levelingDurationSlider:SetPoint("TOPLEFT", levelingDurationLabel, "BOTTOMLEFT", 0, -20)

-- ============================================
-- Quest XP
-- ============================================

local questCheckbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
questCheckbox:SetPoint("TOPLEFT", levelingDurationSlider, "BOTTOMLEFT", -2, -30)

local questLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
questLabel:SetPoint("LEFT", questCheckbox, "RIGHT", 2, 0)
questLabel:SetText("Show Quest XP")

local questDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
questDesc:SetPoint("TOPLEFT", questCheckbox, "BOTTOMLEFT", 26, -2)
questDesc:SetText("Shows the XP of the quests in your log on the XP bar, split into quests\nready to turn in and quests still in progress. The text gets its own line.")
questDesc:SetJustifyH("LEFT")

questCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetShowQuestXP(self:GetChecked())
  tfb.RefreshXPBar()
end)

-- Sub-options for the two quest groups, indented below the main checkbox.
local function createQuestGroupCheckbox(anchor, text, setValue)
  local checkbox = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  checkbox:SetSize(24, 24)
  checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
  local label = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
  label:SetText(text)
  checkbox:SetScript("OnClick", function(self)
    setValue(tfb.db, self:GetChecked())
    tfb.RefreshXPBar()
  end)
  return checkbox
end

local questReadyCheckbox = createQuestGroupCheckbox(questDesc, "Quests Ready to Turn In", tfb.db.SetShowQuestXPReady)
local questOpenCheckbox = createQuestGroupCheckbox(questReadyCheckbox, "Quests in Progress", tfb.db.SetShowQuestXPOpen)

local questDisplayLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
questDisplayLabel:SetPoint("TOPLEFT", questOpenCheckbox, "BOTTOMLEFT", -24, -16)
questDisplayLabel:SetText("Quest XP Display")

local questDisplayDropdown = CreateFrame("DropdownButton", nil, content, "WowStyle1DropdownTemplate")
questDisplayDropdown:SetPoint("TOPLEFT", questDisplayLabel, "BOTTOMLEFT", 0, -5)
questDisplayDropdown:SetWidth(200)
questDisplayDropdown:SetupMenu(function(_, rootDescription)
  local options = { { "both", "Bar and Text" }, { "bar", "Bar Only" }, { "text", "Text Only" } }
  for _, opt in ipairs(options) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetQuestXPDisplay() == opt[1]
    end, function()
      tfb.db:SetQuestXPDisplay(opt[1])
      tfb.RefreshXPBar()
    end, opt[1])
  end
end)

-- ============================================
-- Tracked sources
-- ============================================

local trackLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
trackLabel:SetPoint("TOPLEFT", questDisplayDropdown, "BOTTOMLEFT", 0, -30)
trackLabel:SetText("Show Progress For")

local trackDesc = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
trackDesc:SetPoint("TOPLEFT", trackLabel, "BOTTOMLEFT", 0, -4)
trackDesc:SetText("A custom duration replaces the matching duration above for that source.")
trackDesc:SetJustifyH("LEFT")

local sources = {}

-- The last visible element of a source block and the x offset that leads back
-- from it to the column of the source checkboxes.
local function blockBottom(entry)
  local last = entry.overrides[#entry.overrides]
  if last.slider:IsShown() then
    return last.slider, -30, -22
  end
  return last.custom, -24, -2
end

-- Sources are stacked below each other; a block grows when one of its custom
-- duration sliders is shown, so everything below it is re-anchored.
local function layoutSources()
  local previous
  for _, entry in ipairs(sources) do
    entry.track:ClearAllPoints()
    if not previous then
      entry.track:SetPoint("TOPLEFT", trackDesc, "BOTTOMLEFT", -2, -6)
    else
      local anchor, x, y = blockBottom(previous)
      entry.track:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", x, y)
    end

    local above
    for _, override in ipairs(entry.overrides) do
      override.custom:ClearAllPoints()
      if not above then
        override.custom:SetPoint("TOPLEFT", entry.track, "BOTTOMLEFT", 24, 4)
      elseif above.slider:IsShown() then
        override.custom:SetPoint("TOPLEFT", above.slider, "BOTTOMLEFT", -6, -18)
      else
        override.custom:SetPoint("TOPLEFT", above.custom, "BOTTOMLEFT", 0, 2)
      end
      above = override
    end

    previous = entry
  end
end

-- Scroll range: from the top of the content to the bottom of the last block.
local function updateContentHeight()
  local bottom = blockBottom(sources[#sources])
  local top, lowest = content:GetTop(), bottom:GetBottom()
  if top and lowest then
    content:SetHeight(top - lowest + 30)
  end
end

local function relayout()
  layoutSources()
  updateContentHeight()
  -- Positions may only resolve on the next frame right after the panel opens.
  C_Timer.After(0, updateContentHeight)
end

local OVERRIDES = {
  { leveling = false, text = "Custom Duration at Max Level" },
  { leveling = true,  text = "Custom Duration While Leveling" },
}

local function getModeDefault(leveling)
  if leveling then
    return tfb.db:GetLevelingProgressDuration()
  end
  return tfb.db:GetProgressDuration()
end

-- key matches the progress payload's `source` and the per-source DB keys.
local function addSource(key, text, getTracked, setTracked)
  local entry = { key = key, getTracked = getTracked, overrides = {} }

  entry.track = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
  local trackText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  trackText:SetPoint("LEFT", entry.track, "RIGHT", 2, 0)
  trackText:SetText(text)
  entry.track:SetScript("OnClick", function(self)
    setTracked(tfb.db, self:GetChecked())
  end)

  for _, def in ipairs(OVERRIDES) do
    local override = { leveling = def.leveling }

    override.custom = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    override.custom:SetSize(24, 24)
    local customText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    customText:SetPoint("LEFT", override.custom, "RIGHT", 2, 0)
    customText:SetText(def.text)

    override.slider = createDurationSlider(nil, function(value)
      -- SetValue in OnShow fires this too; only a custom duration is stored.
      if override.custom:GetChecked() then
        tfb.db:SetSourceDuration(key, def.leveling, value)
      end
    end)
    override.slider:SetPoint("TOPLEFT", override.custom, "BOTTOMLEFT", 6, -14)
    override.slider:Hide()

    override.custom:SetScript("OnClick", function(self)
      if self:GetChecked() then
        tfb.db:SetSourceDuration(key, def.leveling, snapDuration(override.slider:GetValue()))
        override.slider:Show()
      else
        tfb.db:SetSourceDuration(key, def.leveling, nil)
        override.slider:Hide()
      end
      relayout()
    end)

    table.insert(entry.overrides, override)
  end

  table.insert(sources, entry)
end

addSource("reputation", "Reputation", tfb.db.GetTrackReputation, tfb.db.SetTrackReputation)
addSource("professions", "Profession Skills", tfb.db.GetTrackProfessions, tfb.db.SetTrackProfessions)
if tfb.gameVersion:HasWeaponSkills() then
  addSource("weaponSkills", "Weapon Skills", tfb.db.GetTrackWeaponSkills, tfb.db.SetTrackWeaponSkills)
end
if tfb.gameVersion:HasHousing() then
  addSource("housing", "Housing Favor", tfb.db.GetTrackHousing, tfb.db.SetTrackHousing)
end
if tfb.gameVersion:HasModernFactionSystems() then
  addSource("journey", "Journey Progress (Delves Season, Preyhunter's Journey, ...)", tfb.db.GetTrackJourneyProgress, tfb.db.SetTrackJourneyProgress)
end

settingsPanel:SetScript("OnShow", function()
  setSliderValue(durationSlider, tfb.db:GetProgressDuration())
  levelingCheckbox:SetChecked(tfb.db:GetShowProgressWhileLeveling())
  setSliderValue(levelingDurationSlider, tfb.db:GetLevelingProgressDuration())
  questCheckbox:SetChecked(tfb.db:GetShowQuestXP())
  questReadyCheckbox:SetChecked(tfb.db:GetShowQuestXPReady())
  questOpenCheckbox:SetChecked(tfb.db:GetShowQuestXPOpen())

  for _, entry in ipairs(sources) do
    entry.track:SetChecked(entry.getTracked(tfb.db))
    for _, override in ipairs(entry.overrides) do
      local custom = tfb.db:GetSourceDuration(entry.key, override.leveling)
      -- Checked state first: the slider callback only stores while it is set.
      override.custom:SetChecked(custom ~= nil)
      setSliderValue(override.slider, custom or getModeDefault(override.leveling))
      override.slider:SetShown(custom ~= nil)
    end
  end
  relayout()
end)

local subCategory = Settings.RegisterCanvasLayoutSubcategory(tfb.settingsCategory, settingsPanel, "Bar Content")
Settings.RegisterAddOnCategory(subCategory)
