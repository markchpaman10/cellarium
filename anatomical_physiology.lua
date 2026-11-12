local P=require('body_parts');local G=require('genome');local Eco=require('adaptation');local F={}
function F.capabilities(a,g)
 local mass,force,support,heart,lung,digest,brain,exchange,waste,fat,rigidity,health=0,0,0,0,0,0,0,0,0,0,0,0
 local ledger={};local efficiency=0;local regionalMass={};local reproduction=0;local sense=0
 for _,p in ipairs(a.components) do
  mass=mass+p.mass;regionalMass[p.regionId]=(regionalMass[p.regionId] or 0)+p.mass;health=health+p.mass*p.condition;ledger[p.type]=(ledger[p.type] or 0)+p.mass
  if p.type=='Muscle' then force=force+p.mass*p.force*p.efficiency*p.leverage*p.condition;efficiency=efficiency+p.efficiency*p.mass
  elseif p.type=='Bone' or p.type=='Support' or p.type=='Carapace' then support=support+p.strength*p.condition/(1+p.length*.15)
  elseif p.type=='Heart' then heart=heart+p.capacity*p.condition
  elseif p.type=='Lung' then lung=lung+p.capacity*p.condition
  elseif p.type=='Stomach' then digest=digest+p.capacity*p.efficiency*p.condition
  elseif p.type=='Sensor' then sense=sense+(p.acuity or 0)*p.condition*(p.functionalMaturity or 1)
  elseif p.type=='Gonad' then reproduction=reproduction+(p.capacity or 0)*p.condition*(p.functionalMaturity or 1)
  elseif p.type=='Kidney' then waste=waste+(p.wasteCapacity or 0)*p.condition
  elseif p.type=='Brain' then brain=brain+p.capacity*p.efficiency*p.condition
  elseif p.type=='Skin' then exchange=exchange+p.exchange*p.condition;waste=waste+p.wasteCapacity*p.condition;rigidity=rigidity+p.rigidity*p.volume
  elseif p.type=='Fat' then fat=fat+p.capacity*p.condition end
 end
 local control=0;local connected=0;for _,n in ipairs(a.nerves) do control=control+n.efficiency*n.condition;if n.efficiency>0 and a.components[n.to].condition>0 then connected=connected+1 end end;control=control/math.max(1,#a.nerves);control=control*connected/math.max(1,#a.nerves)
 local coordination=control*math.min(1,.3+brain*3);local load=math.min(1,support/math.max(.01,mass*3));local metabolic=.12+mass*.28+force*.15+#a.organs*.01
 local supply=math.min(1,heart/math.max(.1,metabolic), (lung+exchange)/math.max(.1,metabolic));local range=0
 for _,j in ipairs(a.joints) do range=range+j.range*j.mobility*j.condition end;range=range/math.max(1,#a.joints)
 local stride=0;for _,r in ipairs(a.regions) do if r.partType=='segment' then stride=stride+r.length/32 end end;stride=stride/math.max(1,a.appendageCount)
 local modes={contractions=.3};if a.appendageCount>0 and #a.joints>0 then modes.jointed=math.min(1,range) end;if a.axisAspect>2 then modes.undulation=.6 end;if a.symmetry=='radial' then modes.radial=.5 end
 local locomotion='contractions';if modes.jointed then locomotion='jointed' elseif modes.undulation then locomotion='undulation' elseif modes.radial then locomotion='radial' end
 if a.anatomicalVersion==2 then local carried={};for i=#a.regions,1,-1 do local r=a.regions[i];local total=(regionalMass[i] or 0)+(carried[i] or 0);r.carriedMass=total;if r.parent then carried[r.parent]=(carried[r.parent] or 0)+total;local st=a.components[r.structure];local host=a.regions[r.parent];local reach=math.sqrt((r.cx-host.cx)^2+(r.cz-host.cz)^2)/32;r.loadRatio=math.min(1,st.strength*st.condition/math.max(.00001,total*(.7+reach)));if r.partType=='neck' or r.partType=='segment' then load=math.min(load,r.loadRatio) end end end end
 local jointFactor=a.appendageCount>0 and math.min(1,.3+range*.65) or 1
 local speed=jointFactor*math.sqrt(force/math.max(.01,mass))*(.01+stride*.018)*coordination*load/(1+rigidity*4)
 local e=G.express(g);local c={mass=mass,force=force*load*coordination*jointFactor,support=load,circulation=heart,respiration=lung+exchange,lungCapacity=lung,cutaneousExchange=exchange,supply=supply,coordination=coordination,skin=0,fatCapacity=fat,metabolicDemand=metabolic,digestion=digest,perception=sense*.12*coordination,immunity=e.immunity,lifespan=230+e[6]*240,fitness=e.fitness*(a.anatomicalVersion==2 and math.min(1,reproduction/math.max(.01,metabolic*.1)) or 1),stride=stride,wasteHandling=math.min(1,waste/math.max(.01,metabolic)),movementModes=modes,locomotion=locomotion,stability=math.min(load,supply,coordination*2),speed=speed,maxHealth=40+health*25+heart*4,endurance=20*(.2+fat)*(efficiency/math.max(.001,ledger.Muscle or 0))*supply/math.max(.1,metabolic),energyCapacity=100+fat,tolerance=(e[10]+e[18]+e[6])/3,growthRate=.012*health/math.max(.001,mass),mentalCondition=coordination,physicalMass=ledger,organCapacity={heart=heart,lung=lung,digestion=digest,neural=brain}}
 local defense=0;for _,r in ipairs(a.regions) do defense=defense+P.defense(a,r.id,'dorsal')+P.defense(a,r.id,'ventral') end;c.skin=defense/math.max(1,#a.regions*2)
 c=Eco.capabilities(a,g,c);if a.anatomicalVersion==2 then local demand=math.max(.04,c.mass*.12+c.metabolicDemand*.35);c.oxygenDemand=demand;c.supply=math.min(1,c.circulation/demand,c.respiration/demand);c.compatibility.land=math.min(1,c.airRespiration/demand)*c.support;c.compatibility.freshwater=math.min(1,c.aquaticRespiration/demand);c.compatibility.saltwater=c.compatibility.freshwater*(.15+a.ecology.genes[13]*.85) end;return c
end
return F
