local _, tfb = ...

tfb.reputation = {}

local repCache = {}

function tfb.reputation:GetReputationChange()
  for i = 1, C_Reputation.GetNumFactions() do
    local factionData = C_Reputation.GetFactionDataByIndex(i)

    if factionData and not factionData.isHeader and factionData.factionID then
      local name, standing, current, max, currentValue, r, g, b

      -- 1. Renown (Major Factions)
      if C_Reputation.IsMajorFaction(factionData.factionID) then
        local majorFactionData = C_MajorFactions.GetMajorFactionData(factionData.factionID)
        if majorFactionData then
          name = majorFactionData.name
          standing = "Renown " .. majorFactionData.renownLevel
          current = majorFactionData.renownReputationEarned
          max = majorFactionData.renownLevelThreshold
          currentValue = majorFactionData.renownReputationEarned
          -- Blizzard-Farben mit Fallback
          if majorFactionData.factionFontColor then
            r = majorFactionData.factionFontColor.color.r
            g = majorFactionData.factionFontColor.color.g
            b = majorFactionData.factionFontColor.color.b
          else
            r, g, b = tfb.colors:GetRenownColor()
          end
        end

        -- 2. Friendship
      else
        local friendshipData = C_GossipInfo.GetFriendshipReputation(factionData.factionID)
        if friendshipData and friendshipData.friendshipFactionID == factionData.factionID then
          if friendshipData and friendshipData.friendshipFactionID > 0 then
            name = friendshipData.name or factionData.name
            standing = friendshipData.reaction or ""
            current = friendshipData.standing - (friendshipData.reactionThreshold or 0)
            max = friendshipData.nextThreshold and (friendshipData.nextThreshold - friendshipData.reactionThreshold) or 1
            currentValue = friendshipData.standing
            r, g, b = tfb.colors:GetFriendshipColor()
          end

          -- 3. Klassische Ruffraktionen
        else
          name = factionData.name
          standing = _G["FACTION_STANDING_LABEL" .. (factionData.reaction or 4)] or ""
          current = factionData.currentStanding - factionData.currentReactionThreshold
          max = factionData.nextReactionThreshold - factionData.currentReactionThreshold
          currentValue = factionData.currentStanding
          if factionData.reaction then
            r, g, b = tfb.colors:GetFactionBarColor(factionData.reaction)
          end
        end
      end

      if C_Reputation.IsFactionParagonForCurrentPlayer(factionData.factionID) then
        local currentValue_paragon, threshold, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionData.factionID)
        if currentValue_paragon and threshold then
          standing = "Paragon"
          current = currentValue_paragon % threshold
          if hasRewardPending then
            current = current + threshold
          end
          max = threshold
          currentValue = currentValue_paragon
        end
      end

      -- Cache-Logik: Nur ausgeben bei Änderung
      if currentValue then
        local cached = repCache[factionData.factionID]

        if cached then
          -- Fraktion existiert im Cache - prüfe auf Änderung
          if cached ~= currentValue then
            repCache[factionData.factionID] = currentValue

            return {
              name = name,
              factionID = factionData.factionID,
              standing = standing,
              current = current,
              max = max,
              GetColor = function() return r or 1, g or 1, b or 1 end,
            }
          end
        else
          -- Fraktion existiert noch nicht im Cache - nur anlegen
          repCache[factionData.factionID] = currentValue
        end
      end
    end
  end

  return nil
end
