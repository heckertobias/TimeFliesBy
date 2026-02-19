local frame = CreateFrame("Frame")
local repCache = {} -- Speichert alte Werte: [factionID] = earnedValue

frame:RegisterEvent("UPDATE_FACTION")

frame:SetScript("OnEvent", function(self, event, ...)
  if event == "UPDATE_FACTION" then
    for i = 1, C_Reputation.GetNumFactions() do -- Moderne API für Retail
      local factionData = C_Reputation.GetFactionDataByIndex(i)
      if factionData and not factionData.isHeader and factionData.factionID and factionData.currentStanding ~= repCache[factionData.factionID] then
        local delta = factionData.currentStanding and
            (factionData.currentStanding - (repCache[factionData.factionID] or 0)) or 0
        print(string.format("Ruf mit %s (%d) geändert: %d (neu: %d)", factionData.name, factionData.factionID, delta,
          factionData.currentStanding))
        repCache[factionData.factionID] = factionData.currentStanding
      end
    end
  end
end)

-- MAJOR_FACTION_RENOWN_LEVEL_CHANGED: majorFactionID, newRenownLevel, oldRenownLevel

-- https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetFriendshipReputationRanks
-- https://warcraft.wiki.gg/wiki/API_C_GossipInfo.GetFriendshipReputation

-- https://warcraft.wiki.gg/wiki/API_C_Reputation.IsMajorFaction
-- https://warcraft.wiki.gg/wiki/API_

-- https://warcraft.wiki.gg/wiki/API_C_Reputation.GetFactionDataByIndex
