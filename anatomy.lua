local G=require('genome');local Eco=require('adaptation');local F=require('growth');local Legacy=require('anatomy_legacy');local certificate=require('generator_certificate');local A={legacy=Legacy}
function A.capabilities(a,g)
 if a.anatomicalVersion==1 then return require('anatomical_physiology_v1').capabilities(a,g) end
 if a.anatomicalVersion then return require('anatomical_physiology').capabilities(a,g) end
 if a.version~=3 then return Eco.capabilities(a,g,Legacy.capabilities(a,g)) end
 local e=G.express(g);local d=a.parameters;local mass,rawForce,support,skin,fat,exchange,waste=0,0,0,0,0,0,0;local heart,lungs,digest,neural=0,0,0,0;local brainCount=0;local activeMuscles=0
 for _,c in ipairs(a.components) do
  mass=mass+c.mass
  if c.type=='Bone' or c.type=='Support' or c.type=='Carapace' then support=support+c.strength*c.condition*(.7+c.flexibility*.3)
  elseif c.type=='Muscle' then rawForce=rawForce+c.mass*c.force*c.condition*c.efficiency;activeMuscles=activeMuscles+c.condition
  elseif c.type=='Skin' then skin=skin+c.toughness*c.condition;exchange=exchange+(c.exchange or 0)*c.condition;waste=waste+(c.wasteCapacity or 0)*c.condition
  elseif c.type=='Fat' then fat=fat+c.capacity*c.condition
  elseif c.type=='Heart' then heart=heart+c.capacity*c.condition
  elseif c.type=='Lung' then lungs=lungs+c.capacity*c.condition
  elseif c.type=='Stomach' then digest=digest+c.capacity*c.efficiency*c.condition;waste=waste+(c.wasteCapacity or 0)*c.condition
  elseif c.type=='Brain' then neural=neural+c.efficiency*c.condition;brainCount=brainCount+1 end
 end
 neural=neural/math.max(1,brainCount)
 local nerve=0;for _,n in ipairs(a.nerves) do nerve=nerve+n.efficiency*n.condition end;nerve=nerve/math.max(1,#a.regions)
 local vascular=0;for _,v in ipairs(a.vessels) do vascular=vascular+v.condition end;vascular=vascular/math.max(1,#a.regions)
 local coordination=nerve*neural;local tissueSupport=math.min(1,support/math.max(1,mass*.9))
 local metabolic=.18+mass*.025+rawForce*.016+e[1]*.1;metabolic=metabolic/(.7+d[16]*.6)
 local demand=math.max(.55,mass*.17+metabolic*.4);local resp=lungs+exchange
 local supply=math.min(1,heart/demand*vascular,resp/demand);local wasteRatio=math.min(1,waste/math.max(.25,metabolic*.6))
 local joints=0;for _,j in ipairs(a.joints) do joints=joints+j.mobility*j.condition end;joints=joints/math.max(1,#a.joints)
 local modes={};local contraction=math.max(0,1-d[11]*.85)*activeMuscles/math.max(1,#a.muscles)
 if a.appendageCount>0 and #a.joints>0 and joints>.05 then modes.jointed=.35+joints*.65 end
 if contraction>.1 and rawForce>.01 then modes.contractions=contraction*(.5+d[12]*.5) end
 if #a.regions>2 and a.axisAspect>1.7 and contraction>.1 then modes.undulation=contraction*(.8+math.min(2,a.axisAspect)*.2) end
 if a.symmetry=='radial' and rawForce>.01 then modes.radial=(.4+contraction*.6)*math.min(1,#a.regions/4+.2) end
 local method,best='stationary',0;for _,name in ipairs({'jointed','contractions','undulation','radial'}) do if (modes[name] or 0)>best then method=name;best=modes[name] end end
 local sense=0;for _,s in ipairs(a.sensors) do local parent=a.components[s.parent];sense=sense+s.acuity*s.condition*(parent and parent.condition or 0) end
 local force=rawForce*tissueSupport*coordination;local stride=0;for _,st in ipairs(a.structures) do if st.region=='limb' then stride=stride+st.length*st.condition end end;stride=stride/math.max(1,a.appendageCount)/20
 local c={mass=mass,force=force,support=tissueSupport,circulation=heart,respiration=resp,lungCapacity=lungs,cutaneousExchange=exchange,supply=supply,coordination=coordination,skin=skin/math.max(1,#a.skin),fatCapacity=fat,metabolicDemand=metabolic,digestion=digest,perception=.04+math.min(.5,sense*.035)*neural,immunity=e.immunity,lifespan=230+e[6]*240,fitness=e.fitness,stride=stride,wasteHandling=wasteRatio,movementModes=modes,locomotion=method,stability=math.min(tissueSupport,supply,coordination*2,wasteRatio)}
 c.speed=best*(.012+math.sqrt(math.max(0,rawForce)/math.max(1,mass))*.045)*coordination*tissueSupport*(.6+e[9]*.4)*math.min(1,.3+supply)
 c.maxHealth=65+mass*2+e[5]*45;c.endurance=(.25+e[7])*(.3+supply)*50;c.energyCapacity=100+fat;c.tolerance=(e[10]+e[18]+e[6])/3;c.growthRate=.012+e[6]*.01;c.mentalCondition=coordination*(.5+e[4]*.5);return Eco.capabilities(a,g,c)
end
function A.validate(a)
 if a.anatomicalVersion then return require('body_parts').validate(a) end
 if a.version~=3 then return Legacy.validate(a) end
 local failures,limitations={},{};local c=a.caps
 if #a.regions>a.limits.regions or #a.components>a.limits.components then failures[#failures+1]='Development exceeded complexity budget' end
 for i,r in ipairs(a.regions) do if i>1 and (not r.parent or not a.regions[r.parent] or r.parent>=r.id) then failures[#failures+1]='Disconnected or cyclic growth region '..i end end
 for i,part in ipairs(a.components) do if part.parent and (not a.components[part.parent] or part.parent>=i) then failures[#failures+1]='Invalid tissue attachment '..i end end
 if c.support<.16 then failures[#failures+1]='Developed tissues exceed structural support' elseif c.support<.5 then limitations[#limitations+1]='Low tissue support limits force' end
 if c.circulation<.15 or c.supply<.16 then failures[#failures+1]='Circulation/exchange cannot sustain tissue demand' elseif c.supply<.55 then limitations[#limitations+1]='Supply limits stamina and sustained activity' end
 if c.respiration<.12 then failures[#failures+1]='No functional environmental exchange' end
 if c.compatibility and math.max(c.compatibility.land,c.compatibility.freshwater)<.12 then failures[#failures+1]='No viable respiratory environment' end
 if c.digestion<.1 then failures[#failures+1]='Insufficient nutrient acquisition' end
 if c.coordination<.045 or #a.nerves<#a.regions then failures[#failures+1]='Neural network cannot coordinate developed tissues' end
 if c.wasteHandling<.1 then failures[#failures+1]='Waste handling cannot support metabolism' end
 if c.locomotion=='stationary' then limitations[#limitations+1]='Stationary: limited to resources within reach' end
 for _,o in ipairs(a.organs) do local host=a.regions[o.regionId];if not host then failures[#failures+1]='Organ has no host region' else local dx,dy=o.x-host.x,o.y-host.y;local ca,sa=math.cos(host.orientation),math.sin(host.orientation);if ((dx*ca+dy*sa)/(host.rx-o.rx))^2+((-dx*sa+dy*ca)/(host.ry-o.ry))^2>1.001 then failures[#failures+1]='Organ outside protected cavity: '..o.type end end end
 for i,o in ipairs(a.organs) do for j=i+1,#a.organs do local p=a.organs[j];if (o.x-p.x)^2+(o.y-p.y)^2<(o.rx+p.rx+.3)^2 then failures[#failures+1]='Overlapping organ cavities' end end end
 a.limitations=limitations;return #failures==0,failures
end
function A.procedural(g,conditions)
 g=G.upgrade(g);local a=F.generate(g,conditions);Eco.enrich(a,g,conditions);a.caps=A.capabilities(a,g);a.viable,a.failures=A.validate(a);return a
end
function A.blocks(g,conditions)
 g=G.upgrade(g);local a=require('reconstruction').generate(g,conditions);a.caps=A.capabilities(a,g);a.viable,a.failures=A.validate(a);a.limitations={'Experimental anatomy: inspect structural tradeoffs'};return a
end
function A.generate(g,conditions)
 if not conditions or not conditions.generator or conditions.generator=='anatomical' then return A.blocks(g,conditions) end
 if (conditions and conditions.generator=='legacy') or not certificate.approved then local a=Legacy.generate(g,conditions);a.generator='legacy-fallback';a.caps=A.capabilities(a,g);return a end
 local ok,a=pcall(A.procedural,g,conditions)
 if ok then return a end -- Biological failure is reported, never silently replaced.
 local fallback=Legacy.generate(g,conditions);fallback.generator='legacy-fallback';fallback.technicalFallback=tostring(a);fallback.caps=A.capabilities(fallback,g);return fallback
end
function A.damage(a,region,amount)
 if a.version~=3 then return Legacy.damage(a,region,amount) end
 for _,c in ipairs(a.components) do if c.region==region or c.type==region or region=='Bone' and (c.type=='Support' or c.type=='Carapace') then c.condition=math.max(0,c.condition-amount) end end
 for _,j in ipairs(a.joints) do if region=='limb' then j.condition=math.max(0,j.condition-amount) end end
end
return A
