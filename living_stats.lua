local T={}
local function avg(parts,key) local n=0;for _,p in ipairs(parts or {}) do n=n+(p[key] or 0)*p.condition end;return n/math.max(1,#(parts or {})) end
function T.calculate(o)
 local a,c=o.anatomy,o.caps;local growth=.35+.65*(o.maturity or 0);local energy=math.max(.05,(o.energy or 0)/100);local stamina=math.max(.05,(o.stamina or 0)/100);local oxygen=o.oxygen or 1
 local muscle=avg(a.muscles,'efficiency');local neural=0;for _,p in ipairs(a.organs) do if p.type=='Brain' then neural=neural+p.capacity*p.efficiency*p.condition end end
 local condition=0;for _,p in ipairs(a.components) do condition=condition+p.condition end;condition=condition/math.max(1,#a.components)
 local armor,area=0,0;for _,p in ipairs(a.skin) do local coverage=math.max(.1,(p.rx or 4)*(p.ry or 4));armor=armor+(p.armor or p.toughness or 0)*coverage*p.condition;area=area+coverage end
 if a.anatomicalVersion then armor=c.skin;area=1 end
 local joints=0;for _,j in ipairs(a.joints) do joints=joints+j.mobility*j.condition end;joints=joints/math.max(1,#a.joints)
 return {STR=c.force*growth*math.sqrt(energy*stamina),DEF=(armor/math.max(1,area)+c.support*.25)*growth,DEX=c.coordination*(.35+joints*.65)*(.5+muscle*.5)*growth*math.sqrt(stamina),INT=neural*c.coordination*growth*(1-(o.sickness or 0))*.5,VIT=math.sqrt(math.max(0,c.supply*oxygen))*condition*(.5+c.immunity*.5),END=c.endurance*energy*stamina*oxygen*.02}
end
function T.updateVitals(o,dt)
 local hearts=0;local pump=0;for _,p in ipairs(o.anatomy.organs) do if p.type=='Heart' then hearts=hearts+1;pump=pump+p.capacity*p.condition end end
 o.vitals=o.vitals or {bloodVolume=hearts>0 and o.caps.mass*.07 or nil,bleeding=0};local v=o.vitals;v.oxygenation=o.oxygen or 1;v.circulation=o.caps.circulation;v.nutrientTransport=o.caps.supply*o.energy/100;v.cardiac=hearts>0
 if hearts>0 then v.maximumBloodVolume=o.caps.mass*.07;v.bloodVolume=math.max(0,math.min(v.maximumBloodVolume,(v.bloodVolume or v.maximumBloodVolume)-(v.bleeding or 0)*dt));local volume=v.bloodVolume/math.max(.001,v.maximumBloodVolume);v.pressure=volume*math.min(1,pump/math.max(.1,o.caps.mass*.15));v.heartRate=40+o.caps.metabolicDemand*20+(100-o.stamina)*.3;v.transport=volume*math.min(1,v.pressure);o.oxygen=math.max(0,(o.oxygen or 1)-dt*(1-v.transport)*.08)
  if volume<.15 then o.alive=false;o.deathCause='Transport failure after blood loss';o.behavior='Deceased' end
 else v.heartRate=nil;v.pressure=nil;v.transport=o.caps.supply;v.mode='Diffusion / distributed exchange' end
 o.stats=T.calculate(o)
end
return T
