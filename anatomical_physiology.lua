local P=require('body_parts');local G=require('genome');local Eco=require('adaptation');local F={}
function F.capabilities(a,g)
 local mass,force,support,heart,lung,digest,brain,exchange,waste,fat,rigidity,health=0,0,0,0,0,0,0,0,0,0,0,0
 local ledger={};local efficiency=0
 for _,p in ipairs(a.components) do
  mass=mass+p.mass;health=health+p.mass*p.condition;ledger[p.type]=(ledger[p.type] or 0)+p.mass
  if p.type=='Muscle' then force=force+p.mass*p.force*p.efficiency*p.leverage*p.condition;efficiency=efficiency+p.efficiency*p.mass
  elseif p.type=='Bone' or p.type=='Support' or p.type=='Carapace' then support=support+p.strength*p.condition/(1+p.length*.15)
  elseif p.type=='Heart' then heart=heart+p.capacity*p.condition
  elseif p.type=='Lung' then lung=lung+p.capacity*p.condition
  elseif p.type=='Stomach' then digest=digest+p.capacity*p.efficiency*p.condition
  elseif p.type=='Brain' then brain=brain+p.capacity*p.efficiency*p.condition
  elseif p.type=='Skin' then exchange=exchange+p.exchange*p.condition;waste=waste+p.wasteCapacity*p.condition;rigidity=rigidity+p.rigidity*p.volume
  elseif p.type=='Fat' then fat=fat+p.capacity*p.condition end
 end
 local control=0;for _,n in ipairs(a.nerves) do control=control+n.efficiency*n.condition end;control=control/math.max(1,#a.nerves)
 local coordination=control*math.min(1,.3+brain*3);local load=math.min(1,support/math.max(.01,mass*3));local metabolic=.12+mass*.28+force*.15+#a.organs*.01
 local supply=math.min(1,heart/math.max(.1,metabolic), (lung+exchange)/math.max(.1,metabolic));local range=0
 for _,j in ipairs(a.joints) do range=range+j.range*j.mobility*j.condition end;range=range/math.max(1,#a.joints)
 local stride=0;for _,r in ipairs(a.regions) do if r.partType=='segment' then stride=stride+r.length/32 end end;stride=stride/math.max(1,a.appendageCount)
 local modes={contractions=.3};if a.appendageCount>0 and #a.joints>0 then modes.jointed=math.min(1,range) end;if a.axisAspect>2 then modes.undulation=.6 end;if a.symmetry=='radial' then modes.radial=.5 end
 local locomotion='contractions';if modes.jointed then locomotion='jointed' elseif modes.undulation then locomotion='undulation' elseif modes.radial then locomotion='radial' end
 local speed=math.sqrt(force/math.max(.01,mass))*(.01+stride*.018)*coordination*load/(1+rigidity*4)
 local e=G.express(g);local c={mass=mass,force=force*load*coordination,support=load,circulation=heart,respiration=lung+exchange,lungCapacity=lung,cutaneousExchange=exchange,supply=supply,coordination=coordination,skin=0,fatCapacity=fat,metabolicDemand=metabolic,digestion=digest,perception=#a.sensors*.08*coordination,immunity=e.immunity,lifespan=230+e[6]*240,fitness=e.fitness,stride=stride,wasteHandling=math.min(1,waste/math.max(.01,metabolic)),movementModes=modes,locomotion=locomotion,stability=math.min(load,supply,coordination*2),speed=speed,maxHealth=40+health*25+heart*4,endurance=20*(.2+fat)*(efficiency/math.max(.001,ledger.Muscle or 0))*supply/math.max(.1,metabolic),energyCapacity=100+fat,tolerance=(e[10]+e[18]+e[6])/3,growthRate=.012*health/math.max(.001,mass),mentalCondition=coordination,physicalMass=ledger,organCapacity={heart=heart,lung=lung,digestion=digest,neural=brain}}
 local defense=0;for _,r in ipairs(a.regions) do defense=defense+P.defense(a,r.id,'dorsal')+P.defense(a,r.id,'ventral') end;c.skin=defense/math.max(1,#a.regions*2)
 return Eco.capabilities(a,g,c)
end
return F
