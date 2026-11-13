-- Procedural skeletal silhouettes. World-space anatomy is authoritative:
-- project x/y in plan and x/-z in profile. No species templates.
local B={}
local function project(p,top)
 return p.x or p.cx or 0, top and (p.y or p.cy or 0) or -(p.z or p.cz or 0)
end
local function classify(c)
 local name=c.anatomicalName or ''
 if name:match('^vertebra ') or name:match('^cervical segment ') then return 'vertebra' end
 if name=='protective rib arch' then return 'rib' end
 if name:find('girdle',1,true) then return 'girdle' end
 if name=='cranial protective vault' then return 'skull' end
 if name=='orbital rim' then return 'orbital' end
 if name=='paired distal support' then return 'long' end
 if name:find('phalange',1,true) or name=='digit' then return 'digit' end
 if name:find('jaw',1,true) then return 'jaw' end
 if name:find('claw',1,true) then return 'claw' end
 return 'long'
end
B.classify=classify
local function shade(color,mult,alpha)
 love.graphics.setColor(math.min(1,color[1]*mult),math.min(1,color[2]*mult),math.min(1,color[3]*mult),alpha or 1)
end
local function strip(ax,ay,bx,by,wa,wb,color)
 local dx,dy=bx-ax,by-ay
 local len=math.sqrt(dx*dx+dy*dy)
 if len<.00001 then return end
 local nx,ny=-dy/len,dx/len
 shade(color,.64)
 love.graphics.polygon('fill',ax+nx*wa,ay+ny*wa,bx+nx*wb,by+ny*wb,bx-nx*wb,by-ny*wb,ax-nx*wa,ay-ny*wa)
 shade(color,1.04)
 love.graphics.polygon('fill',ax+nx*wa*.76,ay+ny*wa*.76,bx+nx*wb*.76,by+ny*wb*.76,bx-nx*wb*.76,by-ny*wb*.76,ax-nx*wa*.76,ay-ny*wa*.76)
 shade(color,1.24,.55)
 love.graphics.setLineWidth(math.max(.11,math.min(wa,wb)*.15))
 love.graphics.line(ax+nx*wa*.48,ay+ny*wa*.48,bx+nx*wb*.48,by+ny*wb*.48)
end
local function capsule(ax,ay,bx,by,width,color,kind)
 local dx,dy=bx-ax,by-ay
 local len=math.sqrt(dx*dx+dy*dy)
 if len<.00001 then return end
 local nx,ny=-dy/len,dx/len
 local ux,uy=dx/len,dy/len
 local w=math.min(width,len*.18)
 local shaft=w*(kind=='digit' and .55 or .50)
 local endW=w*(kind=='digit' and .72 or .88)
 local s=len*.18
 strip(ax,ay,ax+dx*.20,ay+dy*.20,endW,shaft,color)
 strip(ax+dx*.20,ay+dy*.20,bx-dx*.20,by-dy*.20,shaft,shaft*.95,color)
 strip(bx-dx*.20,by-dy*.20,bx,by,shaft*.95,endW*.86,color)
 shade(color,.78)
 love.graphics.ellipse('fill',ax,ay,endW*.95,endW*.78)
 love.graphics.ellipse('fill',bx,by,endW*.82,endW*.72)
 shade(color,1.12)
 love.graphics.ellipse('fill',ax-ux*s*.12+nx*w*.10,ay-uy*s*.12+ny*w*.10,endW*.65,endW*.53)
 love.graphics.ellipse('fill',bx+ux*s*.10+nx*w*.08,by+uy*s*.10+ny*w*.08,endW*.59,endW*.48)
end
local function curved(points,top,width,color)
 local n=#points
 if n<2 then return end
 for i=2,n do
  local ax,ay=project(points[i-1],top)
  local bx,by=project(points[i],top)
  local taper=math.sin(math.pi*((i-.5)/n))
  strip(ax,ay,bx,by,width*(.30+.30*taper),width*(.28+.28*taper),color)
 end
end
-- Different genetic support strategies need distinct visual anatomy.
-- These are structural tissues, not substitutes for the bone generator.
local function hydrostatic(points,top,width,color)
 for i=2,#points do
  local ax,ay=project(points[i-1],top)
  local bx,by=project(points[i],top)
  local dx,dy=bx-ax,by-ay
  local length=math.sqrt(dx*dx+dy*dy)
  if length>.001 then
   local nx,ny=-dy/length,dx/length
   local radius=math.max(.16,width*.82)
   shade(color,.48,.72)
   strip(ax,ay,bx,by,radius,radius*.88,color)
   shade(color,1.25,.72)
   love.graphics.setLineWidth(math.max(.11,radius*.13))
   love.graphics.line(ax+nx*radius*.52,ay+ny*radius*.52,bx+nx*radius*.46,by+ny*radius*.46)
   love.graphics.line(ax-nx*radius*.52,ay-ny*radius*.52,bx-nx*radius*.46,by-ny*radius*.46)
  end
 end
end
local function exoskeleton(points,top,width,color)
 for i=2,#points do
  local ax,ay=project(points[i-1],top)
  local bx,by=project(points[i],top)
  local dx,dy=bx-ax,by-ay
  local length=math.sqrt(dx*dx+dy*dy)
  if length>.001 then
   local nx,ny=-dy/length,dx/length
   local radius=math.max(.18,width*.82)
   strip(ax,ay,bx,by,radius,radius*.86,color)
   shade(color,.43,.95)
   love.graphics.setLineWidth(math.max(.12,radius*.18))
   for t=.12,.88,.24 do
    local px,py=ax+dx*t,ay+dy*t
    love.graphics.line(px+nx*radius,py+ny*radius,px-nx*radius,py-ny*radius)
   end
  end
 end
end
function B.draw(c,top,color)
 local pts=c.path
 if not pts or #pts<2 then return end
 local kind=classify(c)
 local grow=math.max(0,math.min(1,c.growth or 1))
 if grow<.02 then return end
 local width=math.max(.12,math.min(2.7,(c.thickness or .1)*6))*(.3+.7*grow)
 if c.type=='Support' then
  hydrostatic(pts,top,width,color)
 elseif c.type=='Carapace' then
  exoskeleton(pts,top,width,color)
 elseif kind=='rib' or kind=='girdle' or kind=='orbital' or kind=='jaw' then
  curved(pts,top,width,color)
 elseif kind=='skull' then
  -- Cranial vault uses its generated rim; do not replace with a circle.
  curved(pts,top,width*1.4,color)
 elseif kind=='vertebra' then
  local ax,ay=project(pts[1],top)
  local bx,by=project(pts[#pts],top)
  capsule(ax,ay,bx,by,width*.72,color,'digit')
  local dx,dy=bx-ax,by-ay
  local len=math.sqrt(dx*dx+dy*dy)
  if len>.01 then
   local nx,ny=-dy/len,dx/len
   local mx,my=(ax+bx)*.5,(ay+by)*.5
   strip(mx-nx*width*.75,my-ny*width*.75,mx+nx*width*.75,my+ny*width*.75,width*.24,width*.24,color)
  end
 else
  for i=2,#pts do
   local ax,ay=project(pts[i-1],top)
   local bx,by=project(pts[i],top)
   capsule(ax,ay,bx,by,width,color,kind)
  end
 end
end
-- Joint anchors use the generated parent and child bone paths.
-- This is visual geometry only; development and physics remain unchanged.
function B.jointAnchor(parent,child,joint,top)
 local function nearest(path,point)
  if not path or #path==0 then return nil end
  local best,bestDist
  for _,p in ipairs(path) do
   local dx=(p.x or 0)-(point.cx or 0)
   local dy=(p.y or 0)-(point.cy or 0)
   local dz=(p.z or 0)-(point.cz or 0)
   local d=dx*dx+dy*dy+dz*dz
   if not bestDist or d<bestDist then best,bestDist=p,d end
  end
  return best
 end
 local p=nearest(parent.path,joint)
 local q=nearest(child.path,joint)
 if not p or not q then return nil end
 local ax,ay=project(p,top)
 local bx,by=project(q,top)
 local gap=math.sqrt((ax-bx)^2+(ay-by)^2)
 local thickness=math.min(parent.thickness or .1,child.thickness or .1)
 local size=math.max(.08,math.min(.34,thickness*3))
 if gap>math.max(1.2,size*5) then return nil end
 return (ax+bx)*.5,(ay+by)*.5,size
end
return B
