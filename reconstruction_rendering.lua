local V={};local colors={Bone={.92,.86,.67},Support={.44,.76,.70},Carapace={.68,.75,.56},Muscle={.76,.24,.32},Fat={.96,.76,.37},Heart={.9,.25,.32},Lung={.89,.57,.68},Stomach={.55,.74,.46},Brain={.77,.58,.94},Kidney={.68,.36,.32},Gonad={.85,.66,.39}}
local function point(p,top) return p.cx or p.x,top and (p.cy or 0) or -(p.cz or -p.y) end
local function path(points,top,width,color)
 local coords={};for _,pt in ipairs(points) do coords[#coords+1]=pt.x;coords[#coords+1]=top and pt.y or -pt.z end
 if #coords>=4 then love.graphics.setColor(color);love.graphics.setLineWidth(math.max(.2,width));love.graphics.setLineJoin('bevel');love.graphics.line(coords) end
end
function V.draw(o,x,y,scale,t,layer,selected,top)
 local a=o.anatomy;layer=layer or 'External';local function on(k) return type(layer)=='table' and layer[k] or type(layer)~='table' and layer==k end
 local external=on('External') or on('Skin');if external and o.alive and o.behavior and o.behavior~='Resting' then a=require('anatomical_rendering').pose(a,t or 0) end;local tint=require('rendering_legacy').pigment(a.pigment)
 love.graphics.push('all');love.graphics.translate(x,y);if top then love.graphics.rotate(o.angle or 0) end;love.graphics.scale(scale)
 require('tissue_surface').draw(a,tint,top,external and 1 or .09)
 for _,c in ipairs(a.components) do if c.volume>.0000000001 then
  local xx,yy=point(c,top);local color=colors[c.type] or {.58,.69,.71};local isSupport=c.type=='Bone' or c.type=='Support' or c.type=='Carapace'
  if on('Skeleton') and isSupport then
   path(c.path or {},top,math.max(.35,c.thickness*20),color)
   if c.parent then local p=a.components[c.parent];local px,py=point(p,top);love.graphics.setColor(color[1],color[2],color[3],.4);love.graphics.setLineWidth(.45);love.graphics.line(px,py,xx,yy) end
  elseif on('Muscle') and c.type=='Muscle' then
   local p,q=a.components[c.origin],a.components[c.insertion];local px,py=point(p,top);local qx,qy=point(q,top);local width=math.sqrt(c.volume*32^3/math.max(1,math.sqrt((px-qx)^2+(py-qy)^2))*math.pi)*.6
   local points={px,py,xx,yy-width,qx,qy,xx,yy+width};love.graphics.setColor(color[1],color[2],color[3],.85);love.graphics.polygon('fill',points);love.graphics.setColor(.97,.58,.58,.75);love.graphics.setLineWidth(.35);love.graphics.line(px,py,xx,yy,qx,qy)
  elseif on('Fat') and c.type=='Fat' then
   local r=a.regions[c.regionId];local rad=math.sqrt(c.volume*32^3/math.max(1,r.length*math.pi));path({{x=xx-math.cos(r.orientation)*r.length*.35,y=c.cy,z=c.cz+math.sin(r.orientation)*r.length*.35},{x=xx+math.cos(r.orientation)*r.length*.35,y=c.cy,z=c.cz-math.sin(r.orientation)*r.length*.35}},top,math.max(.3,rad*2),{.94,.75,.39,.85})
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
