-- Adapter from the growth-lab metrics into the existing habitat/lifecycle APIs.
local G=require('genome');local F={}
function F.metrics(a,condition)
 local parts,joints={},{};local mass,health=0,0
 for i,c in ipairs(a.components) do local v={};for k,x in pairs(c) do v[k]=x end;v.volume=c.volume*c.condition;parts[i]=v;mass=mass+c.mass;health=health+c.mass*c.condition end
 for i,j in ipairs(a.joints) do joints[i]={mobility=j.mobility*j.condition,stability=j.stability*j.condition} end
 local view={components=parts,joints=joints};local c=condition or {energy=1,hydration=1,oxygen=1,fatigue=0};c.tissue=c.tissue or health/math.max(.000001,mass)
 return require('physiology').evaluate(view,a.growth or 1,c)
end
function F.capabilities(a,g)
 -- Retain the existing environmental exchange/diet bridge; physical metrics and
 -- locomotion come from the imported growth lab and its anatomical controller.
 local c=require('anatomical_physiology').capabilities(a,g);local m=F.metrics(a);local p=require('locomotion').profile(a,c)
 c.geneticPotential=G.express(g);c.growthLabMetrics=m;c.locomotionProfile=p;c.speed=p.speed;c.landSpeed=p.speed;c.swimSpeed=p.waterSpeed;c.stride=p.stride;c.force=p.force*p.support*p.control;c.coordination=math.min(c.coordination,p.control);c.locomotion=p.mode;c.movementModes={}
 if p.canMove then c.movementModes[p.mode]=p.speed end;if p.waterSpeed>0 then c.movementModes.swimming=p.waterSpeed end
 c.maxHealth=40+c.mass*8+(m.current.Vitality or 0);c.endurance=m.current.Endurance or 0
 if p.force==0 or p.control==0 or not p.canMove then c.flight.powered=false;c.flight.glide=false;c.compatibility.flight=0 end
 return c
end
return F
