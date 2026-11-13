-- Refine the existing genetic regional plan into a real connected tissue graph.
-- No complete animal templates: appendage roles share one articulated builder.
local G=require('genome');local P=require('body_parts');local F={}
local function localPoint(r,x,y,z) local c,s=math.cos(r.orientation),math.sin(r.orientation);return {x=r.cx+c*x+s*z,y=r.cy+y,z=r.cz-s*x+c*z} end
local function volume(r) r.rx=r.length/2;r.ry=r.thickness/2;r.rz=r.width/2;r.volume=math.pi*r.length*r.width*r.thickness/(6*32^3);r.freeVolume=r.volume;r.tissues={};r.tissueIds={} end
function F.generate(g,conditions)
 local old=require('anatomical_growth').generate(g,conditions);local e=G.express(g);local d,q=e.development,e.ecology;local a=P.new(g,conditions)
 a.anatomicalVersion=2;a.generator='skeletal-reconstruction-v2';a.parameters=d;a.ecology={genes=q,version=2};a.limits={regions=320,components=6000};a.regions=G.copy(old.regions);a.parts=a.regions;a.appendageCount=old.appendageCount;a.limbPairs=old.limbPairs;a.headCount=old.headCount;a.symmetry=old.symmetry;a.segments=old.segments;a.pigment=old.pigment
 a.bodyOrientation=(d[19]-.5)*2.7;a.supportStrategy=d[11]>.48 and 'articulated endoskeleton' or d[20]>.65 and 'segmented exoskeleton' or 'hydrostatic axial framework'
 a.posture=d[7]<.3 and 'splayed' or d[7]>.68 and 'suspended' or 'load-bearing';local axis={};local source=old.regions
 -- The genetic axis can be upright, curved, compact or elongated. Axial regions
 -- are connected cavities along a spine, not independent finished body ovals.
 for _,r in ipairs(a.regions) do
  local original=source[r.id];r.tissues={};r.tissueIds={};r.structure=nil;r.neuralNode=nil
  if r.partType=='chest' or r.partType=='abdomen' or r.partType=='pelvis' or r.partType=='trunk' then
   axis[#axis+1]=r;r.length=r.length*(.28+d[1]*d[1]*1.35);r.thickness=r.thickness*(.65+d[2]*.8);r.width=r.width*(.7+d[2]*.55)
   r.orientation=a.bodyOrientation+(#axis-1)*(d[3]-.5)*.6
   if r.parent then local p=a.regions[r.parent];local pt=localPoint(p,-p.length*.42,0,0);local cx=math.cos(r.orientation)*r.length*.34;local sz=-math.sin(r.orientation)*r.length*.34;r.cx,r.cy,r.cz=pt.x-cx,pt.y,pt.z-sz;r.attachment={x=pt.x-p.cx,y=0,z=pt.z-p.cz} else r.cx,r.cy,r.cz=0,0,0 end
  else
   local parent=a.regions[r.parent];local op=source[r.parent];local dx,dy,dz=original.cx-op.cx,original.cy-op.cy,original.cz-op.cz
   local angle=a.bodyOrientation;local c,s=math.cos(angle),math.sin(angle)
   -- Appendage orientation varies with attachment program and function.
   if r.partType=='segment' then local role=(d[21]>.58 and (r.root or r.parent)==1) and 'manipulation' or q[9]>.66 and 'swimming' or 'support';r.functionalRole=role;r.specialization=role=='manipulation' and ((r.pathIndex or 1)==1 and 'upper arm' or 'forearm') or ((r.pathIndex or 1)==1 and 'upper leg' or 'lower leg');angle=angle+(d[7]-.5)*1.1;r.thickness=r.thickness*(.65+e[16]*1.2);r.width=r.width*(.8+e[16]*.6) end
   if r.partType=='cranium' then r.length=r.length*(.55+d[14]*1.1);r.width=r.width*(.65+d[23]*.7);r.thickness=r.thickness*(.7+d[14]*.55) end
   if r.partType=='snout' then local skull=parent;r.length=skull.length*(.15+q[22]*.85);dx=skull.length*.45+r.length*.35;r.width=skull.width*(.35+d[14]*.4);r.thickness=skull.thickness*(.25+d[23]*.3) end
   r.cx=parent.cx+c*dx+s*dz;r.cy=parent.cy+dy;r.cz=parent.cz-s*dx+c*dz;r.orientation=original.orientation+angle
   local at=original.attachment or {x=0,y=0,z=0};r.attachment={x=c*at.x+s*at.z,y=at.y,z=-s*at.x+c*at.z}
   if original.start then local sx,sy,sz=original.start.x-op.cx,original.start.y-op.cy,original.start.z-op.cz;r.start={x=parent.cx+c*sx+s*sz,y=parent.cy+sy,z=parent.cz-s*sx+c*sz};r.finish={x=r.start.x+math.cos(r.orientation)*r.length,y=r.start.y,z=r.start.z-math.sin(r.orientation)*r.length};r.cx=(r.start.x+r.finish.x)/2;r.cz=(r.start.z+r.finish.z)/2 end
  end
  r.x,r.y=r.cx,-r.cz;volume(r)
 end
 -- Replace old terminal stubs by bases with individual jointed phalanges.
 local bases={};for _,r in ipairs(a.regions) do if r.terminal then bases[#bases+1]=r end end
 for _,base in ipairs(bases) do
  base.functionalRole=a.regions[base.parent].functionalRole;base.partType=base.functionalRole=='manipulation' and 'hand' or 'foot';base.role='distal base and load distribution';base.specialization=base.partType;base.shape='loft'
  local count=1+math.floor(e[3]*2+d[10]*1.5);local segments=1+math.floor(d[10]*2.8)
  for digit=1,count do local parent=base;local start=localPoint(base,base.length*.34,(digit-(count+1)/2)*base.width/math.max(1,count),0)
   for k=1,segments do local len=base.length*(.3+d[8]*.35)*(1-(k-1)*.16);local h=base.thickness*.46*(1-(k-1)*.18);local pt={x=start.x+math.cos(base.orientation)*len*.5,y=start.y,z=start.z-math.sin(base.orientation)*len*.5+(digit-(count+1)/2)*base.thickness*.13}
    local r=P.add(a,'digit',parent.id,{cx=pt.x,cy=pt.y,cz=pt.z,length=len,width=h,thickness=h,orientation=base.orientation+(digit-(count+1)/2)*.10,appendage=true,genes={'L3','D8','D10','E21'},attachment={x=start.x-parent.cx,y=start.y-parent.cy,z=start.z-parent.cz},digitIndex=digit,digitSegment=k,jointed=true,specialization='phalange',functionalRole='fine motor control',start=G.copy(start)})
    r.finish=localPoint(r,r.length*.5,0,0);start=G.copy(r.finish);parent=r
   end
   if q[21]>.48 then local len=base.length*(.2+q[21]*.5);local pt=localPoint(parent,parent.length*.5+len*.4,0,-len*.12);local claw=P.add(a,'claw',parent.id,{cx=pt.x,cy=pt.y,cz=pt.z,length=len,width=base.width*.15,thickness=base.thickness*.22,orientation=base.orientation+.3+q[21]*.3,curvature=.2+q[21]*.6,taper=.9,appendage=true,genes={'E14','E15','E21'},attachment={x=pt.x-parent.cx,y=pt.y-parent.cy,z=pt.z-parent.cz},specialization='terminal keratin',functionalRole='grip'}) end
  end
 end
 local kind=d[11]>.48 and 'Bone' or d[20]>.65 and 'Carapace' or 'Support'
 local function support(r,name,point,vol,parent,path)
  local c=P.component(a,r,kind,parent,vol,{cx=point.x,cy=point.y,cz=point.z,x=point.x,y=-point.z,anatomicalName=name,length=r.length/32,width=r.width/32,thickness=r.thickness/32*(.1+e[15]*.25),density=.45+e[15]*.75,rigidity=d[11],flexibility=1-d[11],strength=(.5+e[15]*2)*math.max(.000001,vol)^.65*13,path=path,jointPoints={},muscleAttachments={},integrity=1})
  local length=0;for i=2,#(path or {}) do local p,q=path[i-1],path[i];length=length+math.sqrt((p.x-q.x)^2+(p.y-q.y)^2+(p.z-q.z)^2)/32 end;c.length=math.max(.0001,length);c.width=2*math.sqrt(math.max(0,c.volume)/(math.pi*c.length));c.thickness=c.width*(.65+e[15]*.35)
  a.structures[#a.structures+1]=c;if c.type=='Bone' then a.bones[#a.bones+1]=c end;return c
 end
 -- Actual vertebrae, rib arches, girdles, paired long supports, skull rims.
 for _,r in ipairs(a.regions) do
  local axial=r.cavityAllowed and r.partType~='cranium';local n=axial and 3+math.floor(d[5]*4) or r.partType=='neck' and 1+math.floor(d[13]*4) or 1
  local parent=r.parent and a.regions[r.parent].distalSupport;local total=r.volume*(.075+e[15]*.065);r.skeletalIds={}
  for k=1,n do local u=(k-.5)/n;local pt=localPoint(r,r.length*(.5-u),0,axial and r.thickness*.2 or 0);local finish=localPoint(r,r.length*(.5-u-.6/n),0,axial and r.thickness*.2 or 0);local c=support(r,axial and 'vertebra '..k or r.partType=='neck' and 'cervical segment '..k or r.specialization or r.partType,pt,total/n,parent,{pt,finish});r.structure=r.structure or c.id;r.skeletalIds[#r.skeletalIds+1]=c.id;parent=c.id end
  r.distalSupport=parent
  if axial then for k=1,2+math.floor(d[2]*3) do local u=k/(3+math.floor(d[2]*3));for side=-1,1,2 do local path={localPoint(r,r.length*(.4-u*.8),0,r.thickness*.2),localPoint(r,r.length*(.4-u*.8),side*r.width*.4,r.thickness*.05),localPoint(r,r.length*(.4-u*.8),side*r.width*.32,-r.thickness*.32)};support(r,'protective rib arch',path[2],r.volume*.012,r.structure,path) end end
   local path={localPoint(r,0,-r.width*.45,0),localPoint(r,0,0,-r.thickness*.12),localPoint(r,0,r.width*.45,0)};support(r,r.partType=='pelvis' and 'pelvic girdle' or 'shoulder / axial girdle',path[2],r.volume*.015,r.structure,path)
  elseif r.partType=='cranium' then local path={};for k=0,16 do local t=k/16*math.pi*2;path[#path+1]=localPoint(r,math.cos(t)*r.length*.42,0,math.sin(t)*r.thickness*.4) end;support(r,'cranial protective vault',localPoint(r,0,0,0),r.volume*.035,r.structure,path)
   for side=-1,1,2 do local eye=localPoint(r,r.length*.22,side*r.width*.35,r.thickness*.12);support(r,'orbital rim',eye,r.volume*.008,r.structure,{localPoint(r,r.length*.12,side*r.width*.35,r.thickness*.22),eye,localPoint(r,r.length*.33,side*r.width*.35,r.thickness*.16)}) end
  elseif r.partType=='segment' and d[11]>.45 then support(r,'paired distal support',localPoint(r,0,r.width*.18,0),r.volume*.035,r.structure,{localPoint(r,-r.length*.42,r.width*.18,0),localPoint(r,r.length*.42,r.width*.18,0)}) end
  if r.parent then local host=a.regions[r.parent];local at={x=host.cx+r.attachment.x,y=host.cy+r.attachment.y,z=host.cz+r.attachment.z};local name=r.partType=='digit' and 'digit hinge' or r.partType=='lower_jaw' and 'jaw hinge' or r.partType=='segment' and ((r.pathIndex or 1)==1 and 'shoulder / hip' or (r.pathIndex or 1)==2 and 'elbow / knee' or 'wrist / ankle') or 'axial articulation'
   a.joints[#a.joints+1]={id=#a.joints+1,parent=host.distalSupport,child=r.structure,partId=r.id,type=name,minimum=-.15-d[10]*.65,maximum=.2+d[10]*1.1,range=.35+d[10]*1.75,mobility=.2+e[3]*.7,stability=.4+e[15]*.5,strength=a.components[r.structure].strength,condition=1,cx=at.x,cy=at.y,cz=at.z,x=at.x,y=-at.z,supportingTissues={}}
  end
 end
 -- Existing organ instructions are retained; transformed cavities keep canonical
 -- organ types so circulation, exchange, digestion and cognition use real tissues.
 local occupied={};local quality=math.max(.02,math.min(1.4,(conditions and conditions.nutrition or 1)*(conditions and conditions.oxygen or 1)*(1-math.abs((conditions and conditions.temperature or 37)-37)/40)))
 local function organ(kind,r,locus,serial)
  local radius=math.min(r.rx,r.ry,r.rz)*(.17+e[locus]*.07);local v=4/3*math.pi*(radius/32)^3
  -- Deterministic cavity search: keep each organ inside its host's
  -- ellipsoidal cavity and separate organs in full 3-D, not by a flat
  -- screen-space overlap. No random draws or growth-system changes.
  local clearance=radius*.92
  local maxX=math.max(0,r.length*.43-clearance)
  local maxY=math.max(0,r.width*.43-clearance)
  local maxZ=math.max(0,r.thickness*.43-clearance)
  for attempt=0,35 do
   local t=(attempt+serial)*2.39996322972865
   local ring=attempt==0 and 0 or math.sqrt(attempt/35)*.82
   local axial=attempt==0 and 0 or math.sin(t*.73)*ring
   local lateral=attempt==0 and 0 or math.cos(t)*ring
   local vertical=attempt==0 and 0 or math.sin(t)*ring
   local pt=localPoint(r,axial*maxX,lateral*maxY,vertical*maxZ)
   local fit=v<r.freeVolume
   for _,o in ipairs(occupied) do
    if o.regionId==r.id then
     local dx=pt.x-o.cx
     local dy=pt.y-o.cy
     local dz=pt.z-o.cz
     local separation=radius+(o.rx or radius)
     if dx*dx+dy*dy+dz*dz<separation*separation*.72 then fit=false;break end
    end
   end
   if fit then local scale=kind=='Lung' and 350 or kind=='Heart' and 300 or kind=='Stomach' and 320 or 120;local capacity=v*scale*(.4+e[locus]*.6)*quality
    local c=P.component(a,r,kind,r.structure,v,{cx=pt.x,cy=pt.y,cz=pt.z,x=pt.x,y=-pt.z,rx=radius,ry=radius,rz=radius,capacity=capacity,efficiency=.4+e[locus]*.55,wasteCapacity=kind=='Kidney' and capacity or 0,airExchange=kind=='Lung' and capacity*(.2+q[1]*1.8) or nil,anatomicalName=kind=='Heart' and a.supportStrategy=='hydrostatic axial framework' and 'peristaltic circulatory pump' or kind=='Brain' and a.headCount==0 and 'distributed central ganglion' or kind})
    a.organs[#a.organs+1]=c;occupied[#occupied+1]=c;return c
   end
  end;a.placementFailures[#a.placementFailures+1]='No suitable cavity for '..kind..' in '..r.uid
 end
 local hearts,brains={},{};local h=organ('Heart',axis[1],19,1);if h then hearts[1]=h end
 if q[1]>.18 then organ('Lung',axis[1],20,2) end;organ('Stomach',axis[math.min(2,#axis)],21,3);organ('Kidney',axis[#axis],19,4);organ('Gonad',axis[#axis],24,5)
 for _,r in ipairs(a.regions) do if r.partType=='cranium' then local b=organ('Brain',r,22,1);if b then brains[#brains+1]=b;r.brain=b.id end end end
 if #brains==0 and a.headCount==0 then local b=organ('Brain',axis[1],22,6);if b then brains[1]=b end end
 for _,r in ipairs(a.regions) do
  local host=r.parent and a.regions[r.parent];local origin=host and host.distalSupport or r.skeletalIds[2] or (axis[2] and axis[2].structure)
  -- Antagonistic bundles are separate tissue volumes with attachment geometry.
  if origin then for side=-1,1,2 do local share=(r.partType=='cranium' or r.jaw) and .09 or .11+e[16]*.10;local pt=localPoint(r,0,0,side*r.thickness*.17);local m=P.component(a,r,'Muscle',r.structure,r.volume*share,{cx=pt.x,cy=pt.y,cz=pt.z,x=pt.x,y=-pt.z,rx=r.length*.38,ry=r.thickness*.20,rz=r.width*.2,density=.5+e[16]*.25,origin=origin,insertion=r.distalSupport,force=.8+e[2]*1.8,efficiency=.4+e[3]*.5,leverage=(.3+d[10]*.5)/(1+r.length/80),fiberQuality=.35+e[2]*.6,energyCost=.1+e[1]*.2,fatigue=0,functionalRole=side<0 and 'flexor / ventral stabilizer' or 'extensor / dorsal stabilizer',muscleSide=side});a.muscles[#a.muscles+1]=m;local st=a.components[m.insertion];st.muscleAttachments[#st.muscleAttachments+1]=m.id;P.component(a,r,'Tendon',r.structure,r.volume*.01,{origin=origin,insertion=r.distalSupport,strength=st.strength*.7}) end end
  local nerve=P.component(a,r,'Nerve',r.structure,r.volume*(.007+e[22]*.012),{capacity=.25+e[22]*.7,efficiency=.3+e[22]*.6,anatomicalName=r.parent and 'peripheral branch' or 'axial nerve cord'});r.neuralNode=nerve.id
  local sourceNode=host and host.neuralNode or brains[1] and brains[1].id
  if sourceNode then a.nerves[#a.nerves+1]={from=sourceNode,to=nerve.id,efficiency=nerve.efficiency,condition=1} end
  for _,id in ipairs(r.skeletalIds) do a.nerves[#a.nerves+1]={from=nerve.id,to=id,efficiency=nerve.efficiency,condition=1} end
  for _,m in ipairs(a.muscles) do if m.regionId==r.id then a.nerves[#a.nerves+1]={from=nerve.id,to=m.id,efficiency=nerve.efficiency,condition=1} end end
  if hearts[1] then a.vessels[#a.vessels+1]={from=host and host.structure or hearts[1].id,to=r.structure,capacity=hearts[1].capacity,condition=1} end
  if r.partType=='cranium' or r.partType=='antenna' or r.partType=='digit' then local pt=localPoint(r,r.length*.2,0,r.thickness*.12);local c=P.component(a,r,'Sensor',r.structure,math.min(.0004,r.volume*.02),{cx=pt.x,cy=pt.y,cz=pt.z,x=pt.x,y=-pt.z,rx=1,ry=1,rz=1,acuity=.3+e.perception*.65,socket=r.partType=='cranium' and 'orbital rim' or 'tactile terminal'});a.sensors[#a.sensors+1]=c;a.nerves[#a.nerves+1]={from=nerve.id,to=c.id,efficiency=nerve.efficiency,condition=1} end
  local storage=(r.partType=='abdomen' and 1.7 or r.partType=='digit' and .3 or 1);local v=r.volume*(.02+e[17]*.11)*storage;local fat=P.component(a,r,'Fat',r.structure,v,{capacity=v*30,insulation=.2+e[17]*.5,storageEfficiency=.4+e[17]*.5,preferredThickness=.2+e[17]*.5});a.fat[#a.fat+1]=fat
  for _,surface in ipairs({'dorsal','ventral'}) do local t=(.1+e[18]*.4+q[18]*.3)*(surface=='ventral' and .55 or 1);local skin=P.component(a,r,'Skin',r.structure,r.volume*(.025+t*.05),{surface=surface,thickness=t,toughness=.25+e[18]*.6,hardness=.25+q[14]*.35+q[15]*.4,armor=q[18]*(.2+q[14]*.4+q[15]*.4)*(r.partType=='abdomen' and .5 or 1)*(surface=='ventral' and .4 or 1),flexibility=.3+q[16]*.6,rigidity=q[15]*(1-q[16]*.6),covering=q[15]>.68 and 'plates' or q[14]>.6 and 'scales' or 'elastic skin',exchange=r.volume*(1-t)*(.4+q[1]*.6)*4,wasteCapacity=r.volume*.5,regeneration=.02+q[19]*.1});a.skin[#a.skin+1]=skin end
  if r.cavityAllowed and q[2]>.4 then local gi=P.component(a,r,'Gill',r.structure,r.volume*.018,{capacity=r.volume*(.3+q[2])*15,efficiency=.4+q[3]*.6,ventilation=.3+q[9]*.7,area=r.length*r.width/32^2});a.gills[#a.gills+1]=gi end
  if r.functionalRole=='swimming' or r.partType=='fin' or q[10]>.7 and r.partType=='segment' then local membrane=q[10]>.7;local c=P.component(a,r,membrane and 'Membrane' or 'Fin',r.structure,r.volume*.035,{area=r.length*r.width/32^2*(membrane and 3 or 1),control=.2+d[14]*.6,efficiency=.4+q[9]*.5,aX=host and host.x or r.x,aY=host and host.y or r.y,bX=r.x,bY=r.y});a.surfaces[#a.surfaces+1]=c end
  if r.partType=='lower_jaw' then local mouth=P.component(a,r,'Mouth',r.structure,r.volume*.01,{aperture=r.length/32*(.3+d[10]),capacity=r.volume*50,forceCoupling=.3+q[22]*.7});a.mouths[#a.mouths+1]=mouth;for k=1,2+math.floor(q[21]*4) do local pt=localPoint(r,r.length*(k/(3+math.floor(q[21]*4))-.5),0,r.thickness*.5);support(r,'tooth attachment',pt,r.volume*.008,r.structure,{pt,localPoint(r,pt.x-r.cx,0,r.thickness*.8)}) end end
 end
 for _,st in ipairs(a.structures) do st.children={} end;for _,st in ipairs(a.structures) do if st.parent then local parent=a.components[st.parent];parent.children[#parent.children+1]=st.id end end
 for _,j in ipairs(a.joints) do local parent,child=a.components[j.parent],a.components[j.child];parent.jointPoints[#parent.jointPoints+1]=j.id;child.jointPoints[#child.jointPoints+1]=j.id;for _,c in ipairs(a.components) do if c.regionId==j.partId and (c.type=='Muscle' or c.type=='Tendon') then j.supportingTissues[#j.supportingTissues+1]=c.id end end end
 for _,brain in ipairs(brains) do if brain~=brains[1] then a.nerves[#a.nerves+1]={from=brains[1].id,to=brain.id,efficiency=.4+e[22]*.5,condition=1} end end
 for _,o in ipairs(a.organs) do local r=a.regions[o.regionId];a.nerves[#a.nerves+1]={from=r.neuralNode,to=o.id,efficiency=.4+e[22]*.5,condition=1} end
 P.component(a,axis[1],'Stem',axis[1].structure,0,{density=.6,anatomicalName='persistent embryonic precursor'})
 a.axisAspect=axis[1].length*#axis/axis[1].thickness;a.width=axis[1].width/32;a.growthFactor=1/(1+#a.regions*.004+a.headCount*.03);a.exchangeMethod='genetic anatomical exchange';a.tissues={Stem=.1,Muscle=#a.muscles,Structural=#a.structures,Nerve=#a.nerves,Blood=#a.vessels,Epithelial=#a.skin,Adipose=#a.fat};a.operations={{operation='GENETIC_FRAMEWORK',region=1,detail=a.supportStrategy}}
 P.bounds(a);require('anatomical_development').initialize(a,g);return a
end
return F
