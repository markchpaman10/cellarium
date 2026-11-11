-- Rasterize the continuous tissue envelope of the grown region graph.
-- No creature templates, rectangular body tiles, or random decorative geometry.
local M={}
function M.pose(a,phase,method)
 local out={}
 for _,r in ipairs(a.regions) do
  local p={x=r.x,y=r.y,rx=r.rx,ry=r.ry,orientation=r.orientation,parent=r.parent,id=r.id,kind=r.kind}
  local t=phase or 0
  if method=='undulation' then p.y=p.y+math.sin(t+r.id*.65)*math.min(4,r.ry*.3)
  elseif method=='contractions' then p.x=p.x*(1+.055*math.sin(t+r.id*.35));p.ry=p.ry*(1+.06*math.sin(t+r.id*.35))
  elseif method=='radial' then local k=1+.065*math.sin(t);p.x=p.x*k;p.y=p.y*k;p.rx=p.rx*(2-k);p.ry=p.ry*(2-k)
  elseif method=='jointed' and r.kind=='appendage' then local parent=r.parent and out[r.parent];local originalParent=r.parent and a.regions[r.parent];local wave=math.sin(t+(r.mirrorGroup or r.id)*2+r.pathIndex*.5)*.13
   if parent then local dx,dy=r.x-originalParent.x,r.y-originalParent.y;p.x=parent.x+dx*math.cos(wave)-dy*math.sin(wave);p.y=parent.y+dx*math.sin(wave)+dy*math.cos(wave) end
  end
  out[r.id]=p
 end;return out
end
function M.raster(a,pose)
 pose=pose or M.pose(a);local loX,loY,hiX,hiY=1e9,1e9,-1e9,-1e9;for _,r in ipairs(pose) do local radius=math.max(r.rx,r.ry);loX=math.min(loX,r.x-radius);loY=math.min(loY,r.y-radius);hiX=math.max(hiX,r.x+radius);hiY=math.max(hiY,r.y+radius) end;local x0,y0=math.floor(loX-3),math.floor(loY-3);local w,h=math.ceil(hiX-x0+3),math.ceil(hiY-y0+3);local pixels={}
 local function ellipse(x,y,rx,ry,angle)
  local radius=math.max(rx,ry);local ca,sa=math.cos(angle or 0),math.sin(angle or 0)
  for yy=math.max(0,math.floor(y-radius-y0)),math.min(h-1,math.ceil(y+radius-y0)) do for xx=math.max(0,math.floor(x-radius-x0)),math.min(w-1,math.ceil(x+radius-x0)) do
   local dx,dy=xx+x0+.5-x,yy+y0+.5-y;local u,v=(dx*ca+dy*sa)/rx,(-dx*sa+dy*ca)/ry;if u*u+v*v<=1 then pixels[yy*w+xx]=true end
  end end
 end
 for _,r in ipairs(pose) do
  if r.parent then local p=pose[r.parent];local dist=math.sqrt((p.x-r.x)^2+(p.y-r.y)^2);local steps=math.max(1,math.ceil(dist/2));for i=0,steps do local t=i/steps;local radiusX=p.rx*(1-t)+r.rx*t;local radiusY=p.ry*(1-t)+r.ry*t;ellipse(p.x*(1-t)+r.x*t,p.y*(1-t)+r.y*t,radiusX,radiusY,p.orientation*(1-t)+r.orientation*t) end end
  ellipse(r.x,r.y,r.rx,r.ry,r.orientation)
 end
 return {pixels=pixels,width=w,height=h,x=x0,y=y0}
end
return M
