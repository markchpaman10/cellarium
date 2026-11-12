local G=require('genome');local C=require('cognition');local S=require('persistence');local I={version=1}
function I.snapshot(o)
 local memory=C.ensure(o);return {version=1,id=o.id,name=o.name,genome=G.copy(o.genome),anatomy=G.copy(o.anatomy),physiology={oxygen=o.oxygen,energy=o.energy,hydration=o.hydration,stamina=o.stamina,vitals=G.copy(o.vitals)},nature=G.copy(o.nature),memories=G.copy(memory.memories),relationships=G.copy(memory.relationships),stats=G.copy(o.stats),age=o.age,maturity=o.maturity,capabilities={fly=o.caps.flight and o.caps.flight.powered or false,vocal=false,language=false,manipulation=false}}
end
function I.validateIntent(o,intent)
 local allowed={observe=true,explore=true,rest=true,seek_food=true,seek_water=true,signal=true,fly=true}
 if type(intent)~='table' or not allowed[intent.action] then return false,'Action is outside the biological interface.' end
 if intent.action=='fly' and (not o.caps.flight or not o.caps.flight.powered or o.energy<40) then return false,'Organism lacks functional flight capability or energy.' end
 if intent.action=='signal' and #o.anatomy.skin==0 then return false,'No implemented signaling structure.' end
 return true
end
-- Export/restore one and the same organism. No desktop/process/file-control capability is provided.
function I.serialize(o) return 'return '..S.encode(o) end
function I.restore(data)
 local f,why=loadstring(data);if not f then return nil,why end;setfenv(f,{});local ok,o=pcall(f);if not ok or type(o)~='table' or not G.valid(o.genome) or not o.anatomy then return nil,'Invalid organism state' end;S.rebind(o.anatomy);o.caps=require('anatomy').capabilities(o.anatomy,o.genome);C.ensure(o);return o
end
return I
