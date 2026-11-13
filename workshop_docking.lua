-- Attachment records reference physical equipment IDs. Docking never transfers,
-- copies, grows or stores a biological sample inside the workshop.
local M=require('desktop_model');local T=require('desktop_samples');local V=require('vessels');local D={}
function D.station(s,id)
 local o=M.find(s,id);if not o or o.kind~='workstation' then return nil end
 o.config=o.config or {};o.config.docks=o.config.docks or {};return o
end
function D.dna(s,stationId)
 local station=D.station(s,stationId);if not station then return nil end
 local object=M.find(s,station.config.docks.dna);if not object or object.kind~='dna' or object.archivedEntity then return nil,object end
 for _,record in ipairs(s.materials) do if record.id==object.entityId then return record,object end end
 return nil,object
end
function D.container(s,stationId,slot)
 if slot=='dna' then return D.dna(s,stationId) end
 local station=D.station(s,stationId);if not station then return nil end
 local object=M.find(s,station.config.docks[slot]);if not object or object.archivedEntity then return nil end
 return T.vessel(s,object.entityId),object
end
function D.detach(s,objectId)
 local object=M.find(s,objectId);if not object or not object.config then return false end
 local station=D.station(s,object.config.workshop)
 if station then for _,slot in ipairs({'input','output','dna'}) do if station.config.docks[slot]==object.id then station.config.docks[slot]=nil end end end
 object.config.workshop=nil;object.config.dockSlot=nil;return true
end
function D.attach(s,stationId,objectId,slot)
 local station=D.station(s,stationId);local object=M.find(s,objectId)
 if not station or not object or object.archivedEntity or object.stored then return false,'Workshop or container unavailable.' end
 if slot~='input' and slot~='output' and slot~='dna' then return false,'Unknown workshop docking slot.' end
 local vessel
 if slot=='dna' then
  if object.kind~='dna' then return false,'Attach an archived DNA vial to the purple DNA dock.' end
  for _,record in ipairs(s.materials) do if record.id==object.entityId and require('genome').valid(record.genome) then vessel=record;break end end
  if not vessel then return false,'This DNA vial has no valid genome record.' end
 else
  if object.kind=='dna' then return false,'Use the purple DNA dock for DNA. INPUT takes the blank cell.' end
  vessel=T.vessel(s,object.entityId);if not vessel then return false,'Attach a physical cell container.' end
 end
 local occupied=station.config.docks[slot]
 if occupied and occupied~=objectId and M.find(s,occupied) then return false,'That docking slot is occupied.' end
 if slot=='input' and V.count(vessel)<1 then return false,'The input container must contain a sample.' end
 if slot=='output' and V.count(vessel)~=0 then return false,'Attach an empty output container.' end
 if object.config.workshop and (object.config.workshop~=stationId or object.config.dockSlot~=slot) then return false,'Detach this container from its current slot first.' end
 object.config.rack=nil;object.config.slot=nil;station.config.docks[slot]=objectId;object.config.workshop=stationId;object.config.dockSlot=slot
 if slot=='dna' then station.config.genomeId=vessel.id;return true,'DNA vial attached. Put a blank cell at INPUT and an empty container at OUTPUT.' end
 return true,slot=='input' and 'Input container attached.' or 'Empty output container attached.'
end
function D.validatePair(s,stationId)
 local input,source=D.container(s,stationId,'input');local output,destination=D.container(s,stationId,'output')
 if not input then return nil,nil,'Attach an input container containing a sample.' end
 if not output then return nil,nil,'Attach an empty output container.' end
 if source.id==destination.id or input.id==output.id then return nil,nil,'Input and output must be separate containers.' end
 if input.frozen or input.closed then return nil,nil,'Open and thaw the input container before processing.' end
 if output.frozen or output.closed then return nil,nil,'Open and thaw the output container before processing.' end
 if V.count(input)<1 then return nil,nil,'The attached input container is empty.' end
 if V.count(output)~=0 then return nil,nil,'The attached output container must be empty.' end
 return input,output
end
function D.slotRects(o)
 if not o.config.expanded then return {} end
 return {input={x=16,y=110,w=244,h=340},output={x=790,y=110,w=244,h=340},dna={x=630,y=86,w=138,h=225}}
end
function D.layout(s,station,monitors)
 local factor=station.scale*M.monitorAt(monitors,station.x,station.y).dpi/96
 for slot,r in pairs(D.slotRects(station)) do local _,object=D.container(s,station.id,slot);if object then
  local w,h=M.dimensions(object,M.monitorAt(monitors,station.x,station.y));object.x=math.floor(station.x+(r.x+r.w/2)*factor-w/2);object.y=math.floor(station.y+(r.y+(slot=='dna' and (32+(r.h-32)/2) or 40+(r.h-60)/2))*factor-h/2);object.layer=math.max(object.layer,station.layer+1);M.remember(object,monitors)
 end end
end
function D.drop(s,object,cursor,monitors)
 local ordered=require('desktop_depth').ordered(s);for i=#ordered,1,-1 do local station=ordered[i];if station.kind=='workstation' and M.isVisible(s.desktop,station) then
  local x,y=M.localPoint(station,M.monitorAt(monitors,station.x,station.y),cursor.x,cursor.y)
  if object.kind=='dna' and x>=0 and y>=0 and x<station.w and y<station.h then
   local ok,why=D.attach(s,station.id,object.id,'dna');if ok then require('desktop_controls').expand(s,station);require('desktop_controls').collapse(s,object);D.layout(s,station,monitors) end;return true,ok,why
  end
  for slot,r in pairs(D.slotRects(station)) do if x>=r.x and y>=r.y and x<r.x+r.w and y<r.y+r.h then
   local ok,why=D.attach(s,station.id,object.id,slot);if ok then require('desktop_controls').collapse(s,object);D.layout(s,station,monitors) end;return true,ok,why
  end end
 end end;return false
end
return D
