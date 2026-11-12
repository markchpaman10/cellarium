local G=require('genome');local Nav=require('navigation');local H=require('habitat');local A=require('anatomy');local Cog=require('cognition');local Stats=require('living_stats');local P={}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
function P.new(id,g,parents,gen,x,y,angle,anatomy)
 local a=anatomy or A.generate(g);local o={id=id,name='Organism '..id,genome=G.copy(g),anatomy=a,traits=G.express(g),caps=a.caps,x=x,y=y,angle=angle,phase=id*.7,energy=90,health=100,stamina=100,hydration=100,sickness=0,age=0,maturity=0,bodyCondition=.4,mentalCondition=1,generation=gen or 0,parents=parents or 'Laboratory',parentIds={},ancestry={},children={},breed=0,alive=true,behavior='Juvenile',deathCause=nil,altitude=0,oxygen=1,transitions=0,corpse=0,inbreeding=0}
 o.fatMass=a.caps.fatCapacity*.04;o.muscleMass=0;for _,m in ipairs(a.muscles) do o.muscleMass=o.muscleMass+m.mass end;return o
end
function P.update(o,s,dt,env)
 if not o.alive then o.corpse=o.corpse+dt;return end
 H.ensure(s);o.altitude=o.altitude or 0;o.oxygen=o.oxygen or 1;local e=o.traits;o.caps=A.capabilities(o.anatomy,o.genome);local c=o.caps;o.locomotion=c.locomotion or 'jointed';o.age=o.age+dt;o.breed=o.breed+dt
 if o.energy>25 then o.maturity=math.min(1,o.maturity+dt*c.growthRate);o.bodyCondition=.4+.6*o.maturity end
 o.lifeStage=o.age>c.lifespan*.8 and 'Elderly' or o.maturity<1 and 'Juvenile' or 'Mature'
 local localEnv=H.sample(s.habitat,o.x,o.y,o.altitude);local inWater=localEnv.kind=='freshwater' or localEnv.kind=='saltwater';o.environment=localEnv.kind
 if o.previousEnvironment and o.previousEnvironment~=o.environment then o.transitions=(o.transitions or 0)+1 end;o.previousEnvironment=o.environment
 local moisture=inWater and localEnv.kind=='freshwater' and 1.1 or -( .06+c.mass*.003)*(1-c.moistureRetention*.8)*(1.3-(s.habitat.humidity or .65)*.6);o.hydration=clamp(o.hydration+dt*moisture,0,100)
 local breathing=inWater and c.aquaticRespiration*(localEnv.oxygen or .85)*(.6+(o.stamina/100)*.4) or c.airRespiration*(localEnv.oxygen or 1);local ratio=breathing/math.max(.1,c.oxygenDemand*(o.maturity<1 and 1.1 or 1));o.oxygen=clamp(o.oxygen+dt*(math.min(1.2,ratio)-1)*.16,0,1)
 local food,dist=nil,99;for i,f in ipairs(s.food) do local d=(o.x-f.x)^2+(o.y-f.y)^2;local diet=c.diet[f.kind or 'debris'] or 0;local where=H.sample(s.habitat,f.x,f.y);local blocked=o.blockedFood and s.time<o.blockedFood.untilTime and f.x==o.blockedFood.x and f.y==o.blockedFood.y;if not blocked and diet>.1 and d<dist and H.oxygenRatio(c,where)>.92 then dist=d;food=i end end
 Cog.update(o,s,dt)
 local moving=true;local danger=nil
 for _,other in ipairs(s.organisms) do if other~=o and other.alive and other.traits[8]>.72 and (other.x-o.x)^2+(other.y-o.y)^2<.005 then danger=other;break end end
 local function seekCompatible(waterOnly)
  local best,bd
  for index,cell in ipairs(s.habitat.cells) do if (not waterOnly or cell.kind=='freshwater') and H.oxygenRatio(c,cell)>1.03 then local x=((index-1)%H.width+.5)/H.width;local y=(math.floor((index-1)/H.width)+.5)/H.height;local d=(x-o.x)^2+(y-o.y)^2;if not bd or d<bd then best={x=x,y=y};bd=d end end end
  return best,bd
 end
 if o.oxygen<.7 or (inWater and localEnv.salinity>c.salinityTolerance+.25) then local target=seekCompatible(false);if target then o.angle=Nav.heading(s,o,target.x,target.y) or (o.angle+.7) end;o.behavior='Seeking breathable habitat'
 elseif o.hydration<40 then local target,d=seekCompatible(true);if target then o.angle=Nav.heading(s,o,target.x,target.y) or (o.angle+.7);o.behavior='Seeking water';if d<.001 then o.hydration=clamp(o.hydration+dt*12,0,100);o.behavior='Drinking';moving=false end end
 elseif danger and e[8]<.4 then o.angle=math.atan2(o.y-danger.y,o.x-danger.x);o.behavior='Avoiding danger'
 elseif o.stamina<25 or (o.energy<20 and not food) then moving=false;o.behavior='Resting'
 elseif food and dist<c.perception^2 and o.energy<92 then local f=s.food[food];local heading=Nav.heading(s,o,f.x,f.y);if heading then o.angle=heading else o.blockedFood={x=f.x,y=f.y,untilTime=s.time+30};o.angle=o.angle+.7 end;o.behavior='Foraging'
 elseif o.breed>45 and o.maturity>=1 and o.energy>65 then
  local nearest,nd;for _,p in ipairs(s.organisms) do if p~=o and p.alive and p.maturity>=1 and p.energy>55 and p.caps.fitness>.1 and H.oxygenRatio(c,H.sample(s.habitat,p.x,p.y))>.9 then local d=(p.x-o.x)^2+(p.y-o.y)^2;if not nd or d<nd then nearest=p;nd=d end end end
  if nearest then o.angle=Nav.heading(s,o,nearest.x,nearest.y) or (o.angle+.7);o.behavior='Seeking mate' else o.behavior='Exploring';o.angle=o.angle+math.sin(s.time*.5+o.phase)*dt end
 else local intent=Cog.intent(o,s);o.behavior=intent.activity;if intent.x then o.angle=Nav.heading(s,o,intent.x,intent.y) or o.angle elseif intent.angle then o.angle=intent.angle else o.angle=o.angle+(intent.turn or 0)*dt end end
 local condition=math.min(o.health/100,o.stamina/100+.3,o.energy/100+.4);local targetAltitude=0;if o.energy>65 and o.stamina>45 and o.oxygen>.8 and c.airRespiration/c.oxygenDemand>.95 and c.flight.powered then targetAltitude=.35 elseif c.flight.glide and (localEnv.elevation or 0)>.42 and o.energy>60 then targetAltitude=.15 end
 if targetAltitude>o.altitude then o.altitude=math.min(targetAltitude,o.altitude+dt*.035) else o.altitude=math.max(0,o.altitude-dt*(c.flight.glide and .008 or .09)) end
 o.locomotion=o.altitude>.08 and (c.flight.powered and 'powered flight' or 'gliding') or inWater and 'swimming' or c.locomotion or 'jointed'
 local speed=(o.altitude>.08 and (c.landSpeed+.018)*(c.flight.glide and 1.2 or 1) or inWater and c.swimSpeed or c.landSpeed)*condition*(.45+o.maturity*.55)*(.35+o.oxygen*.65)
 local nextX=o.x+math.cos(o.angle)*speed*dt;local nextY=o.y+math.sin(o.angle)*speed*dt;local nextEnv=H.sample(s.habitat,nextX,nextY,o.altitude);if nextEnv.obstacle or (H.oxygenRatio(c,nextEnv)<.85 and H.oxygenRatio(c,localEnv)>.95 and e.perception>.25) then o.angle=o.angle+2;moving=false end
 if moving then o.x=clamp(o.x+math.cos(o.angle)*speed*dt,.06,.94);o.y=clamp(o.y+math.sin(o.angle)*speed*dt,.09,.91);o.stamina=clamp(o.stamina+dt*(c.supply*1.4-.65-c.force*.02),0,100) else o.stamina=clamp(o.stamina+dt*(2+c.supply*3),0,100) end
 if o.x<=.061 or o.x>=.939 or o.y<=.091 or o.y>=.909 then o.angle=o.angle+2 end
 if food and dist<.0017 and o.energy<98 and o.altitude<.08 then local meal=table.remove(s.food,food);o.energy=math.min(100,o.energy+(20+c.digestion*6)*(c.diet[meal.kind or 'debris'] or .5));o.fatMass=math.min(c.fatCapacity*.1,o.fatMass+.02);Cog.remember(o,{kind='food',x=meal.x,y=meal.y,outcome=1},s.time) end
 local drain=c.metabolicDemand*(moving and 1 or .6)*(o.altitude>.08 and (c.flight.powered and 1.9 or 1.12) or 1);o.energy=o.energy-dt*drain
 if o.energy<20 and o.fatMass>0 then local transfer=math.min(o.fatMass,dt*.025);o.fatMass=o.fatMass-transfer;o.energy=o.energy+transfer*35 end;o.energy=math.max(0,o.energy)
 local tempStress=math.max(0,math.abs((s.habitat.temperature or 22)-22)-c.temperatureTolerance)*.025;local saltStress=inWater and math.max(0,localEnv.salinity-c.salinityTolerance)*.25*(1-c.waterResistance*.4) or 0;local oxygenStress=(1-o.oxygen)*.8
 if o.oxygen<.2 then A.damage(o.anatomy,'Muscle',dt*.0005) end
 if env==2 then o.sickness=clamp(o.sickness+dt*(.04*(1-c.immunity)-c.immunity*.015),0,1) else o.sickness=clamp(o.sickness-dt*(.01+c.immunity*.02),0,1) end
 local loss=(o.energy<=0 and 1.1 or 0)+(o.hydration<=0 and 1.4 or 0)+math.max(0,.45-c.supply)*.8+tempStress+saltStress+oxygenStress+o.sickness*.35+(o.age>c.lifespan and .8 or 0)
 o.health=clamp(o.health+dt*100/c.maxHealth*((o.energy>35 and o.hydration>25 and .08+e[6]*.13 or 0)-loss),0,100)
 if c.support<.4 and moving then A.damage(o.anatomy,'limb',dt*.0008) end
 if o.sickness>.5 then A.damage(o.anatomy,'Lung',dt*.0006*o.sickness) end
 if o.energy>40 then for _,part in ipairs(o.anatomy.components) do part.condition=math.min(1,part.condition+dt*(part.regeneration and part.regeneration*.01 or .0006*(.4+e[6]))) end;for _,j in ipairs(o.anatomy.joints) do j.condition=math.min(1,j.condition+dt*.0004) end end
 o.mentalCondition=c.mentalCondition*(1-o.sickness)*o.stamina/100;o.hunger=1-o.energy/100;o.thirst=1-o.hydration/100
 o.maxHealth=c.maxHealth;o.currentHealth=c.maxHealth*o.health/100;o.metabolicDemand=c.metabolicDemand;o.fertility=c.fitness*(o.lifeStage=='Elderly' and .25 or 1);o.environmentalTolerance=c.tolerance;Stats.updateVitals(o,dt)
 if o.health<=0 or c.circulation<.1 or c.respiration<.1 then o.alive=false;o.lifeStage='Deceased';o.behavior='Deceased';o.deathCause=o.oxygen<.25 and 'Oxygen deficiency ('..o.environment..')' or saltStress>.1 and 'Salinity exposure' or tempStress>.1 and 'Temperature exposure' or o.hydration<=0 and 'Dehydration' or o.energy<=0 and 'Starvation' or o.age>c.lifespan and 'Aging' or o.sickness>.7 and 'Disease' or c.supply<.2 and 'Organ failure' or 'Environmental exposure' end
end
return P
