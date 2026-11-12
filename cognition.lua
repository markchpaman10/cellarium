local G=require('genome');local C={}
local function clamp(v) return math.max(0,math.min(1,v)) end
function C.capabilities(o)
 local brains,network=0,0;for _,p in ipairs(o.anatomy.organs) do if p.type=='Brain' then brains=brains+p.capacity*p.efficiency*p.condition end end
 for _,n in ipairs(o.anatomy.nerves) do network=network+n.efficiency*n.condition end;network=network/math.max(1,#o.anatomy.nerves)
 local development=.2+.8*(o.maturity or 0);local processing=brains*network*development;local capacity=math.min(32,math.floor(processing*2))
 return {processing=processing,capacity=capacity,learning=clamp(processing/8),recognition=capacity>=6,planning=capacity>=10 and network>.3,communicationLearning=capacity>=12}
end
function C.ensure(o)
 o.cognition=o.cognition or {memories={},relationships={},events={},stress=0,lastSocial=-100,lastSignal=-100,habituation=0};return o.cognition
end
function C.nature(o)
 local e=G.express(o.genome);local capability=C.capabilities(o);local flexibility=capability.learning
 return {sociability=clamp((1-e[8])*.65+flexibility*.35),aggression=clamp(e[8]*.65+e[1]*.35),fearfulness=clamp(1-e[5]*.4-e.perception*.4),curiosity=clamp(e[4]*.4+flexibility*.4+e.development[3]*.2),territoriality=clamp(e[8]*.5+e[24]*.5),dominance=clamp(e[8]*.5+e[11]*.5),tolerance=clamp((1-e[8])*.5+o.caps.coordination*.5),attachment=clamp((1-e[8])*.5+flexibility*.5),exploration=clamp(e[4]*.5+e[9]*.3+flexibility*.2),flexibility=flexibility,stressSensitivity=clamp(1-o.caps.immunity*.6-o.caps.coordination*.4),socialLearning=flexibility*(1-e[8])}
end
function C.remember(o,event,time)
 local c=C.ensure(o);local cap=C.capabilities(o);if cap.capacity<1 or event.perceived==false then return false end
 local key=event.kind..'/'..tostring(event.subject or '')..'/'..math.floor((event.x or o.x)*16)..'/'..math.floor((event.y or o.y)*16)
 for _,m in ipairs(c.memories) do if m.key==key then m.strength=math.min(1,m.strength+.15*cap.learning);m.last=time;m.outcome=event.outcome;m.reinforcements=(m.reinforcements or 1)+1;return true end end
 local memory={key=key,kind=event.kind,subject=cap.recognition and event.subject or nil,x=event.x or o.x,y=event.y or o.y,outcome=event.outcome or 0,strength=.25+cap.learning*.4,created=time,last=time,perceived=true};c.memories[#c.memories+1]=memory
 if #c.memories>cap.capacity then local weakest=1;for i,m in ipairs(c.memories) do if m.strength<c.memories[weakest].strength then weakest=i end end;table.remove(c.memories,weakest) end;return true
end
function C.communication(o,intent,recipient,time)
 local c=C.ensure(o);if time-c.lastSignal<8 then return nil end
 local movement=(o.caps.speed or 0)>0;local sensorCount=0;for _,p in ipairs(o.anatomy.sensors or {}) do if p.condition>.2 then sensorCount=sensorCount+1 end end
 local mechanism=movement and 'posture' or (#o.anatomy.skin>0 and sensorCount>0 and 'chemical' or nil);if not mechanism then return nil end
 local event={organismId=o.id,recipient=recipient,intent=intent,mechanism=mechanism,time=time,stress=c.stress,capabilities={vocal=false,language=false,recognition=C.capabilities(o).recognition},memoryContext=#c.memories};c.events[#c.events+1]=event;if #c.events>32 then table.remove(c.events,1) end;c.lastSignal=time;return event
end
function C.update(o,s,dt)
 local c=C.ensure(o);local cap=C.capabilities(o);local nature=C.nature(o);o.nature=nature;o.cognitiveCapabilities=cap
 c.stress=clamp(c.stress+dt*((1-(o.oxygen or 1))*.04+(100-o.health)*.0004-nature.flexibility*.01))
 for i=#c.memories,1,-1 do local m=c.memories[i];m.strength=m.strength-dt*(.0008+(1-cap.learning)*.0015);if m.strength<=.03 then table.remove(c.memories,i) end end
 while #c.memories>cap.capacity do table.remove(c.memories,1) end
 if (o.oxygen or 1)<.6 and s.time-(c.lastStress or -100)>6 then C.remember(o,{kind='unsafe habitat',outcome=-1,perceived=true},s.time);c.lastStress=s.time end
 if cap.capacity==0 then c.relationships={};return end
 if s.time-c.lastSocial>=3 then
  c.lastSocial=s.time;local seen=0
  for _,other in ipairs(s.organisms) do if other~=o and other.alive and (other.x-o.x)^2+(other.y-o.y)^2<math.min(.08,o.caps.perception)^2 then seen=seen+1;local stressed=o.health<35 or c.stress>.7
   local outcome=stressed and -.2 or (.02+nature.tolerance*.08);C.remember(o,{kind='social encounter',subject=other.id,outcome=outcome,perceived=true},s.time)
   if cap.recognition then local key=tostring(other.id);local relationship=c.relationships[key] or {subject=other.id,familiarity=0,trust=0,fear=0,encounters=0};relationship.encounters=relationship.encounters+1;relationship.familiarity=clamp(relationship.familiarity+.025*cap.learning);relationship.trust=math.max(-1,math.min(1,relationship.trust+outcome*cap.learning));relationship.fear=clamp(relationship.fear+(stressed and .05 or -.01));relationship.lastSeen=s.time;c.relationships[key]=relationship end
   C.communication(o,stressed and 'retreat' or nature.aggression>.7 and nature.tolerance<.3 and 'threat display' or 'investigate',cap.recognition and other.id or nil,s.time)
   if seen>=3 then break end
  end end
 end
end
function C.intent(o,s)
 local c=C.ensure(o);local nature=o.nature or C.nature(o)
 -- Physiology has priority: this function only influences otherwise-idle behavior.
 if o.health<35 or c.stress>.75 then
  for _,other in ipairs(s.organisms) do if other~=o and other.alive and (other.x-o.x)^2+(other.y-o.y)^2<o.caps.perception^2 then return {activity='Retreating',angle=math.atan2(o.y-other.y,o.x-other.x),cause='Injury or remembered stress'} end end
 end
 if o.energy<70 then local best;for _,m in ipairs(c.memories) do if m.kind=='food' and m.outcome>0 and m.strength>.2 and (not best or m.strength>best.strength) and (m.x-o.x)^2+(m.y-o.y)^2>.001 then best=m end end;if best then return {activity='Revisiting food site',x=best.x,y=best.y,cause='Remembered positive feeding outcome'} end end
 if nature.sociability>.55 and c.stress<.5 then for _,other in ipairs(s.organisms) do if other~=o and other.alive and (other.x-o.x)^2+(other.y-o.y)^2<o.caps.perception^2 then local relationship=c.relationships[tostring(other.id)];if not relationship or relationship.fear<.3 then return {activity=relationship and relationship.familiarity>.2 and 'Following familiar neighbor' or 'Investigating neighbor',x=other.x,y=other.y,cause='Inherited sociability and perceived neighbor'} end end end end
 return {activity='Exploring',turn=(.4+nature.exploration)*math.sin(s.time*.4+o.phase),cause='Curiosity and available energy'}
end
return C
