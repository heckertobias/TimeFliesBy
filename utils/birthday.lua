local _, tfb = ...

tfb.birthday = {}

-- Same 24h cycle the playtime bar renders at max level.
local DAY = 86400

local SOUND_FILE = "Interface\\AddOns\\TimeFliesBy\\media\\happy-birthday.ogg"

-- The DB only stores the playtime reported by the last TIME_PLAYED_MSG, and
-- GetCurrentPlayed extrapolates from it. Until that message arrives, the stored
-- value is still the one written at the *previous* login and can be hours behind,
-- which would look like a freshly crossed milestone. Stay silent until then.
local hasFreshPlaytime = false

-- Plays the jingle regardless of the enable/competitive settings, so the options
-- panel can preview it. Returns whether the sound was actually started.
function tfb.birthday:PlayJingle()
  local willPlay = PlaySoundFile(SOUND_FILE, tfb.db:GetBirthdayJingleChannel())
  return willPlay
end

-- Advances the per-character day counter and celebrates at most once per crossing.
-- The counter moves even when the jingle stays silent, so a milestone reached while
-- muted is skipped rather than replayed later, and enabling the option afterwards
-- does not fire retroactively.
local function evaluate(played)
  if not played or played <= 0 then
    return
  end

  local charKey = tfb.character:GetCharKey()
  local days = floor(played / DAY)
  local celebrated = tfb.db:GetLastCelebratedDay(charKey)

  -- First run for this character: prime the counter without celebrating, so an
  -- existing character does not fire for every day it already played.
  if celebrated == nil then
    tfb.db:SetLastCelebratedDay(charKey, days)
    return
  end

  if days <= celebrated then
    return
  end

  -- Celebrate once even when several days were skipped at the same time.
  tfb.db:SetLastCelebratedDay(charKey, days)

  if not tfb.db:GetBirthdayJingleEnabled() then
    return
  end

  if not tfb.db:GetBirthdayJinglePlayInCompetitive() and tfb.instance:IsInCompetitiveContent() then
    return
  end

  tfb.birthday:PlayJingle()
end

function tfb.birthday:Check()
  if not hasFreshPlaytime then
    return
  end

  local charKey = tfb.character:GetCharKey()
  if not tfb.db:HasCharData(charKey) then
    return
  end

  evaluate(tfb.db:GetCurrentPlayed(charKey))
end

-- Uses the event payload rather than the DB, because this callback may run before
-- the one in TimeFliesBy.lua that persists the new value.
local function onTimePlayed(_, totalTimePlayed)
  hasFreshPlaytime = true
  evaluate(totalTimePlayed)
end
tfb.events:Register("TIME_PLAYED_MSG", "birthday", onTimePlayed)
