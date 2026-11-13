local BoneShapes=require('skeletal_shapes')
local OrganShapes=require('organ_shapes')
local TissuePaths=require('tissue_paths')
local V={};local colors={Bone={.92,.86,.67},Support={.44,.76,.70},Carapace={.68,.75,.56},Muscle={.76,.24,.32},Fat={.96,.76,.37},Heart={.9,.25,.32},Lung={.89,.57,.68},Stomach={.55,.74,.46},Brain={.77,.58,.94},Kidney={.68,.36,.32},Gonad={.85,.66,.39}}
local function point(p,top)
 -- Anatomy components have cx/cy/cz; bone path vertices have x/y/z.
 -- The side view MUST use world Z, never world Y.
 -- The previous fallback read p.y when p.z was available, projecting
 -- the top-view bones over the side-view organism.
 local x=p.cx or p.x or 0
 if top then return x,p.cy or p.y or 0 end
 return x,-(p.cz or p.z or 0)
end
local function path(points,top,width,color)
 local coords={};for _,pt in ipairs(points) do coords[#coords+1]=pt.x;coords[#coords+1]=top and pt.y or -pt.z end
 if #coords>=4 then love.graphics.setColor(color);love.graphics.setLineWidth(math.max(.2,width));love.graphics.setLineJoin('bevel');love.graphics.line(coords) end
end
-- Volumetric bone and soft-tissue silhouettes are derived from the same
-- support paths / muscle attachments as the anatomical graph.
local function boneShape(points,top,width,color)
 if not points or #points<2 then return end
 local n=#points
 local px,py=point(points[1],top)
 for i=2,n do
  local qx,qy=point(points[i],top)
  local dx,dy=qx-px,qy-py
  local length=math.sqrt(dx*dx+dy*dy)
  if length>.0001 then
   local nx,ny=-dy/length,dx/length
   local w=math.max(.3,width)
   local head=w*(i==2 and 1.30 or .85)
   local tip=w*(i==n and 1.27 or .85)
   love.graphics.setColor(.65,.59,.45,.92)
   love.graphics.polygon('fill',px+nx*head*.62,py+ny*head*.62,qx+nx*tip*.55,qy+ny*tip*.55,qx-nx*tip*.55,qy-ny*tip*.55,px-nx*head*.62,py-ny*head*.62)
   love.graphics.setColor(color[1],color[2],color[3],1)
   love.graphics.polygon('fill',px+nx*head*.43,py+ny*head*.43,qx+nx*tip*.38,qy+ny*tip*.38,qx-nx*tip*.38,qy-ny*tip*.38,px-nx*head*.43,py-ny*head*.43)
   love.graphics.setColor(1,.97,.83,.65)
   love.graphics.setLineWidth(math.max(.15,w*.11))
   love.graphics.line(px+nx*w*.26,py+ny*w*.26,qx+nx*w*.22,qy+ny*w*.22)
  end
  px,py=qx,qy
 end
end
local function muscleAnchor(bone,target)
 if not bone then return nil end
 local best,dist
 for _,p in ipairs(bone.path or {}) do
  local dx=p.x-target.cx
  local dy=p.y-target.cy
  local dz=p.z-target.cz
  local d=dx*dx+dy*dy+dz*dz
  if not dist or d<dist then best,dist=p,d end
 end
 return best or bone
end
local function muscleShape(px,py,qx,qy,width,side)
 local dx,dy=qx-px,qy-py
 local length=math.sqrt(dx*dx+dy*dy)
 if length<.08 then return end
 local nx,ny=-dy/length,dx/length
 local w=math.max(.12,math.min(width,length*.19))
 local shift=(side or 1)*w*.42
 local x1,y1=px+dx*.24+nx*shift,py+dy*.24+ny*shift
 local x2,y2=px+dx*.76+nx*shift,py+dy*.76+ny*shift
 love.graphics.setColor(.36,.09,.12,.94)
 love.graphics.polygon('fill',px,py,x1+nx*w,y1+ny*w,x2+nx*w,y2+ny*w,qx,qy,x2-nx*w,y2-ny*w,x1-nx*w,y1-ny*w)
 love.graphics.setColor(.72,.22,.28,.96)
 love.graphics.polygon('fill',px,py,x1+nx*w*.77,y1+ny*w*.77,x2+nx*w*.77,y2+ny*w*.77,qx,qy,x2-nx*w*.77,y2-ny*w*.77,x1-nx*w*.77,y1-ny*w*.77)
 love.graphics.setColor(.94,.51,.48,.53)
 love.graphics.setLineWidth(math.max(.12,w*.08))
 for i=-1,1 do
  local off=i*w*.35
  love.graphics.line(x1+nx*off,y1+ny*off,x2+nx*off,y2+ny*off)
 end
 love.graphics.setColor(.90,.80,.66,.94)
 love.graphics.setLineWidth(math.max(.10,w*.16))
 love.graphics.line(px,py,x1,y1)
 love.graphics.line(x2,y2,qx,qy)
end
local function fatLayer(a,r,volume,top)
 if not r or volume<=0 then return end
 local x,y=point(r,top)
 local bodyWidth=math.max(.2,top and r.width or r.thickness)
 local length=math.max(.2,r.length)
 local tissue=math.sqrt(volume*32^3/math.max(1,length))
 local thickness=math.min(bodyWidth*.27,math.max(.15,tissue*.27))
 -- Subcutaneous bilateral pads follow the region's axis, rather than
 -- arbitrary full-length horizontal bars.
 local angle=top and (r.start and r.finish and math.atan2(r.finish.y-r.start.y,r.finish.x-r.start.x) or 0) or r.orientation
 local dx,dy=math.cos(angle),math.sin(angle)
 local nx,ny=-dy,dx
 for side=-1,1,2 do
  local cx=x+nx*side*(bodyWidth*.30)
  local cy=y+ny*side*(bodyWidth*.30)
  local ex,ey=dx*length*.32,dy*length*.32
  local ox,oy=nx*thickness*.6,ny*thickness*.6
  love.graphics.setColor(.71,.49,.20,.78)
  love.graphics.polygon('fill',cx-ex-ox,cy-ey-oy,cx+ex-ox,cy+ey-oy,cx+ex+ox,cy+ey+oy,cx-ex+ox,cy-ey+oy)
  love.graphics.setColor(.96,.79,.42,.87)
  love.graphics.setLineWidth(math.max(.2,thickness*.22))
  love.graphics.line(cx-ex*.83,cy-ey*.83,cx+ex*.83,cy+ey*.83)
 end
end
function V.draw(o,x,y,scale,t,layer,selected,top)
 local a=o.anatomy;layer=layer or 'External';local function on(k) return type(layer)=='table' and layer[k] or type(layer)~='table' and layer==k end
 local external=on('External') or on('Skin');if not a.motionAnimation and not a.motionMode and o.motion and o.motion.active then a=require('locomotion').pose(a,o.motion.phase or 0,{energy=(o.energy or 0)/100,oxygen=o.oxygen or 1,fatigue=o.motion.fatigue or 0},o.caps.locomotionProfile) elseif not a.motionAnimation and not a.motionMode and o.animation then a=require('motion').pose(a,o.animation,t or 0,o.condition) end;local tint=require('rendering_legacy').pigment(a.pigment)
 love.graphics.push('all');love.graphics.translate(x,y);if top then love.graphics.rotate(o.angle or 0) end;love.graphics.scale(scale)
 require('tissue_surface').draw(a,tint,top,external and 1 or .09)
 -- Cartilage is a small socket between nearby bone endpoints, never
 -- a broad overlay at the anatomical region center.
 if on('Skeleton') and a.supportStrategy=='articulated endoskeleton' then
  for _,j in ipairs(a.joints) do
   local parent=a.components[j.parent]
   local child=a.components[j.child]
   if parent and child and parent.volume>0 and child.volume>0 and (j.growth or 0)>.02 then
    BoneShapes.drawJoint(parent,child,j,top,colors.Bone or {.85,.79,.59})
   end
  end
 end
 for _,c in ipairs(a.components) do if c.volume>.0000000001 then
  local xx,yy=point(c,top);local color=colors[c.type] or {.58,.69,.71};local isSupport=c.type=='Bone' or c.type=='Support' or c.type=='Carapace'
  if on('Skeleton') and isSupport then
   -- Both cameras draw the SAME 3-D skeletal geometry, independently
   -- projected by skeletal_shapes. Never hide ribs to disguise bad projection.
   BoneShapes.draw(c,top,color)
  elseif on('Muscle') and c.type=='Muscle' then
   local p,q=a.components[c.origin],a.components[c.insertion]
   if p and q then
    local px,py=point(muscleAnchor(p,c),top)
    local qx,qy=point(muscleAnchor(q,c),top)
    local span=math.sqrt((px-qx)^2+(py-qy)^2)
    local width=math.sqrt(math.max(0,c.volume)*32^3/math.max(1,span)*math.pi)*.24
    muscleShape(px,py,qx,qy,width,c.muscleSide)
   end
  elseif on('Fat') and c.type=='Fat' then
   local r=a.regions[c.regionId];fatLayer(a,r,c.volume,top)
  elseif on('Organs') and (c.type=='Heart' or c.type=='Lung' or c.type=='Stomach' or c.type=='Brain' or c.type=='Kidney' or c.type=='Gonad') then
   OrganShapes.draw(c,top)
  elseif on('Organs') and c.type=='Gill' then path({{x=c.cx-c.rx*.4,y=c.cy,z=c.cz},{x=c.cx+c.rx*.4,y=c.cy,z=c.cz}},top,.8,{.35,.75,.91}) end
  if (on('External') or on('Nervous')) and c.type=='Sensor' and a.motionAnimation~='Dead' then local r=a.regions[c.regionId];if r.partType=='cranium' then love.graphics.setColor(.96,.97,.77);love.graphics.circle('fill',xx,yy,math.max(.15,1.5*c.growth));love.graphics.setColor(.035,.10,.13);love.graphics.circle('fill',xx+.3,yy,math.max(.1,.8*c.growth)) end end
  if c.condition<.7 then love.graphics.setColor(.8,.15,.17,.8);love.graphics.circle('fill',xx,yy,.8) end
 end end
 if on('Nervous') then TissuePaths.draw(a,a.nerves,top,'nerve') end
 if on('Organs') then TissuePaths.draw(a,a.vessels,top,'vessel') end
 -- Membranes and fins are not rendered as arbitrary translucent
 -- triangles. Their future mesh must follow real edge attachments.
 if selected and a.regions[selected] then local r=a.regions[selected];love.graphics.setColor(.3,.95,.8,.9);love.graphics.setLineWidth(.5);love.graphics.line(r.x-4,r.y,r.x+4,r.y);love.graphics.line(r.x,r.y-4,r.x,r.y+4) end
 love.graphics.pop()
end
return V
