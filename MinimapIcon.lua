local _, tfb = ...

tfb.MinimapIcon = {}

local ICON_NAME = "TimeFliesBy"

local LDB = LibStub("LibDataBroker-1.1")
local LibDBIcon = LibStub("LibDBIcon-1.0")

local function addTimeLine(tooltip, label, seconds)
  tooltip:AddDoubleLine(label, tfb.chat:FormatPlaytime(seconds), 1, 0.82, 0, 1, 1, 1)
end

local dataObject = LDB:NewDataObject(ICON_NAME, {
  type = "launcher",
  text = "Time Flies By",
  icon = "Interface\\AddOns\\TimeFliesBy\\media\\icon",

  OnClick = function(_, button)
    if button == "LeftButton" then
      Settings.OpenToCategory(tfb.settingsCategory:GetID())
    end
  end,

  OnTooltipShow = function(tooltip)
    tooltip:AddLine("Time Flies By")

    local charKey = tfb.character:GetCharKey()
    if tfb.db:HasCharData(charKey) then
      local expansionName = tfb.gameVersion:GetCurrentExpansionName()
      local expansionLevel = tfb.gameVersion:GetCurrentExpansionLevel()

      addTimeLine(tooltip, "This character", tfb.db:GetCurrentPlayed(charKey))
      addTimeLine(tooltip, expansionName, tfb.db:GetCharPlaytimeCurrentExpansion(charKey))
      addTimeLine(tooltip, expansionName .. " (all characters)", tfb.db:GetAllCharsPlaytimeCurrentExpansion(expansionLevel))
      addTimeLine(tooltip, "All characters", tfb.db:GetTotalPlaytime())
    else
      -- Nothing is stored until the first TIME_PLAYED_MSG of this character.
      tooltip:AddLine("Waiting for playtime data...", 0.7, 0.7, 0.7)
    end

    tooltip:AddLine(" ")
    tooltip:AddLine("Click to open settings", 0, 1, 0)
  end,
})

function tfb.MinimapIcon:IsShown()
  return not tfb.db:GetMinimapIconDB().hide
end

function tfb.MinimapIcon:SetShown(shown)
  tfb.db:GetMinimapIconDB().hide = not shown
  if shown then
    LibDBIcon:Show(ICON_NAME)
  else
    LibDBIcon:Hide(ICON_NAME)
  end
end

-- SavedVariables are only loaded after this file runs, and LibDBIcon keeps a
-- reference to the table it is handed, so registration has to wait for login.
tfb.events:Register("PLAYER_LOGIN", "minimapIcon", function()
  LibDBIcon:Register(ICON_NAME, dataObject, tfb.db:GetMinimapIconDB())
end)
