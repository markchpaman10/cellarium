local G=require('genome');local P=require('body_parts');local X=require('gene_expression');local F={}
local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function resize(r,length,width,height,cx,cy,cz,angle)
 r.length=length;r.width=width;r.thickness=height;r.cx=cx;r.cy=cy;r.cz=cz;r.x=cx;r.y=-cz;r.orientation=angle or 0;r.rx=length/2;r.ry=height/2;r.rz=width/2
 r.volume=4/3*math.pi*r.rx*r.ry*r.rz/P.pixelsPerInch^3*(r.shape=='taper' and .72 or r.shape=='foil' and .5 or 1);r.freeVolume=r.volume
end
function F.generate(g,conditions)
 local e=G.express(g);local d=e.development;local q=e.ecology;local a=P.new(g,conditions);a.parameters=d;a.ecology={genes=q,version=2};a.parts=a.regions
 local quality=clamp((conditions and conditions.nutrition or 1)*(1-math.abs((conditions and conditions.temperature or 37)-37)/40),.05,1.4)
 local sym=g.chromosomes[4].loci[2];local activity=X.value(g,4,2)
 a.symmetry=activity<.05 and 'asymmetric' or sym.a==sym.b and (sym.a==0 or sym.a==3) and 'radial' or math.abs(sym.a-sym.b)==3 and 'asymmetric' or 'bilateral'
 local size=.65+e[11]*.9;local height=(16+e[13]*15+d[2]*5)*size;local length=(28+e[12]*25+d[1]*12)*size;local width=height*(.65+d[2]*.4)
 local function add(kind,parent,cx,cy,cz,l,w,h,genes,extra)
  local props={cx=cx,cy=cy,cz=cz,length=l,width=w,thickness=h,genes=genes,curvature=(d[3]-.5)*.22,taper=.1+d[24]*.3}
  for k,v in pairs(extra or {}) do props[k]=v end
  return P.add(a,kind,parent,props)
 end
 local chest=add('chest',nil,0,0,0,length,width,height,{'L11','L12','L13','D1','D2','D3'})
 local initial=G.copy(chest);resize(chest,2,2,2,0,0,0,0);P.snapshot(a,'Initial developmental cell');a.regions[1]=initial;chest=initial;
 local torso={chest};local count=2+math.floor(d[5]*3)
 for i=2,count do local prev=torso[#torso];local kind=i==count and 'pelvis' or i==2 and 'abdomen' or 'trunk';local taper=1-(i-1)*.10
  torso[#torso+1]=add(kind,prev.id,prev.cx-prev.length*.58,0,(d[3]-.5)*height*.16*(i-1),length*.65,width*taper,height*taper,{'D5','D1','L12','D24'},{attachment={x=-prev.length*.4,y=0,z=0}})
 end
 a.operations[#a.operations+1]={operation='AXIS',region=1,detail=a.symmetry..' / differentiated axial regions'};P.snapshot(a,'Axis and body regions')
 for _,r in ipairs(torso) do P.support(a,r,e,d) end;P.snapshot(a,'Axial structural support')
 local signal=g.chromosomes[6].loci[2];local limbs
 if X.value(g,6,2)<.1 or e[14]<.08 then limbs=0
 elseif a.symmetry=='radial' then limbs=3+math.floor(d[18]*5.99)
 elseif a.symmetry=='asymmetric' then limbs=1+((signal.a+2*signal.b)%7)
 else limbs=2*clamp(math.floor(e[14]*3+.01)+(signal.a+2*signal.b)%3,1,5) end
 a.appendageCount=limbs;a.limbPairs=a.symmetry=='bilateral' and limbs/2 or 0
 local roots={};local segments=1+math.floor(d[10]*2.99)
 for i=1,limbs do
  local pair=a.symmetry=='bilateral' and math.floor((i-1)/2) or i-1;local host=torso[1+(pair%#torso)];local side=i%2==0 and 1 or -1
  local angle=a.symmetry=='radial' and (i/limbs*math.pi*2) or -math.pi/2+(d[7]-.5)*.5+(pair%2==0 and .32 or -.3)
  local start={x=host.cx+(pair%2==0 and .18 or -.18)*host.length,y=side*host.width*.4,z=-host.thickness*.25}
  if a.symmetry=='radial' then start={x=chest.cx+math.cos(angle)*chest.length*.25,y=math.sin(angle)*chest.width*.4,z=-height*.15} end
  local bud=add('segment',host.id,start.x,start.y,start.z,2,2,2,{'L14','D6','D7','D8','D9'},{appendage=true,depth=1,root=host.id,start=G.copy(start),attachment={x=start.x-host.cx,y=start.y-host.cy,z=start.z-host.cz},side=side,pathIndex=1,jointed=d[10]>.15})
  roots[#roots+1]={bud=bud,host=host,start=start,side=side,angle=angle,regions={bud.id},index=i};a.operations[#a.operations+1]={operation='BUD',region=bud.id,parent=host.id,detail='anatomical socket'}
 end
 P.snapshot(a,'Appendage buds at attachment sockets')
 for _,root in ipairs(roots) do
  local parent=root.host;local start=G.copy(root.start)
  for segment=1,segments do
   local len=(14+d[8]*23)*size*(segment==1 and 1 or segment==2 and .86 or .4);local girth=(4+d[9]*8+e[16]*2)*size*(1-(segment-1)*.2)
   local angle=root.angle+(segment==2 and .65 or segment==3 and -.6 or 0)*(root.index%2==0 and 1 or -1)
   local finish={x=start.x+math.cos(angle)*len,y=start.y,z=start.z+math.sin(angle)*len}
   if a.symmetry=='radial' then finish={x=start.x+math.cos(root.angle)*len,y=start.y+math.sin(root.angle)*len,z=start.z-len*.16} end
   local r
   if segment==1 then r=root.bud;resize(r,len,girth,girth,(start.x+finish.x)/2,(start.y+finish.y)/2,(start.z+finish.z)/2,math.atan2(-(finish.z-start.z),finish.x-start.x))
   else r=add('segment',parent.id,(start.x+finish.x)/2,(start.y+finish.y)/2,(start.z+finish.z)/2,len,girth,girth,{'D8','D9','D10','L15','L16'},{appendage=true,depth=1,side=root.side,pathIndex=segment,jointed=d[10]>.15,orientation=math.atan2(-(finish.z-start.z),finish.x-start.x)});root.regions[#root.regions+1]=r.id end
   r.start=G.copy(start);r.finish=G.copy(finish);r.root=root.host.id;r.attachment={x=start.x-parent.cx,y=start.y-parent.cy,z=start.z-parent.cz};P.support(a,r,e,d)
   parent=r;start=finish
  end
  root.tip=parent;root.finish=start;a.appendages[#a.appendages+1]={root=root.host.id,regions=G.copy(root.regions),depth=1,side=root.side,angle=root.angle,functionType='articulated appendage'}
 end
 P.snapshot(a,'Elongated differentiated segments')
 for _,root in ipairs(roots) do
  for _,id in ipairs(root.regions) do local r=a.regions[id];local host=a.regions[r.parent]
   if r.jointed then a.joints[#a.joints+1]={id=#a.joints+1,parent=host.structure,child=r.structure,partId=r.id,type=d[11]>.4 and 'hinge' or 'flexure',minimum=-.3-d[10]*.8,maximum=.3+d[10]*1.3,rest=r.orientation,range=.6+d[10]*2.1,mobility=.25+e[3]*.65,stability=.4+e[15]*.5,strength=a.components[r.structure].strength,condition=1,x=r.start.x,y=-r.start.z,cx=r.start.x,cy=r.start.y,cz=r.start.z} end
  end
  local kind=q[9]>.65 and 'fin' or q[14]>.7 and 'hoof' or q[21]>.8 and d[10]>.65 and 'hook' or q[21]>.65 and 'claw' or 'pad';local digits=kind=='pad' and e[3]>.5 and 2 or 1
  for finger=1,digits do local f=root.finish;local tip=add(digits>1 and 'digit' or kind,root.tip.id,f.x+5*size,f.y+(finger-(digits+1)/2)*5*size,f.z,10*size,5*size,3.5*size,{'L3','D10','E9','E14','E21'},{appendage=true,depth=1,side=root.side,pathIndex=segments+1,terminal=kind,attachment={x=f.x-root.tip.cx,y=f.y-root.tip.cy,z=f.z-root.tip.cz}});P.support(a,tip,e,d);tip.start=G.copy(f);tip.finish={x=f.x+10*size,y=tip.cy,z=f.z}
   if kind=='fin' then local c=P.component(a,tip,'Fin',tip.structure,tip.volume*.15,{area=tip.length*tip.width/32^2,efficiency=.4+q[9]*.5});a.surfaces[#a.surfaces+1]=c end
  end
 end
 P.snapshot(a,'Joints and distal adaptations')
 local sensory=g.chromosomes[14].loci[2];local headSignal=(math.floor(d[14]*8+d[23]*3)+(sensory.a-sensory.b))%8
 local heads=X.value(g,14,2)<.05 and 0 or headSignal==0 and 0 or headSignal<=4 and 1 or headSignal<=6 and 2 or 3
 a.headCount=heads;local crania={}
 for i=1,heads do
  local spread=(i-(heads+1)/2);local neckLength=(8+d[13]*16)*size;local neck=add('neck',chest.id,chest.cx+chest.length*.5+neckLength*.35,spread*width*.8,height*.08+spread*height*.72,neckLength,width*.35,height*.42,{'D13','D14','D23','L22'},{attachment={x=chest.rx*.8,y=spread*width*.5,z=height*.08}});P.support(a,neck,e,d)
  local head=add('cranium',neck.id,neck.cx+neckLength*.5+12*size,neck.cy,neck.cz+2*size,(20+e[4]*13)*size,(15+d[14]*11)*size,(17+e[22]*9)*size,{'L4','L22','D14','D23'},{headIndex=i,attachment={x=neck.length*.4,y=0,z=0}});P.support(a,head,e,d);crania[#crania+1]=head
  local snout=add('snout',head.id,head.cx+head.length*.48+7*size,head.cy,head.cz-4*size,(10+q[22]*14)*size,head.width*.56,head.thickness*.45,{'E22','D1','D13'},{attachment={x=head.rx*.8,y=0,z=-head.ry*.25},taper=.7});P.support(a,snout,e,d)
  for jaw=1,2 do local r=add(jaw==1 and 'upper_jaw' or 'lower_jaw',snout.id,snout.cx+3*size,snout.cy,snout.cz+(jaw==1 and 2 or -3)*size,snout.length*.85,snout.width*.7,snout.thickness*.28,{'E22','L2','L3'},{jaw=true,headIndex=i,attachment={x=-snout.rx*.3,y=0,z=jaw==1 and 2 or -3}});P.support(a,r,e,d)
   if jaw==2 then a.joints[#a.joints+1]={id=#a.joints+1,parent=snout.structure,child=r.structure,partId=r.id,type='jaw hinge',minimum=0,maximum=.25+q[22]*.65,range=.25+q[22]*.65,mobility=.4+e[3]*.5,stability=.8,strength=a.components[r.structure].strength,condition=1,cx=r.cx-r.length*.4,cy=r.cy,cz=r.cz,x=r.cx-r.length*.4,y=-r.cz} end
  end
 end
 if d[1]+d[24]>.75 then local prev=torso[#torso];for i=1,1+math.floor(d[1]*3) do local tail=add('tail',prev.id,prev.cx-prev.length*.5-8*size,prev.cy,prev.cz+size*(d[3]-.5)*i,18*size,(9-i*1.5)*size,(9-i*1.5)*size,{'D1','D3','D24'},{attachment={x=-prev.rx*.8,y=0,z=0},taper=.7,appendage=true,depth=1});P.support(a,tail,e,d);prev=tail end end
 if q[20]>.7 then local host=crania[1] or chest;local kind=q[21]>.65 and 'spike' or 'horn';local part=add(kind,host.id,host.cx,host.cy,host.cz+host.thickness*.5+6*size,12*size,4*size,4*size,{'E20','E21','E14','E15'},{orientation=-math.pi/2,attachment={x=0,y=0,z=host.ry},taper=.8});P.support(a,part,e,d);local c=P.component(a,part,'Projection',part.structure,part.volume*.3,{length=12*size,width=4*size,hardness=q[15],sharpness=q[21],strength=a.components[part.structure].strength,attachmentStrength=a.components[host.structure].strength,role=kind,geometryAngle=-math.pi/2,growthCost=.1});a.projections[#a.projections+1]=c end
 if q[23]>.58 then local host=crania[1] or chest;for side=-1,1,2 do local r=add('antenna',host.id,host.cx+host.rx*.2,host.cy+side*host.rz*.6,host.cz+host.ry+7*size,18*size,2*size,2*size,{'E23','L22'},{orientation=-1.1,attachment={x=host.rx*.2,y=side*host.rz*.6,z=host.ry},taper=.8});P.support(a,r,e,d) end end
 P.snapshot(a,'Head-bearing, jaw and tail structures')
 -- Pack organs into real 3-D host cavities. A failed placement is a biological
 -- failure, not permission to put an organ outside the body or substitute a blob.
 local occupied={}
 local function organ(kind,host,slot,locus,scale)
  local radius=math.min(host.rx,host.ry,host.rz)*(.23+e[locus]*.08);local volume=4/3*math.pi*(radius/32)^3
  local positions={{-.25,0,.10},{.28,0,.08},{0,0,-.28},{0,.35,.1},{0,-.35,.1},{0,0,.34}}
  for offset=0,#positions-1 do local p=positions[1+(slot+offset-1)%#positions];local cx,cy,cz=host.cx+p[1]*host.rx,host.cy+p[2]*host.rz,host.cz+p[3]*host.ry;local fit=volume<=host.freeVolume
   for _,other in ipairs(occupied) do if other.regionId==host.id and (cx-other.cx)^2+(cy-other.cy)^2+(cz-other.cz)^2<(radius+other.rx)^2 then fit=false end end
   if fit then local capacity=volume*(scale or 40)*(.4+e[locus]*.6)*quality;local c=P.component(a,host,kind,host.structure,volume,{x=cx,y=-cz,cx=cx,cy=cy,cz=cz,rx=radius,ry=radius,rz=radius,capacity=capacity,efficiency=.45+e[locus]*.5,wasteCapacity=kind=='Stomach' and capacity*.3 or 0,airExchange=kind=='Lung' and capacity*(.2+q[1]*1.8) or nil,anatomicalHost=host.uid});a.organs[#a.organs+1]=c;occupied[#occupied+1]=c;return c end
  end;a.placementFailures[#a.placementFailures+1]='No suitable cavity for '..kind..' in '..host.uid;return nil
 end
 local hearts={};local brains={};local multiplicity=d[22]>.7 and 2 or 1
 for i=1,multiplicity do local host=torso[1+(i-1)%#torso];local h=organ('Heart',host,1,19,120);if h then hearts[#hearts+1]=h end;organ('Lung',host,2,20,160);organ('Stomach',torso[math.min(#torso,i+1)],1,21,120) end
 for i=1,math.max(1,heads) do local host=crania[i] or chest;local brain=organ('Brain',host,heads==0 and 3 or 1,22,90);if brain then brain.distributed=heads==0;brains[#brains+1]=brain end end
 P.snapshot(a,'Protected organ placement')
 for _,r in ipairs(a.regions) do
  local support=a.components[r.structure];local parent=r.parent and a.regions[r.parent];local origin=parent and parent.structure
  -- Root muscles span two distinct supports, not self-to-self attachments.
  if not origin then origin=torso[2] and torso[2].structure end
  if origin then local volume=math.min(r.freeVolume*.55,r.volume*(.18+e[16]*.22));local c=P.component(a,r,'Muscle',r.structure,volume,{origin=origin,insertion=r.structure,density=.55+e[16]*.15,force=(.8+e[2]*1.8),fiberQuality=.35+e[2]*.6,efficiency=.4+e[3]*.5,leverage=(r.kind=='appendage' and .5+d[10]*.5 or .7),energyCost=.1+e[1]*.2,fatigue=0});a.muscles[#a.muscles+1]=c end
  P.component(a,r,'Tendon',r.structure,r.volume*.025,{origin=origin or r.structure,insertion=r.structure,strength=support.strength*.7})
  local nerve=P.component(a,r,'Nerve',r.structure,r.volume*(.01+e[22]*.015),{capacity=.25+e[22]*.7,efficiency=.3+e[22]*.6});r.neuralNode=nerve.id
  local brain=brains[1];if brain then a.nerves[#a.nerves+1]={from=brain.id,to=nerve.id,efficiency=nerve.efficiency,condition=1} end
  a.nerves[#a.nerves+1]={from=nerve.id,to=r.structure,efficiency=nerve.efficiency,condition=1}
  if hearts[1] then a.vessels[#a.vessels+1]={from=hearts[1].id,to=r.structure,capacity=hearts[1].capacity,condition=1} end
 end
 for _,brain in ipairs(brains) do if brains[1] and brain~=brains[1] then a.nerves[#a.nerves+1]={from=brains[1].id,to=brain.id,efficiency=.4+e[22]*.5,condition=1} end end
 for _,head in ipairs(#crania>0 and crania or {chest}) do
  for side=-1,1,2 do local volume=math.min(head.freeVolume*.05,.001);local sensor=P.component(a,head,'Sensor',head.structure,volume,{x=head.cx+head.rx*.45,y=-head.cz-head.ry*.18,cx=head.cx+head.rx*.45,cy=head.cy+side*head.rz*.65,cz=head.cz+head.ry*.18,rx=1.5,ry=1.5,rz=1.5,acuity=.3+e.perception*.65,socket='orbital',functionType='Light / chemical sensing'});a.sensors[#a.sensors+1]=sensor
   local brain=brains[head.headIndex or 1] or brains[1];if brain then a.nerves[#a.nerves+1]={from=brain.id,to=sensor.id,efficiency=.4+e[22]*.5,condition=1} end
  end
 end
 for _,stomach in ipairs(a.organs) do if stomach.type=='Stomach' then local host=crania[1] or chest;local mouth=P.component(a,host,'Mouth',host.structure,math.min(.001,host.freeVolume*.05),{x=host.cx+host.rx*.85,y=-host.cz+host.ry*.2,cx=host.cx+host.rx*.85,cy=host.cy,cz=host.cz-host.ry*.2,rx=2,ry=1,rz=1,capacity=stomach.capacity,aperture=2+q[22]*3,forceCoupling=.3+q[22]*.7});a.mouths[#a.mouths+1]=mouth end end
 P.snapshot(a,'Muscle, connective and nervous integration')
 for _,r in ipairs(a.regions) do
  local volume=math.min(r.freeVolume*.35,r.volume*(.02+e[17]*.10));if volume>0 then local fat=P.component(a,r,'Fat',r.structure,volume,{capacity=volume*30,insulation=.2+e[17]*.5});a.fat[#a.fat+1]=fat end
  local regional=r.partType=='abdomen' and .55 or r.partType=='chest' and 1.2 or 1;local armor=(.2+q[14]*.4+q[15]*.4)*q[18]*regional
  for _,surface in ipairs({'dorsal','ventral'}) do local thickness=(.1+e[18]*.4+q[18]*.3)*(surface=='ventral' and .55 or 1)
   local skin=P.component(a,r,'Skin',r.structure,math.min(r.freeVolume*.35,r.volume*(.02+thickness*.05)),{surface=surface,thickness=thickness,toughness=.25+e[18]*.6,hardness=.25+q[14]*.35+q[15]*.4,armor=armor*(surface=='ventral' and .4 or 1),flexibility=.3+q[16]*.6,rigidity=q[15]*(1-q[16]*.6),covering=armor>.5 and 'plates' or q[14]>.6 and 'scales' or 'soft skin',exchange=r.volume*(1-thickness)*(.4+q[1]*.6)*4,wasteCapacity=r.volume*.5,regeneration=.02+q[19]*.1});a.skin[#a.skin+1]=skin
  end
  if q[2]>.5 and r.kind=='axis' then local gi=P.component(a,r,'Gill',r.structure,math.min(r.freeVolume*.1,r.volume*.025),{capacity=r.volume*(.3+q[2])*15,efficiency=.4+q[3]*.6,ventilation=.3+q[9]*.7,area=r.length*r.width/32^2,rx=r.rx*.35,ry=2,rz=r.rz*.5});a.gills[#a.gills+1]=gi end
  r.growth=1;r.stage='mature';a.operations[#a.operations+1]={operation='DIFFERENTIATE',region=r.id,parent=r.parent,detail='anatomical tissue allocation'}
 end
 -- Optional membranes and sensory/protective extensions are genetic structures,
 -- not random decorative noise. Their tissue mass belongs to their host budget.
 if q[10]>.7 and #roots>=2 then for i=1,math.min(4,#roots) do local r=roots[i].bud;local c=P.component(a,r,'Membrane',r.structure,math.min(r.freeVolume*.1,.005),{area=r.length*width/32^2,control=.2+d[14]*.6,aX=chest.x,aY=chest.y,bX=r.x,bY=r.y,rx=r.rx,ry=width*.5});a.surfaces[#a.surfaces+1]=c end end

 P.snapshot(a,'Fat, skin and regional protective tissues')
 a.segments=#torso;a.width=width/32;a.axisAspect=length*#torso/height;a.tissues={Stem=.1,Muscle=#a.muscles,Structural=#a.structures,Nerve=#a.nerves,Blood=#a.vessels,Epithelial=#a.skin,Adipose=#a.fat};a.exchangeMethod='mixed anatomical exchange';a.growthFactor=1/(1+(#a.regions*.006)+heads*.03)
 a.massLedger={volume=0,tissueVolume=0,mass=0};for _,r in ipairs(a.regions) do a.massLedger.volume=a.massLedger.volume+r.volume end;for _,c in ipairs(a.components) do a.massLedger.tissueVolume=a.massLedger.tissueVolume+c.volume;a.massLedger.mass=a.massLedger.mass+c.mass end
 P.bounds(a);P.snapshot(a,'Mature anatomical construction');return a
end
return F
