-- Reusable anatomical primitives, not animal/species templates. One canonical
-- region/component graph is shared by biology, development and both projections.
local G=require('genome');local P={pixelsPerInch=32}
P.library={
 chest={shape='loft',role='organ-bearing trunk',support='axial',cavity=true},abdomen={shape='loft',role='digestion and reserves',support='axial',cavity=true},pelvis={shape='loft',role='posterior load distribution',support='axial',cavity=true},trunk={shape='loft',role='axial integration',support='axial',cavity=true},
 neck={shape='taper',role='cranial connection',support='axial'},cranium={shape='capsule',role='sensory and neural housing',support='capsule',cavity=true},snout={shape='taper',role='feeding extension',support='capsule'},upper_jaw={shape='jaw',role='feeding support',support='beam'},lower_jaw={shape='jaw',role='articulated feeding',support='beam'},
 segment={shape='taper',role='articulated propulsion',support='beam'},digit={shape='taper',role='distal articulation',support='beam'},pad={shape='pad',role='contact and traction',support='flexible'},claw={shape='hook',role='terminal grip',support='keratin'},hook={shape='hook',role='terminal grip',support='keratin'},hoof={shape='pad',role='terminal load bearing',support='keratin'},
 tail={shape='taper',role='balance or flexible propulsion',support='axial'},fin={shape='foil',role='aquatic propulsion',support='flexible'},membrane={shape='foil',role='lift surface',support='flexible'},horn={shape='taper',role='regional protection',support='keratin'},spike={shape='taper',role='regional protection',support='keratin'},antenna={shape='taper',role='sensory extension',support='flexible'}
}
local densities={Bone=1.05,Carapace=.9,Support=.65,Muscle=.62,Fat=.52,Skin=.61,Brain=.61,Heart=.63,Lung=.25,Stomach=.6,Nerve=.6,Tendon=.66,Sensor=.59,Fin=.6,Membrane=.58,Gill=.6,Projection=.9,Mouth=.6}
function P.new(genome,conditions)
 return {version=3,anatomicalVersion=1,generator='anatomical-blocks-v1',genomeReference=G.hash(genome),seed=(conditions or {}).seed or G.hash(genome),development=G.copy(conditions or {temperature=37,nutrition=1}),regions={},components={},structures={},bones={},muscles={},fat={},skin={},organs={},joints={},sensors={},nerves={},vessels={},surfaces={},projections={},airways={},gills={},mouths={},appendages={},operations={},snapshots={},placementFailures={},limits={regions=80,components=1200},budget=80,pigment=G.express(genome)[23],units={length='in',mass='oz',volume='in^3'},massLedger={}}
end
function P.add(a,kind,parent,opts)
 local def=assert(P.library[kind],kind);local r={id=#a.regions+1,uid='part-'..(#a.regions+1),partType=kind,shape=def.shape,role=def.role,supportType=def.support,cavityAllowed=def.cavity or false,parent=parent,connections={},growth=1,condition=1,stage='formed',depth=opts.depth or 0,kind=opts.appendage and 'appendage' or 'axis',tissues={},geneticInfluences=G.copy(opts.genes or {})}
 for key,value in pairs(opts) do r[key]=G.copy(value) end
 r.length=math.max(.5,r.length or 10);r.width=math.max(.3,r.width or 8);r.thickness=math.max(.3,r.thickness or 8);r.curvature=r.curvature or 0;r.taper=r.taper or .2
 r.cx=r.cx or 0;r.cy=r.cy or 0;r.cz=r.cz or 0;r.orientation=r.orientation or 0;r.x=r.cx;r.y=-r.cz;r.rx=r.length/2;r.ry=r.thickness/2;r.rz=r.width/2
 r.volume=4/3*math.pi*r.rx*r.ry*r.rz/P.pixelsPerInch^3*(def.shape=='taper' and .72 or def.shape=='foil' and .5 or 1);r.freeVolume=r.volume
 r.attachment=r.attachment or {x=0,y=0,z=0};r.localOrientation={pitch=r.orientation,yaw=r.yaw or 0,roll=0}
 if parent then local p=assert(a.regions[parent]);r.connections[#r.connections+1]=parent;p.connections[#p.connections+1]=r.id end
 a.regions[#a.regions+1]=r;a.parts=a.regions;a.operations[#a.operations+1]={operation=parent and 'GROW' or 'DIVIDE',region=r.id,parent=parent,detail=kind};return r
end
function P.component(a,r,kind,parent,volume,props)
 volume=math.max(0,math.min(r.freeVolume,volume));r.freeVolume=math.max(0,r.freeVolume-volume)
 local c={id=#a.components+1,type=kind,partId=r.id,regionId=r.id,parent=parent,x=r.x,y=r.y,cx=r.cx,cy=r.cy,cz=r.cz,rx=r.rx,ry=r.ry,rz=r.rz,size=math.sqrt(r.rx*r.ry)*2,orientation=r.orientation,volume=volume,mass=volume*(densities[kind] or .6),density=densities[kind] or .6,condition=1,region=r.kind=='appendage' and 'limb' or r.partType=='cranium' and 'head' or 'torso',growth=1}
 for k,v in pairs(props or {}) do c[k]=G.copy(v) end
 c.mass=c.volume*c.density
 a.components[#a.components+1]=c;r.tissues[kind]=(r.tissues[kind] or 0)+volume;r.tissueIds=r.tissueIds or {};r.tissueIds[#r.tissueIds+1]=c.id
 return c
end
function P.support(a,r,e,d)
 local rigid=d[11];local kind=rigid>.4 and 'Bone' or d[20]>.7 and 'Carapace' or 'Support'
 local parent=r.parent and a.regions[r.parent].structure
 local c=P.component(a,r,kind,parent,r.volume*(.08+e[15]*.10),{length=r.length/P.pixelsPerInch,thickness=(.35+e[15]*1.4)*r.thickness/P.pixelsPerInch,density=(.45+e[15]*.7),strength=(.5+e[15]*2)*r.volume^.65*5,flexibility=1-rigid,rigidity=rigid,attachmentPosition=G.copy(r.attachment)})
 c.mass=c.volume*c.density;a.structures[#a.structures+1]=c;if kind=='Bone' then a.bones[#a.bones+1]=c end;r.structure=c.id;return c
end
function P.snapshot(a,stage)
 -- These are captured constructor states, never final-body scaling frames.
 a.snapshots[#a.snapshots+1]={stage=stage,regions=G.copy(a.regions),components=G.copy(a.components),joints=G.copy(a.joints),nerves=G.copy(a.nerves),vessels=G.copy(a.vessels),operations=#a.operations}
end
function P.bounds(a)
 local minx,miny,maxx,maxy=math.huge,math.huge,-math.huge,-math.huge
 for _,r in ipairs(a.regions) do local radius=math.max(r.rx,r.ry);minx=math.min(minx,r.x-radius);maxx=math.max(maxx,r.x+radius);miny=math.min(miny,r.y-radius);maxy=math.max(maxy,r.y+radius) end
 a.bounds={minx=minx-3,miny=miny-3,maxx=maxx+3,maxy=maxy+3,width=maxx-minx+6,height=maxy-miny+6}
end
function P.defense(a,partId,surface)
 local result=0
 for _,c in ipairs(a.components) do if c.regionId==partId then
  if c.type=='Skin' and (c.surface=='all' or c.surface==surface) then result=result+(c.armor or 0)*c.condition
  elseif c.type=='Bone' or c.type=='Carapace' or c.type=='Support' then result=result+c.thickness*c.density*c.condition*.18
  elseif c.type=='Fat' then result=result+c.volume*c.condition*.1 end
 end end;return result
end
function P.validate(a)
 local failures={};local function fail(s) failures[#failures+1]=s end
 if #a.regions>a.limits.regions or #a.components>a.limits.components then fail('Anatomical complexity budget exceeded') end
 for i,r in ipairs(a.regions) do
  if i>1 and (not r.parent or r.parent>=i or not a.regions[r.parent]) then fail('Disconnected anatomical part '..i) end
  if not r.structure or not a.components[r.structure] then fail('Missing support in part '..i) end
  local volume=0;for _,c in ipairs(a.components) do if c.regionId==i then volume=volume+c.volume;if c.volume<0 or c.mass<0 then fail('Negative tissue volume') end end end
  if volume>r.volume+1e-7 then fail('Tissues exceed part volume '..i) end
 end
 for _,j in ipairs(a.joints) do if not a.components[j.parent] or not a.components[j.child] or j.range<=0 then fail('Unsupported joint '..j.id) end end
 for _,m in ipairs(a.muscles) do if not a.components[m.origin] or not a.components[m.insertion] or m.origin==m.insertion then fail('Invalid muscle attachments '..m.id) end end
 for _,n in ipairs(a.nerves) do if not a.components[n.from] or not a.components[n.to] then fail('Disconnected nerve') end end
 for _,o in ipairs(a.organs) do local host=a.regions[o.regionId];if not host or not host.cavityAllowed then fail('Organ has no suitable cavity') else local dx,dy,dz=o.cx-host.cx,o.cy-host.cy,o.cz-host.cz;if (dx/(host.rx-o.rx))^2+(dy/(host.rz-o.rz))^2+(dz/(host.ry-o.ry))^2>1.001 then fail('Organ outside its host cavity '..o.id) end end end
 for i,o in ipairs(a.organs) do for j=i+1,#a.organs do local b=a.organs[j];if o.regionId==b.regionId and (o.cx-b.cx)^2+(o.cy-b.cy)^2+(o.cz-b.cz)^2<(o.rx+b.rx)^2-1e-7 then fail('Overlapping cavity contents') end end end
 local reachable={};for _,o in ipairs(a.organs) do if o.type=='Brain' then reachable[o.id]=true end end
 for pass=1,#a.components do local changed=false;for _,n in ipairs(a.nerves) do if reachable[n.from] and not reachable[n.to] then reachable[n.to]=true;changed=true end end;if not changed then break end end
 for _,r in ipairs(a.regions) do if not reachable[r.structure] then fail('No neural path to part '..r.id) end end
 for _,why in ipairs(a.placementFailures) do fail(why) end
 local c=a.caps
 if c then if c.support<.18 then fail('Structure cannot bear developed mass') end;if c.supply<.2 then fail('Organ transport/exchange insufficient for tissue demand') end;if c.digestion<.1 then fail('Nutrient acquisition insufficient') end;if c.coordination<.05 then fail('Neural coordination insufficient') end end
 return #failures==0,failures
end
return P
