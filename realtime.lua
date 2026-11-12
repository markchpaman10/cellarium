-- PC elapsed seconds are authoritative. The biology engine's legacy numerical
-- rate unit is now one real minute; it is never exposed as simulated hours.
local Clock={version=1,secondsPerBiologyUnit=60}
local sessions=setmetatable({},{__mode='k'})
function Clock.duration(seconds)
 local n=math.max(0,math.ceil(seconds or 0));local minutes=math.floor(n/60);local sec=n%60
 if minutes<60 then return string.format('%02d:%02d',minutes,sec) end
 local hours=math.floor(minutes/60);if hours<24 then return string.format('%02d:%02d:%02d',hours,minutes%60,sec) end
 return string.format('%dd %02d:%02d:%02d',math.floor(hours/24),hours%24,minutes%60,sec)
end
function Clock.biologyDuration(value) return Clock.duration((value or 0)*60) end
function Clock.ensure(s,stamp)
 s.clock=s.clock or {version=1,elapsedSeconds=(s.time or 0)*60,pendingSeconds=0,lastSeenUnix=stamp or os.time()}
 local c=s.clock;assert(c.version==1,'Unsupported real-time clock version')
 c.pendingSeconds=math.max(0,c.pendingSeconds or 0);c.elapsedSeconds=c.elapsedSeconds or (s.time or 0)*60
 if s.desktop then s.desktop.settings.offlineCap=nil;s.desktop.settings.simulationRate=nil end
 return c
end
function Clock.start(s,stamp,unix,mono)
 if sessions[s] then return s.clock end
 unix=unix or os.time();mono=mono or love.timer.getTime();local hadClock=s.clock~=nil;local c=Clock.ensure(s,unix)
 if not hadClock then c.lastSeenUnix=unix;c.migratedFromLegacy=stamp~=nil end
 local away=math.max(0,unix-(c.lastSeenUnix or stamp or unix));c.pendingSeconds=c.pendingSeconds+away;c.lastSeenUnix=math.max(c.lastSeenUnix or unix,unix)
 c.lastOfflineSeconds=away;sessions[s]={wall=unix,mono=mono,observed=0};return c
end
function Clock.observe(s,unix,mono)
 unix=unix or os.time();mono=mono or love.timer.getTime();if not sessions[s] then Clock.start(s,nil,unix,mono);return 0 end
 local session=sessions[s];local c=Clock.ensure(s);local elapsed=math.max(0,unix-session.wall,mono-session.mono)
 local delta=math.max(0,elapsed-session.observed);session.observed=math.max(session.observed,elapsed)
 c.pendingSeconds=c.pendingSeconds+delta;c.lastSeenUnix=math.max(c.lastSeenUnix or unix,unix,session.wall+session.observed)
 return delta
end
function Clock.process(s,advance,maxSeconds)
 local c=Clock.ensure(s);local amount=math.min(c.pendingSeconds,maxSeconds or 300)
 if amount<.000001 then return 0 end
 -- Long absences are processed in responsive batches, not truncated. Coarser
 -- integration is internal catch-up work, never a player speed control.
 c.integrationStepSeconds=c.pendingSeconds>60 and 5 or .05
 local ok,why=pcall(advance,s,amount/60);c.integrationStepSeconds=nil;if not ok then error(why,0) end
 c.pendingSeconds=math.max(0,c.pendingSeconds-amount);c.elapsedSeconds=c.elapsedSeconds+amount;return amount
end
function Clock.update(s,advance,unix,mono,maxSeconds) Clock.observe(s,unix,mono);return Clock.process(s,advance,maxSeconds) end
function Clock.busy(s) return s.clock and s.clock.pendingSeconds>5 end
function Clock.status(s) return Clock.busy(s) and ('Synchronizing '..Clock.duration(s.clock.pendingSeconds)..' remaining') or 'PC clock / real time' end
function Clock.visual(s) return s.clock and (s.clock.elapsedSeconds+s.clock.pendingSeconds) or s.time end
function Clock.hasSession(s) return sessions[s]~=nil end
function Clock.sync(s,advance) if sessions[s] then Clock.update(s,advance) end;return not Clock.busy(s) end
function Clock.wallTime() return os.date('%I:%M:%S %p') end
return Clock
