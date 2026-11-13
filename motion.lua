-- Animation preview using existing anatomical region/joint graph.
-- No changes to the genome, development, or canonical anatomy.
local Legacy=require('anatomical_rendering')
local M={}
local names={'Walking','Biting','Scratching','Eating','Laying','Dead'}
M.names=names
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function axial(r)
 return r.partType=='chest' or r.partType=='abdomen' or r.partType=='pelvis' or r.partType=='trunk' or r.partType=='neck' or r.partType=='tail'
end
function M.available(a)
 local parts={};local legs=0;local heads=0;local mouths=0;local limbs=0;local digits=0;local axis=0
 for _,r in ipairs(a and a.regions or {}) do
  parts[r.partType]=true
  if r.partType=='segment' and (r.pathIndex or 1)==1 then limbs=limbs+1
   if r.functionalRole~='manipulation' and r.functionalRole~='swimming' then legs=legs+1 end
  end
  if r.partType=='cranium' then heads=heads+1 end
  if r.partType=='lower_jaw' or r.partType=='snout' then mouths=mouths+1 end
  if r.partType=='digit' or r.partType=='claw' then digits=digits+1 end
  if axial(r) then axis=axis+1 end
 end
 local out={
  Walking=legs>=2 or axis>=2,
  Biting=heads>0 and (mouths>0 or parts.upper_jaw),
  Scratching=limbs>0 and digits>0,
  Eating=heads>0 and (mouths>0 or parts.upper_jaw),
  Laying=true,Dead=true
 }
 return out,{legs=legs,limbs=limbs,heads=heads,axis=axis,mode=legs>=2 and 'legged gait' or 'axial undulation'}
end
local function gaitAngle(r,t,legCount)
 local phase=(r.root or r.id)*1.71+(r.muscleSide or 0)
 if r.partType=='segment' then
  local k=r.pathIndex or 1
  return math.sin(t*5+phase+(k-1)*1.9)*(.17/(k^.45))
 elseif r.partType=='digit' or r.partType=='foot' or r.partType=='hand' then
  return math.sin(t*5+phase+2)*.09
 elseif axial(r) then
  return math.sin(t*3+(r.id or 1)*.8)*(legCount>=2 and .014 or .11)
 end
 return 0
end
function M.pose(a,animation,t,condition)
 if not a or not animation then return a end
 local available,info=M.available(a)
 if not available[animation] then return a end
 local energy=clamp((condition and condition.energy or 1)*(1-(condition and condition.fatigue or 0)*.7),.05,1)
 local rate=t or 0
 local function angle(r,j)
  local k=r.partType
  local a0=0
  if animation=='Walking' then
   a0=gaitAngle(r,rate,info.legs)*energy
  elseif animation=='Biting' then
   if k=='lower_jaw' then a0=.22+.16*math.sin(rate*9)
   elseif k=='neck' or k=='cranium' then a0=.045*math.sin(rate*4) end
  elseif animation=='Eating' then
   if k=='lower_jaw' then a0=.11+.12*math.sin(rate*6)
   elseif k=='neck' or k=='cranium' then a0=.08*math.sin(rate*2) end
  elseif animation=='Scratching' then
   if k=='segment' or k=='digit' or k=='hand' or k=='foot' then
    a0=.16*math.sin(rate*9+(r.root or r.id)*.7+(r.pathIndex or 0))
   end
  elseif animation=='Laying' then
   if k=='segment' then a0=(r.pathIndex or 1)==1 and .24 or -.16
   elseif k=='neck' then a0=.08 end
  elseif animation=='Dead' then
   if k=='segment' then a0=(r.pathIndex or 1)==1 and -.22 or .24
   elseif k=='neck' or k=='cranium' then a0=-.15 end
  end
  return clamp(a0,j.minimum or -.5,j.maximum or .5)
 end
 local posed=Legacy.pose(a,rate,angle)
 -- A non-destructive whole-body offset helps distinguish resting and collapsed poses.
 -- Only display geometry changes; growth and stored anatomy are untouched.
 local drop=(animation=='Laying' and 3.0 or animation=='Dead' and 4.5 or 0)
 if drop>0 then
  for _,r in ipairs(posed.regions) do r.cz=r.cz+drop;r.y=-r.cz
   if r.start then r.start.z=r.start.z+drop end
   if r.finish then r.finish.z=r.finish.z+drop end
  end
  for _,c in ipairs(posed.components) do c.cz=c.cz+drop;c.y=-c.cz
   if c.path then for _,p in ipairs(c.path) do p.z=p.z+drop end end
  end
  for _,j in ipairs(posed.joints) do j.cz=j.cz+drop;j.y=-j.cz end
 end
 return posed
end
return M
