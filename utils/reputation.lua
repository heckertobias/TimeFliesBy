local _, tfb = ...

tfb.reputation = {}

local repCache = {}

-- Renown-style data, shared by major factions in the reputation list and by
-- journey tracks, which are major factions the reputation list leaves out.
-- Returns name, standing, current, max, currentValue, r, g, b - or nil.
local function normalizeMajorFaction(factionID, isJourney)
  if not (C_MajorFactions and C_MajorFactions.GetMajorFactionData) then
    return nil
  end

  local majorFactionData = C_MajorFactions.GetMajorFactionData(factionID)
  if not majorFactionData then
    return nil
  end

  -- Blizzard colors with fallback
  local r, g, b
  if majorFactionData.factionFontColor then
    r = majorFactionData.factionFontColor.color.r
    g = majorFactionData.factionFontColor.color.g
    b = majorFactionData.factionFontColor.color.b
  else
    r, g, b = tfb.colors:GetRenownColor()
  end

  -- Journey tracks count levels, they are not renown reputations.
  local standing = (isJourney and "Level " or "Renown ") .. majorFactionData.renownLevel

  return majorFactionData.name,
      standing,
      majorFactionData.renownReputationEarned,
      majorFactionData.renownLevelThreshold,
      majorFactionData.renownReputationEarned,
      r, g, b
end

-- Normalizes a FactionData entry into the values the bar needs.
-- Returns name, standing, current, max, currentValue, r, g, b
local function normalizeFaction(factionData)
  local name, standing, current, max, currentValue, r, g, b

  -- 1. Renown (Major Factions)
  if C_Reputation.IsMajorFaction(factionData.factionID) then
    name, standing, current, max, currentValue, r, g, b = normalizeMajorFaction(factionData.factionID, false)

    -- 2. Friendship
  else
    local friendshipData = C_GossipInfo.GetFriendshipReputation(factionData.factionID)
    if friendshipData and friendshipData.friendshipFactionID == factionData.factionID then
      if friendshipData and friendshipData.friendshipFactionID > 0 then
        name = friendshipData.name or factionData.name
        standing = friendshipData.reaction or ""
        currentValue = friendshipData.standing
        if friendshipData.nextThreshold then
          current = friendshipData.standing - (friendshipData.reactionThreshold or 0)
          max = friendshipData.nextThreshold - (friendshipData.reactionThreshold or 0)
        else
          -- Highest rank reached: the API stops reporting a next threshold.
          current, max = 0, 0
        end
        r, g, b = tfb.colors:GetFriendshipColor()
      end

      -- 3. Classic reputation factions
      -- Nil-guarded: header rows and account-wide entries do not always carry
      -- the standing fields.
    elseif factionData.currentStanding and factionData.currentReactionThreshold and factionData.nextReactionThreshold then
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

  return name, standing, current, max, currentValue, r, g, b
end

-- Updates the cache for one faction and returns the change payload.
-- Returns nil when nothing changed, when the faction is seen for the first time
-- (the first sighting only primes the cache) or when the faction sits at max
-- standing.
local function checkChange(factionID, name, standing, current, max, currentValue, r, g, b)
  if not currentValue then
    return nil
  end

  local cached = repCache[factionID]

  if cached then
    -- Faction exists in cache - check for change.
    -- The standing is compared too: on a renown level-up UPDATE_FACTION can
    -- report the new value with the old level, and the follow-up
    -- MAJOR_FACTION_RENOWN_LEVEL_CHANGED only changes the level.
    if cached.value ~= currentValue or cached.standing ~= standing then
      repCache[factionID] = { value = currentValue, standing = standing }

      -- Cache first, report second: a faction at max standing has no progress
      -- left to show, so it must not take the bar over. Its cache still has to
      -- follow along, otherwise a later paragon gain would look unchanged.
      if not max or max <= 0 then
        return nil
      end

      return {
        name = name,
        factionID = factionID,
        standing = standing,
        current = current,
        max = max,
        GetColor = function() return r or 1, g or 1, b or 1 end,
      }
    end
  else
    -- Faction not yet in cache - just initialize it
    repCache[factionID] = { value = currentValue, standing = standing }
  end

  return nil
end

-- Journey tracks (Delves season, Preyhunter's Journey, ...) live in the Adventure
-- Guide. They are major factions, but the reputation list omits them and even
-- C_Reputation.GetFactionDataByID returns nil for them, so they are collected by
-- ID here and read straight from C_MajorFactions.
local function collectJourneyFactionIDs()
  local ids = {}
  local seen = {}

  local function add(factionID)
    if factionID and factionID > 0 and not seen[factionID] then
      seen[factionID] = true
      table.insert(ids, factionID)
    end
  end

  if C_MajorFactions and C_MajorFactions.GetMajorFactionIDs and C_MajorFactions.ShouldDisplayMajorFactionAsJourney then
    -- Without an expansion filter this covers every major faction the client knows.
    for _, majorFactionID in ipairs(C_MajorFactions.GetMajorFactionIDs() or {}) do
      if C_MajorFactions.ShouldDisplayMajorFactionAsJourney(majorFactionID) then
        add(majorFactionID)
      end
    end
  end

  -- Fallback in case the current season's track is not flagged as a journey.
  if C_DelvesUI and C_DelvesUI.GetDelvesFactionForSeason then
    add(C_DelvesUI.GetDelvesFactionForSeason())
  end

  return ids
end

function tfb.reputation:GetReputationChange()
  local visited = {}

  for i = 1, C_Reputation.GetNumFactions() do
    local factionData = C_Reputation.GetFactionDataByIndex(i)

    if factionData and factionData.factionID then
      visited[factionData.factionID] = true

      local change = checkChange(factionData.factionID, normalizeFaction(factionData))
      if change then
        return change
      end
    end
  end

  for _, factionID in ipairs(collectJourneyFactionIDs()) do
    if not visited[factionID] then
      visited[factionID] = true

      -- Journey tracks are always cached, but only reported when enabled.
      -- Skipping the cache update instead would swallow the first gain after the
      -- setting is turned on, because a first sighting only primes.
      local change = checkChange(factionID, normalizeMajorFaction(factionID, true))
      if change and tfb.db:GetTrackJourneyProgress() then
        return change
      end
    end
  end

  return nil
end

function tfb.reputation:GetParagonRewards()
  local rewards = {}

  for i = 1, C_Reputation.GetNumFactions() do
    local factionData = C_Reputation.GetFactionDataByIndex(i)

    if factionData and factionData.factionID then
      if C_Reputation.IsFactionParagonForCurrentPlayer(factionData.factionID) then
        local _, _, _, hasRewardPending = C_Reputation.GetFactionParagonInfo(factionData.factionID)

        if hasRewardPending then
          local r, g, b

          if C_Reputation.IsMajorFaction(factionData.factionID) then
            local majorData = C_MajorFactions.GetMajorFactionData(factionData.factionID)
            if majorData and majorData.factionFontColor then
              r = majorData.factionFontColor.color.r
              g = majorData.factionFontColor.color.g
              b = majorData.factionFontColor.color.b
            else
              r, g, b = tfb.colors:GetRenownColor()
            end
          else
            r, g, b = tfb.colors:GetFactionBarColor(factionData.reaction or 8)
          end

          table.insert(rewards, {
            name = factionData.name,
            factionID = factionData.factionID,
            r = r or 1, g = g or 1, b = b or 1,
          })
        end
      end
    end
  end

  return rewards
end
