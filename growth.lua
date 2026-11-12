local G=require('genome');local DG=require('development_genes');local F={}
local pi=math.pi
function F.generate(genome,conditions)
 local e=G.express(genome);local d=DG.expression(genome);local rand=G.rng((G.hash(genome)+719)%2147483647)
 local a={version=3,generator='developmental-growth',regions={},operations={},components={},structures={},bones={},joints={},muscles={},organs={},skin={},fat={},sensors={},nerves={},vessels={},symmetry=d.symmetry,parameters=d,pigment=e[23],development=G.copy(conditions or {temperature=37,nutrition=1}),placementFailures={},appendages={},limits={regions=64,components=600,depth=2},budget=d.budget}
 local quality=math.min(1,a.development.nutrition or 1)*math.max(.12,1-math.abs((a.development.temperature or 37)-37)/30)
 local function op(name,id,parent,detail) a.operations[#a.operations+1]={operation=name,region=id,parent=parent,detail=detail} end
 local function region(parent,x,y,rx,ry,angle,kind,depth)
  if #a.regions>=a.budget or #a.regions>=a.limits.regions then op('TERMINATE',parent,parent,'Growth budget reached');return nil end
  local r={id=#a.regions+1,parent=parent,x=x,y=y,rx=rx,ry=ry,orientation=angle,kind=kind,depth=depth or 0,connections={},growthPotential=math.max(0,a.budget-#a.regions-1),tissues={muscle=.2+e[16]*.45+d[12]*.2,structural=.12+d[11]*.35,skin=.15+e[18]*.15,fat=.02+e[17]*.2,nerve=.02+e[22]*.08}}
  a.regions[#a.regions+1]=r;if parent then r.connections[#r.connections+1]=parent;local p=a.regions[parent];p.connections[#p.connections+1]=r.id end;op(parent and 'GROW' or 'DIVIDE',r.id,parent,kind);return r
 end
 local size=.75+e[11]*.65;local width=(5+d[2]*13)*size*(.7+e[13]*.6);local step=(4+d[1]*14)*(.8+e[12]*.4)*size;local curvature=(d[3]-.5)*1.65;local orient=(d[19]-.5)*1.3
 local root=region(nil,0,0,width*(d.symmetry=='radial' and 1 or (1.1-d[1]*.35)),width,orient,'axis',0)
 local axis={root};local axisCount=d.segments
 local radialOrder=3+math.floor(d[18]*5+.01);local radialAxisLength=0
 local function extendAxis(parent,angle,count,radial)
  for k=1,count do local p=a.regions[parent];local theta=angle+(radial and 0 or curvature*k/math.max(1,count));local progress=k/math.max(1,count);local taper=radial and (.74+.22*math.sin(progress*pi)) or (.38+.64*math.sin((progress*.82+.08)*pi))*(1-.26*progress);local r=region(parent,p.x+math.cos(theta)*step,p.y+math.sin(theta)*step,width*(.7+d[1]*.25)*taper,width*(.65+d[2]*.35)*taper,theta,'axis',0);if not r then break end;axis[#axis+1]=r;parent=r.id;op('DIVIDE',r.id,r.parent,'Axis segmentation') end
 end
 if d.symmetry=='radial' then
  local count=math.min(math.floor((axisCount-1)/3),math.floor((a.budget-1)/(radialOrder*2)));radialAxisLength=count
  for spoke=1,radialOrder do op('MIRROR',root.id,root.id,'Rotational copy '..spoke..'/'..radialOrder);extendAxis(root.id,orient+spoke/radialOrder*2*pi,count,true) end
 else extendAxis(root.id,orient,axisCount-1,false) end
 local branchRoots=d.branchRoots==0 and 0 or (1+math.floor((d[6]-1/3)*3+e[14]*1.5))
 local branchSegmentLimit=4;local recursionAllowed=true
 local function branch(host,angle,depth,lengthScale,mirrorGroup,bendSign)
  bendSign=bendSign or 1
  local p=a.regions[host];local segments=math.min(branchSegmentLimit,1+math.floor(d[8]*3+.01));local radius=math.max(1.8,(2+d[9]*5)*size*(depth==2 and .65 or 1));local parent=host;local path={};op('BRANCH',host,host,'Depth '..depth)
  for k=1,segments do
   local prev=a.regions[parent];local length=(5+d[8]*14)*size*lengthScale;local theta=angle+(d[3]-.5)*k*.35*bendSign
   local start=k==1 and math.max(p.rx,p.ry)*.65 or 0
   local r=region(parent,prev.x+math.cos(theta)*(length+start),prev.y+math.sin(theta)*(length+start),radius*(1-k/(segments+1)*.65),radius*(.8+d[9]*.3)*(1-k/(segments+1)*.52),theta,'appendage',depth)
   if not r then break end;r.mirrorGroup=mirrorGroup;r.pathIndex=k;r.jointed=k<=d.joints;r.root=host;path[#path+1]=r.id;parent=r.id
  end
  if #path>0 then a.appendages[#a.appendages+1]={root=host,regions=path,depth=depth,angle=angle,mirrorGroup=mirrorGroup};local tip=a.regions[path[#path]]
   if recursionAllowed and depth<d.branchDepth and #a.regions+3<a.budget then branch(tip.id,angle-.65,depth+1,.65,mirrorGroup,bendSign);branch(tip.id,angle+.65,depth+1,.65,mirrorGroup,bendSign) end
   op('TERMINATE',tip.id,host,'Genetic extension limit')
  end
 end
 if branchRoots>0 then
  if d.symmetry=='radial' then
   local available=a.budget-#a.regions;local desired=1+math.floor(d[8]*3+.01);recursionAllowed=available>=radialOrder*desired*3;branchSegmentLimit=math.min(desired,math.floor(available/(radialOrder*(recursionAllowed and 3 or 1))))
   if branchSegmentLimit>=1 then for spoke=1,radialOrder do local offset=math.floor(radialAxisLength*d[7]);local host=axis[offset==0 and 1 or 1+(spoke-1)*radialAxisLength+offset].id;local angle=orient+spoke/radialOrder*2*pi;op('MIRROR',host,host,'Radial branching '..spoke);branch(host,angle,1,.7+d[8]*.5,spoke) end end
  else
   for k=1,branchRoots do local idx=1+math.floor(((k-1+d[7])/(branchRoots+.01))*(#axis-1));idx=math.min(#axis,idx);local host=axis[idx];local theta=host.orientation+pi*(.25+d[7]*.5)
    if d.symmetry=='bilateral' then local available=a.budget-#a.regions;local desired=1+math.floor(d[8]*3+.01);recursionAllowed=available>=desired*6;branchSegmentLimit=math.min(desired,math.floor(available/(2*(recursionAllowed and 3 or 1))));if branchSegmentLimit>=1 then op('MIRROR',host.id,host.id,'Paired branch');branch(host.id,theta,1,1,k,1);branch(host.id,host.orientation-(theta-host.orientation),1,1,k,-1) end
    else branchSegmentLimit=4;recursionAllowed=true; branch(host.id,theta+math.sin(k*2.399+d[7]*math.pi*2)*.9,1,.65+(math.sin(k*1.71+d[8]*3)*.5+.5)*.7,k) end
   end
  end
 end
 -- Center the grown graph; no renderer-specific grid is involved.
 local minx,miny,maxx,maxy=1e9,1e9,-1e9,-1e9
 for _,r in ipairs(a.regions) do minx=math.min(minx,r.x-r.rx);maxx=math.max(maxx,r.x+r.rx);miny=math.min(miny,r.y-r.ry);maxy=math.max(maxy,r.y+r.ry) end
 local cx,cy=(minx+maxx)/2,(miny+maxy)/2
 for _,r in ipairs(a.regions) do r.x=r.x-cx;r.y=r.y-cy end
 a.bounds={minx=minx-cx-3,miny=miny-cy-3,maxx=maxx-cx+3,maxy=maxy-cy+3};a.bounds.width=a.bounds.maxx-a.bounds.minx;a.bounds.height=a.bounds.maxy-a.bounds.miny
 local function add(kind,r,parent,properties)
  local c={id=#a.components+1,type=kind,regionId=r.id,x=r.x,y=r.y,rx=r.rx,ry=r.ry,size=2*math.sqrt(r.rx*r.ry),orientation=r.orientation,parent=parent,condition=1,mass=.1,region=r.kind=='appendage' and 'limb' or 'torso'};for k,v in pairs(properties or {}) do c[k]=v end;a.components[#a.components+1]=c;return c
 end
 for _,r in ipairs(a.regions) do
  local parent=r.parent and a.regions[r.parent].structure;local area=pi*r.rx*r.ry/100;local rigidity=d[11]*(.6+e[15]*.4);local kind=rigidity>=.52 and 'Bone' or d[20]>.75 and 'Carapace' or 'Support'
  local st=add(kind,r,parent,{length=r.parent and math.sqrt((r.x-a.regions[r.parent].x)^2+(r.y-a.regions[r.parent].y)^2) or r.rx*2,thickness=1+e[15]*r.ry*.3,density=.4+rigidity,strength=(.8+e[15]*2)*area^.65*quality,mass=area*(.12+rigidity*.16),flexibility=1-rigidity,rigidity=rigidity,jointPoints={r.parent,r.id}})
  a.structures[#a.structures+1]=st;if kind=='Bone' then a.bones[#a.bones+1]=st end;r.structure=st.id
  if parent and r.jointed then a.joints[#a.joints+1]={id=#a.joints+1,parent=parent,child=st.id,type=rigidity>.5 and 'hinge' or 'flexure',range=.4+e[3],stability=.4+e[15]*.4,strength=st.strength,mobility=.4+e[3]*.6,condition=1} end
  local muscleScale=r.kind=='appendage' and (.5+d[21]) or (1.5-d[21]*.6)
  local m=add('Muscle',r,st.id,{origin=parent or st.id,insertion=st.id,mass=area*r.tissues.muscle*muscleScale*quality,force=(.6+e[2]*2)*(.7+e[1]*.3),efficiency=.5+e[3]*.5,energyCost=.1+e[1]*.2,fatigue=0,contraction=1-rigidity*.7});a.muscles[#a.muscles+1]=m
  if e[17]>.1 then local f=add('Fat',r,st.id,{mass=area*r.tissues.fat,capacity=area*(1+e[17]*5),insulation=.2+e[17]*.8});a.fat[#a.fat+1]=f end
  local skin=add('Skin',r,st.id,{mass=area*(.04+e[18]*.05),thickness=.5+e[18]*3,toughness=.2+e[18]*.8,flexibility=1-e[18]*.4,texture=d[15],regeneration=.02+e[6]*.05,exchange=(1-rigidity)*area*(1-e[18]*.65)*.22*quality,wasteCapacity=area*.04*quality});a.skin[#a.skin+1]=skin
  op('DIFFERENTIATE',r.id,r.parent,kind..' / muscle / covering');op('CONNECT',r.id,r.parent,'Structural attachment')
 end
 local occupied={};local hosts={};for _,r in ipairs(axis) do hosts[#hosts+1]=r end
 table.sort(hosts,function(x,y) local sx=x.rx*x.ry*(.4+d[13])+x.id*(d[13]-.5);local sy=y.rx*y.ry*(.4+d[13])+y.id*(d[13]-.5);return sx>sy end)
 local function place(kind,locus,capacityScale,serial)
  for offset=1,#hosts do local host=hosts[1+(offset+serial-2)%#hosts];local radius=math.min(3.7,math.max(1.3,math.min(host.rx,host.ry)*(.21+e[locus]*.055)))
   for attempt=0,24 do local theta=attempt*2.399+d[13]*pi*2;local rad=attempt==0 and 0 or .65*math.sqrt(attempt/24);local ux,uy=math.cos(theta)*host.rx*rad,math.sin(theta)*host.ry*rad;local ca,sa=math.cos(host.orientation),math.sin(host.orientation);local x=host.x+ux*ca-uy*sa;local y=host.y+ux*sa+uy*ca;local fits=true
    for _,o in ipairs(occupied) do if (x-o.x)^2+(y-o.y)^2<(radius+o.rx+.35)^2 then fits=false;break end end
    if fits and (ux/(host.rx-radius))^2+(uy/(host.ry-radius))^2<.99 then
     local o=add(kind,host,host.structure,{x=x,y=y,rx=radius,ry=radius,size=radius*2,mass=radius*radius*.025,capacity=(.3+e[locus])*capacityScale*radius*radius/7*quality,efficiency=.45+e[locus]*.55,tissue=kind=='Brain' and 'Nerve' or kind=='Stomach' and 'Digestive epithelium' or 'Blood / epithelium',wasteCapacity=kind=='Stomach' and radius*.22*quality or 0});a.organs[#a.organs+1]=o;occupied[#occupied+1]=o;return o
    end
   end
  end
  a.placementFailures[#a.placementFailures+1]='No protected cavity for '..kind;return nil
 end
 local copies=1+math.floor(d[22]*2+.01)
 for i=1,copies do place('Heart',19,5.8,i);place('Stomach',21,4.5,i+1);place('Brain',22,3,i+2) end
 a.exchangeMethod=d[11]<.34 and e[18]<.8 and 'cutaneous' or 'lung'
 if a.exchangeMethod=='lung' then for i=1,1+math.floor(d[22]*3+.01) do place('Lung',20,6,i+3) end end
 local hearts,brains={},{};for _,o in ipairs(a.organs) do if o.type=='Heart' then hearts[#hearts+1]=o elseif o.type=='Brain' then brains[#brains+1]=o end end
 local function nearest(list,r) local best,dist;for _,c in ipairs(list) do local delta=(c.x-r.x)^2+(c.y-r.y)^2;if not dist or delta<dist then best=c;dist=delta end end;return best,math.sqrt(dist or 0) end
 for _,r in ipairs(a.regions) do local heart,distance=nearest(hearts,r);local brain,nd=nearest(brains,r)
  if heart then a.vessels[#a.vessels+1]={from=heart.id,to=r.structure,capacity=heart.capacity/(1+distance*.02),condition=1} end
  if brain then a.nerves[#a.nerves+1]={from=brain.id,to=r.structure,efficiency=(.3+e[22]*.7)/(1+nd*.006),condition=1} end;op('CONNECT',r.id,r.parent,'Vascular and neural paths')
 end
 local sensorCount=1+math.floor(d[14]*7+.01);if d.symmetry=='radial' then sensorCount=radialOrder*(1+math.floor(d[14]+.01)) elseif d.symmetry=='bilateral' then sensorCount=2*math.ceil(sensorCount/2) end
 for i=1,sensorCount do local idx=1+math.floor((i-1)/sensorCount*(#axis-1));if d.symmetry=='radial' then idx=1 elseif d.symmetry=='bilateral' then idx=1+math.floor(math.floor((i-1)/2)/(sensorCount/2)*(#axis-1)) end;local host=axis[idx];local theta=d.symmetry=='radial' and i/sensorCount*2*pi or d.symmetry=='bilateral' and ((i%2==0 and 1 or -1)*(.4+d[23]*1.4)+host.orientation) or d[23]*pi*2+i*2.399
  local sensor=add('Sensor',host,host.structure,{x=host.x+math.cos(theta)*host.rx*.88,y=host.y+math.sin(theta)*host.ry*.88,rx=1.4,ry=1.4,size=2.8,mass=.015,acuity=(.3+e.perception*.7),functionType='Light / chemical sensing'});a.sensors[#a.sensors+1]=sensor
 end
 for _,p in ipairs(a.appendages) do local tip=a.regions[p.regions[#p.regions]];p.functionType=(d[11]>.4 and d.joints>0) and 'jointed propulsion' or d[12]>.4 and 'contractile propulsion' or d[14]>.6 and 'sensory extension' or 'flexible support';tip.functionType=p.functionType end
 a.segments=#axis;a.width=2*width/16;a.limbPairs=d.symmetry=='bilateral' and math.floor(#a.appendages/2) or 0;a.appendageCount=#a.appendages;a.axisAspect=(axisCount*step)/(width*2);a.tissues={Stem=.1*(1+e[6]),Muscle=#a.muscles,Blood=#a.vessels,Nerve=#a.nerves,Epithelial=#a.skin,Structural=#a.structures,Adipose=#a.fat}
 for _,r in ipairs(a.regions) do op('TERMINATE',r.id,r.parent,'Differentiation complete') end
 return a
end
return F
