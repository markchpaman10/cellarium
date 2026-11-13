local V={};local colors={Bone={.92,.86,.67},Support={.44,.76,.70},Carapace={.68,.75,.56},Muscle={.76,.24,.32},Fat={.96,.76,.37},Heart={.9,.25,.32},Lung={.89,.57,.68},Stomach={.55,.74,.46},Brain={.77,.58,.94},Kidney={.68,.36,.32},Gonad={.85,.66,.39}}
local function point(p,top)
 local x=p.cx or p.x or 0
 local y=top and (p.cy or p.y or 0) or -(p.cz or (p.y and -p.y) or 0)
 return x,y
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
local function muscleShape(px,py,mx,my,qx,qy,width)
 local dx,dy=qx-px,qy-py
 local length=math.sqrt(dx*dx+dy*dy)
 if length<.001 then return end
 local nx,ny=-dy/length,dx/length
 local w=math.max(.35,math.min(width,length*.55))
 local x1,y1=px+dx*.26,py+dy*.26
 local x2,y2=px+dx*.74,py+dy*.74
 love.graphics.setColor(.37,.075,.10,.95)
 love.graphics.polygon('fill',px,py,x1+nx*w,y1+ny*w,x2+nx*w,y2+ny*w,qx,qy,x2-nx*w,y2-ny*w,x1-nx*w,y1-ny*w)
 love.graphics.setColor(.76,.22,.27,.98)
 love.graphics.polygon('fill',px,py,x1+nx*w*.76,y1+ny*w*.76,x2+nx*w*.76,y2+ny*w*.76,qx,qy,x2-nx*w*.76,y2-ny*w*.76,x1-nx*w*.76,y1-ny*w*.76)
 love.graphics.setColor(.98,.54,.49,.55)
 love.graphics.setLineWidth(math.max(.16,w*.065))
 for i=-2,2 do
  local offset=i*w*.23
  love.graphics.line(px+dx*.14+nx*offset*.25,py+dy*.14+ny*offset*.25,
    px+dx*.5+nx*offset,py+dy*.5+ny*offset,
    px+dx*.86+nx*offset*.25,py+dy*.86+ny*offset*.25)
 end
 love.graphics.setColor(.94,.81,.68,.9)
 love.graphics.setLineWidth(math.max(.18,w*.12))
 love.graphics.line(px,py,px+dx*.14,py+dy*.14)
 love.graphics.line(px+dx*.86,py+dy*.86,qx,qy)
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
 local external=on('External') or on('Skin');if external and o.alive and o.behavior and o.behavior~='Resting' then a=require('anatomical_rendering').pose(a,t or 0) end;local tint=require('rendering_legacy').pigment(a.pigment)
 love.graphics.push('all');love.graphics.translate(x,y);if top then love.graphics.rotate(o.angle or 0) end;love.graphics.scale(scale)
 require('tissue_surface').draw(a,tint,top,external and 1 or .09)
 for _,c in ipairs(a.components) do if c.volume>.0000000001 then
  local xx,yy=point(c,top);local color=colors[c.type] or {.58,.69,.71};local isSupport=c.type=='Bone' or c.type=='Support' or c.type=='Carapace'
  if on('Skeleton') and isSupport then
   -- Rib arches and girdles are transverse 3-D structures. Their top-view
   -- outlines collapse into overlapping spikes in the side projection.
   -- Render those structures in plan view only until a dedicated lateral
   -- rib/girdle silhouette is available. Never reuse top-view geometry
   -- as if it were a side-view bone.
   local transverse=c.anatomicalName=='protective rib arch'
      or c.anatomicalName=='shoulder / axial girdle'
      or c.anatomicalName=='pelvic girdle'
      or c.anatomicalName=='orbital rim'
   if top or not transverse then
    boneShape(c.path or {},top,math.max(.55,(c.thickness or .1)*23),color)
   end
   if c.parent then local p=a.components[c.parent];local px,py=point(p,top);love.graphics.setColor(color[1],color[2],color[3],.4);love.graphics.setLineWidth(.45);love.graphics.line(px,py,xx,yy) end
  elseif on('Muscle') and c.type=='Muscle' then
   local p,q=a.components[c.origin],a.components[c.insertion];local px,py=point(p,top);local qx,qy=point(q,top);local width=math.sqrt(c.volume*32^3/math.max(1,math.sqrt((px-qx)^2+(py-qy)^2))*math.pi)*.6
   muscleShape(px,py,xx,yy,qx,qy,width*.58)
  elseif on('Fat') and c.type=='Fat' then
   local r=a.regions[c.regionId];fatLayer(a,r,c.volume,top)
  elseif on('Organs') and (c.type=='Heart' or c.type=='Lung' or c.type=='Stomach' or c.type=='Brain' or c.type=='Kidney' or c.type=='Gonad') then love.graphics.setColor(color);love.graphics.ellipse('fill',xx,yy,math.max(.1,c.rx),math.max(.1,c.ry));love.graphics.setColor(.95,.94,.84,.7);love.graphics.setLineWidth(.3);love.graphics.ellipse('line',xx,yy,math.max(.1,c.rx),math.max(.1,c.ry))
  elseif on('Organs') and c.type=='Gill' then path({{x=c.cx-c.rx*.4,y=c.cy,z=c.cz},{x=c.cx+c.rx*.4,y=c.cy,z=c.cz}},top,.8,{.35,.75,.91}) end
  if (on('External') or on('Nervous')) and c.type=='Sensor' then local r=a.regions[c.regionId];if r.partType=='cranium' then love.graphics.setColor(.96,.97,.77);love.graphics.circle('fill',xx,yy,math.max(.15,1.5*c.growth));love.graphics.setColor(.035,.10,.13);love.graphics.circle('fill',xx+.3,yy,math.max(.1,.8*c.growth)) end end
  if c.condition<.7 then love.graphics.setColor(.8,.15,.17,.8);love.graphics.circle('fill',xx,yy,.8) end
 end end
 if on('Nervous') then for _,n in ipairs(a.nerves) do if (n.growth or 1)>.01 then local p,q=a.components[n.from],a.components[n.to];local px,py=point(p,top);local qx,qy=point(q,top);love.graphics.setColor(.74,.53,.97,.9);love.graphics.setLineWidth(.35+math.min(.45,n.efficiency*.5));love.graphics.line(px,py,(px+qx)/2,(py+qy)/2,qx,qy) end end end
 if on('Organs') then for _,v in ipairs(a.vessels) do local p,q=a.components[v.from],a.components[v.to];if p.growth>.01 and q.growth>.01 then local px,py=point(p,top);local qx,qy=point(q,top);love.graphics.setColor(.82,.22,.27,.5);love.graphics.setLineWidth(.4);love.graphics.line(px,py,qx,qy) end end end
 if external then for _,c in ipairs(a.surfaces) do local r=a.regions[c.regionId];if c.growth>.01 then local host=a.regions[r.parent or r.id];local xx,yy=point(r,top);local px,py=point(host,top);love.graphics.setColor(.42,.75,.73,.35);love.graphics.polygon('fill',px,py,xx,yy,xx+math.sin(r.orientation)*r.width,yy-math.cos(r.orientation)*r.width) end end end
 if on('Skeleton') then for _,j in ipairs(a.joints) do if j.growth>.02 then love.graphics.setColor(.97,.65,.25);love.graphics.setLineWidth(.45);love.graphics.circle('line',j.cx,top and j.cy or -j.cz,math.max(.3,1.3*j.growth)) end end end
 if selected and a.regions[selected] then local r=a.regions[selected];love.graphics.setColor(.3,.95,.8,.9);love.graphics.setLineWidth(.5);love.graphics.line(r.x-4,r.y,r.x+4,r.y);love.graphics.line(r.x,r.y-4,r.x,r.y+4) end
 love.graphics.pop()
end
return V
