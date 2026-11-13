-- Anatomy-derived controller. No species gaits, minimum speed or forced walking.
local L={worldInches=36};local function clamp(v,a,b) return math.max(a,math.min(b,v)) end
local function support(c) return c.type=='Bone' or c.type=='Support' or c.type=='Carapace' end
function L.profile(a,c)
 local mass,force,cx,cy,cz,neural=0,0,0,0,0,0;local strength=0;local reachable={};local byRegion={};local joint={};local legByPart={}
 for _,o in ipairs(a.organs or {}) do if o.type=='Brain' and o.condition>.05 then reachable[o.id]=true end end
 for pass=1,30 do local changed=false;for _,n in ipairs(a.nerves or {}) do if reachable[n.from] and n.condition*n.efficiency>.005 and not reachable[n.to] then reachable[n.to]=true;changed=true end end;if not changed then break end end
 for _,p in ipairs(a.components) do mass=mass+p.mass;cx=cx+p.mass*p.cx;cy=cy+p.mass*p.cy;cz=cz+p.mass*p.cz
  if support(p) then strength=strength+(p.strength or 0)*p.condition end
  if p.type=='Muscle' then local f=p.mass*(p.force or 0)*(p.leverage or 0)*(p.efficiency or 0)*p.condition;if reachable[p.id] then force=force+f;neural=neural+1 end;byRegion[p.regionId]=(byRegion[p.regionId] or 0)+(reachable[p.id] and f or 0) end
 end
 if mass>0 then cx,cy,cz=cx/mass,cy/mass,cz/mass end
 for _,j in ipairs(a.joints or {}) do joint[j.partId]=j end
 local roots={};for _,r in ipairs(a.regions) do if r.partType=='segment' and (r.pathIndex or 1)==1 then local leg={id=r.id,root=r,segments={},parts={},length=0,force=0,mobility=1,condition=1,role=r.functionalRole};roots[#roots+1]=leg;legByPart[r.id]=leg end end
 for _,r in ipairs(a.regions) do local leg=legByPart[r.id] or r.parent and legByPart[r.parent];if leg then legByPart[r.id]=leg;leg.parts[#leg.parts+1]=r.id;leg.force=leg.force+(byRegion[r.id] or 0)
   if r.partType=='segment' then leg.segments[#leg.segments+1]=r;leg.length=leg.length+r.length/32;local j=joint[r.id];leg.mobility=math.min(leg.mobility,j and j.mobility*j.condition*math.min(1,j.range) or 0);leg.condition=math.min(leg.condition,(a.components[r.structure].condition or 0)) end
   if r.partType=='foot' or r.partType=='pad' or r.partType=='hoof' or r.partType=='hand' or r.partType=='fin' then leg.tip=r end
  end end
 local minz=math.huge;for _,leg in ipairs(roots) do local tip=leg.tip or leg.segments[#leg.segments];leg.tip=tip;leg.foot={x=tip.cx,y=tip.cy,z=tip.cz-tip.thickness*.5};if leg.role~='swimming' and leg.role~='manipulation' then minz=math.min(minz,leg.foot.z) end end
 local contacts={};local stride,limbForce=0,0
 for _,leg in ipairs(roots) do if leg.role~='swimming' and leg.role~='manipulation' and leg.mobility>.01 and leg.force>.000001 and leg.condition>.05 then
  leg.groundGap=leg.foot.z-minz;leg.contact=leg.groundGap<=leg.length*32*.18+leg.tip.thickness*.5
  if leg.contact then contacts[#contacts+1]=leg;stride=stride+leg.length*leg.mobility*.6;limbForce=limbForce+leg.force end
 end end
 table.sort(contacts,function(x,y) local ax=math.atan2(x.foot.y-cy,x.foot.x-cx);local ay=math.atan2(y.foot.y-cy,y.foot.x-cx);return ax==ay and x.id<y.id or ax<ay end)
 local balance=0
 if #contacts>=2 then local minx,miny,maxx,maxy=1e9,1e9,-1e9,-1e9;for _,leg in ipairs(contacts) do local margin=math.max(1,leg.tip.width*.5);minx=math.min(minx,leg.foot.x-margin);maxx=math.max(maxx,leg.foot.x+margin);miny=math.min(miny,leg.foot.y-margin);maxy=math.max(maxy,leg.foot.y+margin) end
  local dx=math.max(minx-cx,0,cx-maxx);local dy=math.max(miny-cy,0,cy-maxy);local span=math.max(1,maxx-minx,maxy-miny);balance=clamp(1-(dx+dy)/(span*.45),0,1)
 end
 local load=clamp(strength/math.max(.000001,mass*5),0,1)*(c and c.support or 1);local supply=c and c.supply or 1;local mode='immobile';local speed=0
 if #contacts>=2 and balance>.02 and force>0 then mode='legged';stride=stride/#contacts;speed=stride*math.sqrt(limbForce/math.max(.001,mass))*balance*load*supply end
 local axes={};local flexibility=0;for _,r in ipairs(a.regions) do if r.partType=='chest' or r.partType=='abdomen' or r.partType=='trunk' or r.partType=='pelvis' or r.partType=='tail' then axes[#axes+1]=r;local j=joint[r.id];if j then flexibility=flexibility+j.mobility*j.condition*j.range end end end
 flexibility=flexibility/math.max(1,#axes-1)
 if #roots==0 and #axes>=2 and flexibility>.12 and force>0 and load>.02 then mode='undulation';stride=0;for _,r in ipairs(axes) do stride=stride+r.length/32 end;stride=stride*.15*math.min(1,flexibility);speed=stride*math.sqrt(force/math.max(.001,mass))*.22*load*supply;balance=1 end
 local waterForce=0;for _,leg in ipairs(roots) do if leg.role=='swimming' then waterForce=waterForce+leg.force*leg.mobility end end
 local waterSpeed=waterForce>0 and math.sqrt(waterForce/math.max(.001,mass))*.15*load*supply or mode=='undulation' and speed*.9 or 0
 if speed<.00001 then speed=0;mode='immobile' end
 local duty=clamp(.58+.2*(1-force/math.max(.001,mass)),.55,.88);for i,leg in ipairs(contacts) do leg.phase=(i-1)/#contacts;leg.stride=stride*32;leg.duty=duty end
 return {mode=mode,canMove=speed>0,speed=speed/L.worldInches,waterSpeed=waterSpeed/L.worldInches,stride=stride,mass=mass,force=force,support=load,balance=balance,legs=contacts,allAppendages=roots,axes=axes,flexibility=flexibility,control=neural/math.max(1,#a.muscles),center={x=cx,y=cy,z=cz},duty=duty,joints=joint}
end
function L.pose(a,phase,condition,profile)
 local p=profile or L.profile(a,a.caps);if not p.canMove then return a end
 local angles={};local contacts={};local rate=phase or 0
 for _,leg in ipairs(p.legs) do
  local f=(rate+leg.phase)%1;local stance=f<leg.duty;local u=stance and f/leg.duty or (f-leg.duty)/(1-leg.duty)
  local first,second=leg.segments[1],leg.segments[2];local host=a.regions[first.parent];local hx,hz=host.cx+first.attachment.x,host.cz+first.attachment.z
  local dx=leg.foot.x-hx+(stance and (.5-u) or (u-.5))*leg.stride;local dz=leg.foot.z-hz+(stance and 0 or math.sin(u*math.pi)*math.min(leg.length*8,leg.stride*.35))
  if second then local l1,l2=first.length,second.length;local bend=math.acos(clamp((dx*dx+dz*dz-l1*l1-l2*l2)/math.max(.00001,2*l1*l2),-1,1));local hip=math.atan2(-dz,dx)-math.atan2(l2*math.sin(bend),l1+l2*math.cos(bend));angles[first.id]=hip-first.orientation;angles[second.id]=hip+bend-second.orientation-angles[first.id]
  else angles[first.id]=math.atan2(-dz,dx)-first.orientation end
  -- Refine the target against the exact hierarchical transform used by rendering.
  -- Unreachable targets remain recorded as slip; joint limits are never stretched.
  local chain={};local r=leg.tip;while r do table.insert(chain,1,r);r=r.parent and a.regions[r.parent] end
  local function foot()
   local c,s,tx,ty=1,0,0,0
   for _,part in ipairs(chain) do local j=p.joints[part.id];if j then
    local ax=c*j.cx+s*j.cz+tx;local ay=s*j.cx-c*j.cz+ty
    local angle=clamp(angles[part.id] or 0,j.minimum,j.maximum)*j.condition;local cc,ss=math.cos(angle),math.sin(angle)
    tx,ty=ax+cc*(tx-ax)-ss*(ty-ay),ay+ss*(tx-ax)+cc*(ty-ay)
    c,s=cc*c-ss*s,ss*c+cc*s
   end end
   return c*leg.foot.x+s*leg.foot.z+tx,-(s*leg.foot.x-c*leg.foot.z+ty)
  end
  local targetX,targetZ=hx+dx,hz+dz
  local function error() local x,z=foot();return (x-targetX)^2+(z-targetZ)^2 end
  for pass=1,12 do for i=#leg.segments,1,-1 do local part=leg.segments[i];local j=p.joints[part.id];if j then
   local old=angles[part.id] or 0;local best,bestError=old,error();local step=.28*(.73^(pass-1))
   for _,delta in ipairs({-step,step}) do angles[part.id]=clamp(old+delta,j.minimum,j.maximum);local e=error();if e<bestError then best,bestError=angles[part.id],e end end;angles[part.id]=best
  end end end
  local footX,footZ=foot()
  contacts[#contacts+1]={partId=leg.tip.id,stance=stance,targetX=targetX,targetZ=targetZ,actualX=footX,actualZ=footZ,errorInches=math.sqrt(error())/32}
 end
 if p.mode=='undulation' then for i,r in ipairs(p.axes) do local j=p.joints[r.id];if j then angles[r.id]=math.sin(rate*math.pi*2-i*.7)*math.min(j.range*.22,.22)*math.min(1,p.flexibility) end end end
 local pose=require('anatomical_rendering').pose(a,0,function(r,j) return clamp(angles[r.id] or 0,j.minimum,j.maximum) end);pose.motionContacts=contacts;pose.motionMode=p.mode;return pose
end
return L
