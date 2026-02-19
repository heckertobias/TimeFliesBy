-- SkillNotifier.lua
local frame = CreateFrame("Frame")

frame:RegisterEvent("CHAT_MSG_SKILL")

frame:SetScript("OnEvent", function(self, event, arg1)
  if event == "CHAT_MSG_SKILL" then
    local skillName, skillLevel = arg1:match("Your skill in (.+) has increased to (%d+)")
    -- local profName, skill = arg1:match("Your skill in ([^%s]+) has increased to ([^%d]+).")
    print(arg1)
    if skillName then
      print("Letzter Skill-Up: " .. skillName)
      print("Letzter Skill-Level: " .. skillLevel)
    end
    return
  end
end)
