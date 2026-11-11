local EG=require('environment_genes');local Diet=require('diet')
local E={}
local function clamp(v) return math.max(0,math.min(1,v)) end
function E.enrich(a,g,conditions)
 if a.ecology then return end
 local q=EG.expression(g);conditions=conditions or {};a.ecology={genes=q,version=1};a.surfaces={};a.projections={};a.airways={};a.gills={};a.mouths={}
 for _,support in ipairs(a.structures or {}) do support.mass=support.mass*(.6+q[7]*.8);support.strength=support.strength*(.75+q[8]*.5) end
 local minerals=conditions.minerals or 1;local nutrition=conditions.nutrition or 1;local oxygen=conditions.oxygen or 1
 local function add(kind,host,props)
  local c={id=#a.components+1,type=kind,parent=host.id,regionId=host.regionId,x=host.x,y=host.y,rx=2,ry=2,size=4,orientation=host.orientation or 0,condition=1,mass=.02,region=host.region or 'torso'};for k,v in pairs(props) do c[k]=v end;a.components[#a.components+1]=c;return c
 end
 for i,c in ipairs(a.skin) do
  local r=a.regions[c.regionId];local nearJoint=r.jointed and .22 or 0;local signal=math.sin(r.id*1.7+q[23]*3)*q[23]*.22;local central=r.kind=='axis' and .09 or -.06
  c.keratinization=clamp(q[14]+central+signal);c.mineralization=clamp(q[15]*minerals+central-signal*.6);c.flexibility=clamp(q[16]+nearJoint-central);c.segmentation=clamp(q[17]+(r.kind=='appendage' and .18 or 0));c.thickness=clamp(q[18]+central+signal*.5);c.regeneration=.02+q[19]*.12
  c.hardness=.45*c.keratinization+.55*c.mineralization;c.rigidity=c.hardness*(1-.7*c.flexibility);c.armor=c.thickness*c.hardness*(1+.5*c.segmentation)
  c.covering=c.hardness<.35 and (c.thickness>.55 and 'thick hide' or 'soft skin') or c.segmentation>.5 and c.flexibility>.4 and 'scales' or c.rigidity>.4 and c.thickness>.45 and 'carapace' or 'keratinized hide'
  c.baseMass=c.mass;c.mass=c.mass+(c.rx*c.ry/100)*c.thickness*(.15+c.mineralization*.3);c.exchange=(c.exchange or 0)*(1-c.thickness*.55)*(1-c.hardness*.65)
  local support=a.components[c.parent]
  if q[9]>.4 and r.kind=='appendage' then local area=(r.rx+r.ry)*(3+q[9]*15);local f=add('Fin',support,{x=r.x,y=r.y,rx=r.rx+q[9]*5,ry=r.ry+q[9]*6,area=area,mass=area*.004,efficiency=q[9]*(.4+c.flexibility*.6),regionId=r.id});a.surfaces[#a.surfaces+1]=f end
  if q[10]>.5 and r.kind=='appendage' and r.parent and r.depth==1 then local parent=a.regions[r.parent];local span=math.sqrt((r.x-parent.x)^2+(r.y-parent.y)^2);local area=span*(3+q[10]*20)*(1-c.rigidity*.6);local m=add('Membrane',support,{x=r.x,y=r.y,rx=math.max(3,span*.5),ry=3+q[10]*10,area=area,mass=area*(.002+.004*(1-q[24])),control=q[11],aX=parent.x,aY=parent.y,bX=r.x,bY=r.y,regionId=r.id});a.surfaces[#a.surfaces+1]=m end
 end
 for _,o in ipairs(a.organs) do if o.type=='Lung' then o.airExchange=o.capacity*(.08+q[1]^2*1.8)*(.5+q[3])*(.65+.35*oxygen);local airway=add('Airway',o,{mass=.01,capacity=o.airExchange,regionId=o.regionId});a.airways[#a.airways+1]=airway end end
 if q[2]>.34 then
  for i=1,math.min(5,1+math.floor(q[2]*4)) do local host=a.skin[1+math.floor((i-1)/5*(#a.skin-1))];local r=a.regions[host.regionId];local area=(r.rx*r.ry*.24+4)*q[2];local gi=add('Gill',host,{x=host.x,y=host.y+host.ry*.5,rx=math.max(2,host.rx*.45),ry=2,area=area,efficiency=.4+q[3]*.6,capacity=area*.3*(.5+q[2])*(.65+.35*oxygen),mass=area*.007,ventilation=.3+q[9]*.7,regionId=host.regionId});a.gills[#a.gills+1]=gi end
 end
 local stomach;for _,o in ipairs(a.organs) do if o.type=='Stomach' then stomach=o;break end end
 if stomach then local mouth=add('Mouth',stomach,{x=stomach.x+stomach.rx*1.2,y=stomach.y,rx=2+q[22]*2,ry=1.5,aperture=2+q[22]*4,capacity=stomach.capacity,forceCoupling=.3+q[22]*.7});a.mouths[#a.mouths+1]=mouth end
 if q[20]>.34 then
  for i,c in ipairs(a.skin) do local r=a.regions[c.regionId];local host=a.components[c.parent];local terminal=r.kind=='appendage' and #r.connections==1;local exposed=r.kind=='axis' or terminal
   if exposed and c.hardness>.26 and (i%math.max(1,4-math.floor(q[20]*3))==0) then
    local length=(2+q[20]*12)*(terminal and 1 or .8);local width=1+(1-q[21])*4;local strength=host.strength*c.hardness
    local role=terminal and q[21]>.45 and 'claw' or length/width>3 and 'spine' or host.strength>2 and 'horn' or 'protective projection'
    local p=add('Projection',host,{x=c.x+math.cos(c.orientation)*c.rx*.75,y=c.y+math.sin(c.orientation)*c.ry*.75,rx=length/2,ry=width/2,size=length,length=length,width=width,sharpness=q[21],hardness=c.hardness,strength=strength,attachmentStrength=host.strength,mass=length*width*(.003+c.mineralization*.006),growthCost=length*width*.02,regeneration=c.regeneration,role=role,geometryAngle=c.orientation+(terminal and 0 or math.pi/2),regionId=c.regionId});a.projections[#a.projections+1]=p
   end
  end
  if a.mouths[1] then local m=a.mouths[1];local host=a.components[m.parent];local c=a.skin[1];for i=1,1+math.floor(q[20]*3) do local p=add('Projection',m,{x=m.x,y=m.y+(i-2)*1.4,length=1+q[20]*4,width=1,rx=1,ry=1,size=3,sharpness=q[21],hardness=.45*q[14]+.55*q[15],strength=host.capacity*.2,attachmentStrength=host.capacity*.2,mass=.015,growthCost=.1,regeneration=.02+q[19]*.1,role=q[21]>.5 and 'tooth' or 'crushing mouthpart',geometryAngle=0});a.projections[#a.projections+1]=p end end
 end
 if a.bounds then local bounds=a.bounds;for _,part in ipairs(a.surfaces) do bounds.minx=math.min(bounds.minx,part.x-part.rx);bounds.maxx=math.max(bounds.maxx,part.x+part.rx);bounds.miny=math.min(bounds.miny,part.y-part.ry);bounds.maxy=math.max(bounds.maxy,part.y+part.ry) end;for _,part in ipairs(a.projections) do local tx=part.x+math.cos(part.geometryAngle or 0)*part.length;local ty=part.y+math.sin(part.geometryAngle or 0)*part.length;bounds.minx=math.min(bounds.minx,tx-2);bounds.maxx=math.max(bounds.maxx,tx+2);bounds.miny=math.min(bounds.miny,ty-2);bounds.maxy=math.max(bounds.maxy,ty+2) end;bounds.width=bounds.maxx-bounds.minx;bounds.height=bounds.maxy-bounds.miny end
 a.developmentCost=0;for _,p in ipairs(a.projections) do a.developmentCost=a.developmentCost+p.growthCost end
 a.growthFactor=1/(1+a.developmentCost*.01+q[18]*q[15]*.25);a.ecology.nutrition=nutrition
end
function E.capabilities(a,g,c)
 local q=a.ecology and a.ecology.genes or EG.expression(g);local legacy=not a.ecology;local air,water,wet,dry,lift,swim,hard,rigid,teeth=0,0,0,0,0,0,0,0,0
 if legacy then air=c.respiration;water=(c.cutaneousExchange or 0)*.4 else
  for _,o in ipairs(a.organs) do if o.type=='Lung' then local opening=1;for _,path in ipairs(a.airways or {}) do if path.parent==o.id then opening=path.condition;break end end;air=air+(o.airExchange or o.capacity)*o.condition*opening end end
  for _,gi in ipairs(a.gills or {}) do local host=a.components[gi.parent];water=water+gi.capacity*gi.efficiency*gi.condition*(host.condition or 1)*(.4+gi.ventilation*.6) end
 end
 for _,s in ipairs(a.skin) do local perm=(s.exchange or 0)*s.condition;wet=wet+perm*(.6+q[2]);dry=dry+perm*(.35+q[1])*(.4+q[4]*.6);hard=hard+(s.hardness or 0);rigid=rigid+(s.rigidity or 0) end
 air=air+dry;water=water+wet
 for _,surface in ipairs(a.surfaces or {}) do local host=a.components[surface.parent];local condition=surface.condition*host.condition;if surface.type=='Membrane' then lift=lift+surface.area*condition*(.3+surface.control*.7) else swim=swim+surface.area*surface.efficiency*condition end end
 for _,p in ipairs(a.projections or {}) do if p.role=='tooth' or p.role=='crushing mouthpart' then teeth=teeth+p.hardness*p.condition end;p.effectiveness=math.min(p.strength or 0,p.attachmentStrength or 0)*(c.force or 0)*p.condition*(a.components[p.parent].condition or 0)/(1+p.mass*3) end
 c.metabolicDemand=c.metabolicDemand*(1+hard/math.max(1,#a.skin)*.12);c.growthRate=c.growthRate*(a.growthFactor or 1)
 local demand=math.max(.5,c.mass*.12+c.metabolicDemand*.35);local airRatio=air/demand;local waterRatio=water/demand;if not legacy then c.respiration=math.max(air,water);c.supply=math.min(1,c.circulation/demand,c.respiration/demand) end
 local landSupport=math.min(1,c.support*(.75+q[8]*.5));local aquaticMotion=math.min(1,.3+(c.movementModes and (c.movementModes.undulation or c.movementModes.contractions or c.movementModes.radial) or .3)*.4+swim/math.max(10,c.mass*5))
 local liftRatio=lift/math.max(1,c.mass*(.65+q[7]*.7)*8);local control=q[11]*c.coordination*2;local propulsion=(c.force or 0)/math.max(.1,c.mass*.035)
 c.flight={surfaceArea=lift,liftRatio=liftRatio,control=control,propulsion=propulsion,glide=liftRatio>=.65 and control>.18,powered=liftRatio>=1.1 and control>.3 and propulsion>.7 and c.support>.35}
 c.compatibility={land=clamp(airRatio)*landSupport,freshwater=clamp(waterRatio)*(.65+aquaticMotion*.35),saltwater=clamp(waterRatio)*(.65+aquaticMotion*.35)*(.15+q[13]*.85),flight=c.flight.powered and clamp(math.min(liftRatio/1.5,propulsion,control)) or c.flight.glide and clamp(liftRatio*.3) or 0}
 c.airRespiration=air;c.aquaticRespiration=water;c.oxygenDemand=demand;c.buoyancy=q[6]-.5*q[7];c.moistureRetention=q[4]*(.6+(hard/math.max(1,#a.skin))*.4);c.salinityTolerance=q[13];c.temperatureTolerance=12+q[12]*25;c.waterResistance=q[5];c.swimSpeed=(c.speed*2+.012*aquaticMotion)*(.8+c.buoyancy*.4);c.swimSpeed=c.swimSpeed/(1+(1-q[5])*.3);c.landSpeed=c.speed*5*landSupport/(1+rigid/math.max(1,#a.skin)*.35)
 local mouthCondition=1;if a.mouths and #a.mouths>0 then mouthCondition=0;for _,mouth in ipairs(a.mouths) do mouthCondition=mouthCondition+mouth.condition end;mouthCondition=mouthCondition/#a.mouths end
 c.biteForce=c.force*(.3+q[22]*.7)*mouthCondition;c.diet,c.feedingStrategy=Diet.capabilities(a,c,q,teeth,mouthCondition,water);c.coverHardness=hard/math.max(1,#a.skin)
 return c
end
return E
