local _, tfb = ...

local CHANNELS = {
  { "Master",   "Master" },
  { "SFX",      "Sound Effects" },
  { "Music",    "Music" },
  { "Ambience", "Ambience" },
  { "Dialog",   "Dialog" },
}

local settingsPanel = CreateFrame("Frame", "TFBBirthdaySettingsPanel")
settingsPanel:Hide()

local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("Birthday Jingle")

-- Enable
local enableCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
enableCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

local enableLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
enableLabel:SetPoint("LEFT", enableCheckbox, "RIGHT", 2, 0)
enableLabel:SetText("Play Birthday Jingle")

local enableDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
enableDesc:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 26, -2)
enableDesc:SetText("Plays a jingle whenever this character completes another full day\nof total time played (every 24 hours).")
enableDesc:SetJustifyH("LEFT")

enableCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetBirthdayJingleEnabled(self:GetChecked())
end)

-- Sound Channel
local channelLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
channelLabel:SetPoint("TOPLEFT", enableCheckbox, "BOTTOMLEFT", 2, -38)
channelLabel:SetText("Sound Channel")

local channelDropdown = CreateFrame("DropdownButton", nil, settingsPanel, "WowStyle1DropdownTemplate")
channelDropdown:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", 0, -5)
channelDropdown:SetWidth(200)
channelDropdown:SetupMenu(function(_, rootDescription)
  for _, opt in ipairs(CHANNELS) do
    rootDescription:CreateRadio(opt[2], function()
      return tfb.db:GetBirthdayJingleChannel() == opt[1]
    end, function()
      tfb.db:SetBirthdayJingleChannel(opt[1])
    end, opt[1])
  end
end)

local channelDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
channelDesc:SetPoint("TOPLEFT", channelDropdown, "BOTTOMLEFT", 2, -4)
channelDesc:SetText("Master ignores the individual volume sliders and always plays.\nThe other channels are muted when you disable them in the sound options.")
channelDesc:SetJustifyH("LEFT")

-- Play in Competitive Content
local competitiveCheckbox = CreateFrame("CheckButton", nil, settingsPanel, "UICheckButtonTemplate")
competitiveCheckbox:SetPoint("TOPLEFT", channelDesc, "BOTTOMLEFT", -4, -20)

local competitiveLabel = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
competitiveLabel:SetPoint("LEFT", competitiveCheckbox, "RIGHT", 2, 0)
competitiveLabel:SetText("Play in Competitive Content")

local competitiveDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
competitiveDesc:SetPoint("TOPLEFT", competitiveCheckbox, "BOTTOMLEFT", 26, -2)
competitiveDesc:SetText("When disabled, the jingle is skipped inside dungeons, raids, battlegrounds,\narenas and delves. The milestone is not played back later.")
competitiveDesc:SetJustifyH("LEFT")

competitiveCheckbox:SetScript("OnClick", function(self)
  tfb.db:SetBirthdayJinglePlayInCompetitive(self:GetChecked())
end)

-- Test
local testButton = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
testButton:SetPoint("TOPLEFT", competitiveCheckbox, "BOTTOMLEFT", 2, -38)
testButton:SetSize(120, 22)
testButton:SetText("Test Sound")

testButton:SetScript("OnClick", function()
  if not tfb.birthday:PlayJingle() then
    tfb.chat:AddMessage("Time Flies By: could not play the birthday jingle. Custom sound files are only picked up after a full game restart.")
  end
end)

local testDesc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
testDesc:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -6)
testDesc:SetText("Plays the jingle right now, even while the option above is disabled.")
testDesc:SetJustifyH("LEFT")

settingsPanel:SetScript("OnShow", function()
  enableCheckbox:SetChecked(tfb.db:GetBirthdayJingleEnabled())
  competitiveCheckbox:SetChecked(tfb.db:GetBirthdayJinglePlayInCompetitive())
end)

local subCategory = Settings.RegisterCanvasLayoutSubcategory(tfb.settingsCategory, settingsPanel, "Birthday Jingle")
Settings.RegisterAddOnCategory(subCategory)
