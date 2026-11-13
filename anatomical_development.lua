-- Persistent current structures + immutable genetically expressed target geometry.
-- Seeking and elapsed-time development evaluate the same biological state law.
local G=require('genome');local P=require('body_parts');local D={}
local function smooth(x) x=math.max(0,math.min(1,x));return x*x*(3-2*x) end
local function phase(t,b,e) return smooth((t-b)/math.max(.0001,e-b)) end
local function stage(r)
 if not r.parent then return .22 end
 if r.partType=='digit' or r.partType=='claw' or r.partType=='hoof' then return .58 end
 if r.partType=='cranium' then return .37 end
 if r.partType=='neck' then return .34 end
 if r.partType=='snout' or r.partType=='upper_jaw' or r.partType=='lower_jaw' then return .49 end
 if r.kind=='appendage' then return .40 end
 if r.partType=='tail' then return .48 end
 return .28
end
function D.initialize(a,g)
 local e=G.express(g);local model={version=1,progress=1,elapsed=0,duration=45+60*(1-e[6])+a.headCount*4,embryonicFraction=.64,fatFraction=.7,regions=G.copy(a.regions),components=G.copy(a.components),nerveTargets=G.copy(a.nerves),jointTargets=G.copy(a.joints),environment=G.copy(a.development)}
 for _,r in ipairs(model.regions) do local parent=r.parent and model.regions[r.parent];r.activation=math.min(.78,math.max(stage(r),parent and parent.activation+.055 or 0));r.completion=math.min(1,.88+(r.kind=='appendage' and .12 or .08));r.geneticGrowthPotential=1;r.targetSize={length=r.length,width=r.width,thickness=r.thickness} end
 a.growthModel=model;a.snapshots={};a.growth=1;D.setProgress(a,1,{fatFraction=1})
end
function D.setProgress(a,t,environment)
 local m=assert(a.growthModel);t=math.max(0,math.min(1,t));m.progress=t;m.elapsed=t*m.duration;a.growth=t;m.fatFraction=environment and environment.fatFraction or m.fatFraction or .7
 for i,r in ipairs(a.regions) do
  local target=m.regions[i];local growth=phase(t,target.activation,target.completion);local lengthGrowth=growth^.85;local widthGrowth=growth^1.10
  r.activation=target.activation;r.growth=growth;r.growthProgress=growth;r.targetSize=target.targetSize;r.currentSize={length=target.length*lengthGrowth,width=target.width*widthGrowth,thickness=target.thickness*widthGrowth};r.geneticGrowthPotential=target.geneticGrowthPotential;r.tissueMaturity=phase(t,target.activation+.06,1);r.functionalMaturity=phase(t,target.activation+.16,.95);r.stage=growth==0 and 'latent precursor' or growth<.15 and 'bud' or growth<1 and 'growing' or 'mature'
  r.length,r.width,r.thickness=r.currentSize.length,r.currentSize.width,r.currentSize.thickness;if not r.parent then r.length=2+(target.length-2)*lengthGrowth;r.width=2+(target.width-2)*widthGrowth;r.thickness=2+(target.thickness-2)*widthGrowth;r.currentSize={length=r.length,width=r.width,thickness=r.thickness} end;r.rx,r.ry,r.rz=r.length/2,r.thickness/2,r.width/2;r.volume=target.volume*(r.length/target.length)*(r.width/target.width)*(r.thickness/target.thickness);r.freeVolume=r.volume;r.tissues={}
  if r.parent then local p=a.regions[r.parent];local tp=m.regions[r.parent];local at=target.attachment;local px=p.length/math.max(.000001,tp.length);local py=p.width/math.max(.000001,tp.width);local pz=p.thickness/math.max(.000001,tp.thickness);r.attachment={x=at.x*px,y=at.y*py,z=at.z*pz}
   r.cx=p.cx+r.attachment.x+(target.cx-tp.cx-at.x)*lengthGrowth;r.cy=p.cy+r.attachment.y+(target.cy-tp.cy-at.y)*widthGrowth;r.cz=p.cz+r.attachment.z+(target.cz-tp.cz-at.z)*lengthGrowth
   -- Extend appendages from their socket toward the distal tip.
   -- This prevents a miniature adult limb from scaling around its midpoint.
   if target.kind=='appendage' or target.partType=='segment' or target.partType=='digit'
     or target.partType=='claw' or target.partType=='tail' then
     local socketX=p.cx+r.attachment.x
     local socketY=p.cy+r.attachment.y
     local socketZ=p.cz+r.attachment.z
     local dx=target.cx-tp.cx-at.x
     local dy=target.cy-tp.cy-at.y
     local dz=target.cz-tp.cz-at.z
     r.cx=socketX+dx*lengthGrowth
     r.cy=socketY+dy*lengthGrowth
     r.cz=socketZ+dz*lengthGrowth
   end
  else r.cx,r.cy,r.cz=target.cx*lengthGrowth,target.cy*widthGrowth,target.cz*widthGrowth;r.attachment={x=0,y=0,z=0} end
  r.x,r.y=r.cx,-r.cz;r.orientation=target.orientation
  local function point(pt) return {x=r.cx+(pt.x-target.cx)*lengthGrowth,y=r.cy+(pt.y-target.cy)*widthGrowth,z=r.cz+(pt.z-target.cz)*widthGrowth} end
  if target.start then r.start=point(target.start);r.finish=point(target.finish) end
  r.mapGrowthPoint=point -- removed below; never serialized or used by renderer.
 end
 for i,c in ipairs(a.components) do
  local target=m.components[i];local r=a.regions[c.regionId];local tr=m.regions[c.regionId];local lg=r.length/math.max(.000001,tr.length);local wg=r.width/math.max(.000001,tr.width)
  local begin=tr.activation+(c.type=='Muscle' and .08 or c.type=='Fat' and .22 or c.type=='Skin' and .12 or c.type=='Nerve' and .04 or c.type=='Brain' and .08 or 0)
  local maturity=phase(t,begin,c.type=='Fat' and 1 or c.type=='Skin' and .95 or .88);c.growth=maturity;c.growthProgress=maturity;c.tissueMaturity=maturity;c.functionalMaturity=phase(t,begin+.08,.97);c.targetSize={rx=target.rx,ry=target.ry,rz=target.rz};c.targetVolume=target.volume;c.targetDensity=target.density
  local ratio=tr.volume>0 and r.volume/tr.volume or 0;local reserve=c.type=='Fat' and m.fatFraction or 1;c.volume=target.volume*ratio*maturity*reserve;c.density=target.density*((c.type=='Bone' or c.type=='Carapace' or c.type=='Support') and (.35+.65*maturity) or 1);if c.type=='Stem' then c.volume=r.volume*.5*(1-phase(t,0,.25)) end;c.mass=c.volume*c.density
  c.cx=r.cx+(target.cx-tr.cx)*lg;c.cy=r.cy+(target.cy-tr.cy)*wg;c.cz=r.cz+(target.cz-tr.cz)*wg;c.x,c.y=c.cx,-c.cz;c.rx=target.rx*lg*maturity^(1/3);c.ry=target.ry*wg*maturity^(1/3);c.rz=target.rz*wg*maturity^(1/3);c.orientation=target.orientation
  for _,key in ipairs({'capacity','airExchange','wasteCapacity','exchange','area'}) do if target[key] then c[key]=target[key]*ratio*maturity end end
  if target.length then c.length=target.length*lg end;if target.width then c.width=target.width*wg end;if target.thickness then c.thickness=target.thickness*wg end
  if target.strength then c.strength=target.strength*(ratio*maturity)^.65*(.35+.65*maturity) end
  if target.path then c.path={};for _,pt in ipairs(target.path) do c.path[#c.path+1]=r.mapGrowthPoint(pt) end end
  r.tissues[c.type]=(r.tissues[c.type] or 0)+c.volume;r.freeVolume=math.max(0,r.freeVolume-c.volume)
 end
 for _,r in ipairs(a.regions) do r.mapGrowthPoint=nil end
 for i,n in ipairs(a.nerves) do local nt=m.nerveTargets[i];n.growth=math.min(a.components[n.from].growth,a.components[n.to].growth);n.efficiency=nt.efficiency*n.growth end
 for i,j in ipairs(a.joints) do local target=m.jointTargets[i];local r=a.regions[j.partId];local parent=a.regions[r.parent];j.cx=parent.cx+r.attachment.x;j.cy=parent.cy+r.attachment.y;j.cz=parent.cz+r.attachment.z;j.x,j.y=j.cx,-j.cz;j.growth=r.functionalMaturity;j.mobility=target.mobility*j.growth end
 a.massLedger={mass=0,tissueVolume=0,volume=0};for _,r in ipairs(a.regions) do a.massLedger.volume=a.massLedger.volume+r.volume end;for _,c in ipairs(a.components) do a.massLedger.mass=a.massLedger.mass+c.mass;a.massLedger.tissueVolume=a.massLedger.tissueVolume+c.volume end
 a.embryology=require('embryology').evaluate(a.seed or 1,t)
 a.growthRevision=(a.growthRevision or 0)+1;return a
end
function D.advance(a,seconds,environment)
 local m=a.growthModel;local env=environment or m.environment;local temperature=env.temperature or 37;local constraint=math.max(0,math.min(1.5,env.nutrition or 1))*math.max(0,math.min(1,env.oxygen or 1))*math.max(0,1-math.abs(temperature-37)/40)
 m.elapsed=m.elapsed+math.max(0,seconds)*constraint;return D.setProgress(a,math.min(1,m.elapsed/m.duration),env)
end
function D.record(a,count,full)
 local copy=G.copy(a);local records={};copy.growthModel.elapsed=0
 for i=0,count do D.setProgress(copy,i/count,{fatFraction=.7});local record={progress=i/count,mass=copy.massLedger.mass,stage=string.format('Biological growth %.1f%%',i/count*100)};if full then record.regions=G.copy(copy.regions);record.components=G.copy(copy.components);record.joints=G.copy(copy.joints);record.nerves=G.copy(copy.nerves) else record.regionStates={};for _,r in ipairs(copy.regions) do record.regionStates[#record.regionStates+1]={id=r.id,length=r.length,width=r.width,thickness=r.thickness,growth=r.growth} end end;records[#records+1]=record end
 return records
end
return D
