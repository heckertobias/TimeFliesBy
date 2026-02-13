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
text1:SetPoint("TOP", bar, "BOTTOM", 0, -2);
text1:SetTextColor(1, 1, 1)
text1:SetTextHeight(12)

local text2 = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text2:SetPoint("TOP", bar, "BOTTOM", 0, -16)
text2:SetTextColor(1, 1, 1)
text2:SetTextHeight(12)
text2:Hide()

local function HideBlizzStatusBar()
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

bar:RegisterEvent("PLAYER_LOGIN")
bar:SetScript("OnEvent", function(self, event, ...)
  if event == "PLAYER_LOGIN" then
    bar:SetSize(GetScreenWidth(), 5)
    HideBlizzStatusBar()
  end
end)
