-- Inspect clones through the actual simulation APIs. Never advance time or edit a specimen.
local G=require('genome');local D={}
function D.organism(s,o)
 if not o or not o.anatomy or o.anatomy.anatomicalVersion~=2 then return {available=false,reason='This saved anatomy does not support the current detailed controller audit.'} end
 for _,field in ipairs({'health','energy','stamina','oxygen'}) do if type(o[field])~='number' then return {available=false,reason='The record is missing '..field..'; a diagnosis would require invented data.'} end end
 local view=G.copy(o);view.anatomy=require('persistence').rebind(view.anatomy);view.caps=require('anatomy').capabilities(view.anatomy,view.genome);view.anatomy.caps=view.caps;view.traits=G.express(view.genome);view.altitude=view.altitude or 0;view.motion=view.motion or {phase=0,distance=0,fatigue=0}
 local habitat=s.habitat;for _,world in ipairs(s.desktop and s.desktop.worlds or {}) do if world.id==o.worldId then habitat=world.habitat;break end end
 local env=require('habitat').sample(habitat,view.x,view.y,view.altitude);local water=env.kind=='freshwater' or env.kind=='saltwater'
 local condition={health=view.health/100,energy=view.energy/100,oxygen=view.oxygen,fatigue=view.motion.fatigue or 0,medium=water and 'water' or 'land'}
 local report=require('locomotion').diagnose(view.anatomy,view.caps,condition);report.available=true;report.id=o.id;report.condition=condition;report.behavior=o.behavior;report.environment=env.kind;report.speedInchesPerSecond=require('organism_lifecycle').movementSpeed(view,view.caps,water)*require('locomotion').worldInches;report.alive=o.alive;report.fresh=true;report.massOunces=report.profile.mass
 report.navigation={tested=false,reason='No current navigation target is recorded.'}
 local path=o.navigation and o.navigation.path;local target=path and path[#path]
 if type(target)=='table' and type(target.x)=='number' and type(target.y)=='number' then
  view.navigation=nil;local heading=require('navigation').heading({habitat=habitat,time=s.time or 0},view,target.x,target.y)
  report.navigation={tested=true,reachable=heading~=nil,targetX=target.x,targetY=target.y,reason=heading and 'The actual navigation solver found a route to the recorded target.' or 'The actual navigation solver found no safe route to the recorded target.'}
 end
 report.statedIdle=o.behavior=='Resting' or o.behavior=='Drinking'
 return report
end
function D.genome(g,conditions)
 if not G.valid(g) then return {available=false,reason='The selected record has no valid canonical genome.'} end
 local copy=G.copy(g);local c=G.copy(conditions or {nutrition=1,oxygen=1,temperature=37});local a=require('anatomy').generate(copy,c);local loci,altered,deleted=0,0,0
 for _,ch in ipairs(copy.chromosomes) do for _,l in ipairs(ch.loci) do loci=loci+1;if (l.copies or 1)~=1 then altered=altered+1 end;if l.deleted or (l.copies or 1)==0 then deleted=deleted+1 end end end
 return {available=true,hash=G.hash(copy),chromosomePairs=#copy.chromosomes,loci=loci,alteredDosage=altered,deleted=deleted,regulationRules=#(copy.regulation or {}),expression=G.express(copy),forecast={viable=a.viable,failures=G.copy(a.failures or {}),heads=a.headCount,appendages=a.appendageCount,symmetry=a.symmetry,support=a.supportStrategy,locomotion=a.caps.locomotion,massOunces=a.caps.mass},conditions=c}
end
return D
