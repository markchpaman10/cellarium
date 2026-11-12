local M=require('desktop_model');local H=require('habitat');local G=require('genome');local W={}
local function water(kind,seed)
 local h=H.new(seed);h.plants={};h.obstacles={};h.water=1;h.salinity=kind=='saltwater' and 1 or 0;h.quality=1;h.dissolvedOxygen=.9;h.waste=0;h.volume=2.6;h.humidity=1
 for i,c in ipairs(h.cells) do c.kind=kind;c.depth=.65;c.salinity=h.salinity;c.oxygen=h.dissolvedOxygen;c.obstacle=false;c.elevation=0;c.shelter=i%11==0 and .5 or 0 end
 return h
end
function W.ensure(s)
 local d=M.ensure(s)
 if #d.worlds==0 then
  d.worlds={{id='terrarium',kind='terrarium',name='Mixed terrestrial mesocosm',habitat=s.habitat,food=s.food,seed=s.seed,accumulator=s.accumulator or 0,time=s.time,capacity=30},{id='freshwater',kind='freshwater',name='Freshwater aquarium',habitat=water('freshwater',231),food={},seed=231,accumulator=0,time=s.time,capacity=16},{id='saltwater',kind='saltwater',name='Saltwater aquarium',habitat=water('saltwater',541),food={},seed=541,accumulator=0,time=s.time,capacity=16},{id='desktop',kind='desktop',name='Dry desktop',habitat=water('land',761),food={},seed=761,accumulator=0,time=s.time,capacity=8}}
  local dry=d.worlds[4].habitat;dry.water=0;dry.humidity=.3;for _,c in ipairs(dry.cells) do c.kind='land';c.depth=0;c.salinity=0;c.oxygen=1 end
 end
 for _,o in ipairs(s.organisms) do o.worldId=o.worldId or 'terrarium' end
 for _,e in ipairs(s.eggs) do e.worldId=e.worldId or 'terrarium' end
 -- S.decode creates independent tables for repeated references. Canonical primary world wins.
 s.habitat=d.worlds[1].habitat;s.food=d.worlds[1].food
 return d.worlds
end
function W.find(s,id) for _,world in ipairs(W.ensure(s)) do if world.id==id then return world end end end
function W.population(s,id) local n=0;for _,o in ipairs(s.organisms) do if o.worldId==id and o.alive then n=n+1 end end;return n end
function W.move(s,id,target,force)
 local world=W.find(s,target);if not world then return false,'Unknown habitat.' end
 local o;for _,v in ipairs(s.organisms) do if v.id==id then o=v end end;if not o or not o.alive then return false,'Select a living organism.' end
 if W.population(s,target)>=world.capacity then return false,'Habitat is at capacity.' end
 local point,breathable=H.location(world.habitat,o.caps,nil,{x=.5,y=.5})
 if not breathable and not force then return false,'This habitat cannot supply enough oxygen for this anatomy.' end
 if not point then return false,'No suitable placement.' end
 o.worldId=target;o.x=point.x;o.y=point.y;o.altitude=0;o.environment=H.sample(world.habitat,o.x,o.y).kind
 return true,'Organism #'..id..' moved to '..world.name..'.'
end
function W.update(s,dt,baseUpdate)
 local worlds=W.ensure(s);local organisms,eggs=s.organisms,s.eggs
 local saved={cells=s.cells,vessels=s.vessels,dishes=s.dishes,gametes=s.gametes}
 local startTime=s.time;local newOrganisms,newEggs={},{}
 for index,w in ipairs(worlds) do
  s.organisms={};s.eggs={};local knownO,knownE={},{}
  for _,o in ipairs(organisms) do if o.worldId==w.id then s.organisms[#s.organisms+1]=o;knownO[o.id]=true end end
  for _,e in ipairs(eggs) do if e.worldId==w.id then s.eggs[#s.eggs+1]=e;knownE[e.id]=true end end
  s.habitat=w.habitat;s.food=w.food;s.seed=w.seed;s.accumulator=w.accumulator;s.time=startTime
  if index>1 then s.cells={};s.vessels={};s.dishes={};s.gametes={} end
  local h=w.habitat;h.waste=(h.waste or 0)+dt*#s.organisms*.00002;h.quality=math.max(.1,1-h.waste);h.humidity=h.humidity or .65
  if w.kind=='freshwater' or w.kind=='saltwater' then for _,c in ipairs(h.cells) do c.salinity=h.salinity;c.oxygen=(h.dissolvedOxygen or .9)*h.quality end end
  s.activeHabitatCapacity=w.capacity;baseUpdate(s,dt,h.environment)
  w.seed=s.seed;w.accumulator=s.accumulator;w.time=s.time;w.food=s.food
  for _,o in ipairs(s.organisms) do if not knownO[o.id] then o.worldId=w.id;newOrganisms[#newOrganisms+1]=o end end
  for _,e in ipairs(s.eggs) do e.worldId=w.id;newEggs[#newEggs+1]=e end
 end
 for _,o in ipairs(newOrganisms) do organisms[#organisms+1]=o end
 s.organisms=organisms;s.eggs=newEggs;s.cells=saved.cells;s.vessels=saved.vessels;s.dishes=saved.dishes;s.gametes=saved.gametes
 s.habitat=worlds[1].habitat;s.food=worlds[1].food;s.seed=worlds[1].seed;s.accumulator=worlds[1].accumulator;s.time=worlds[1].time;s.activeHabitatCapacity=nil
end
return W
