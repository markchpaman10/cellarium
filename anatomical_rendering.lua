local V={};local colors={Bone={.89,.85,.68},Support={.63,.75,.70},Carapace={.7,.73,.59},Muscle={.74,.29,.35},Fat={.94,.78,.43},Heart={.83,.22,.31},Lung={.84,.57,.65},Stomach={.64,.57,.33},Brain={.72,.52,.86},Nerve={.66,.49,.96},Sensor={.92,.97,.75}}
local function pos(p,top) return p.cx or p.x,top and (p.cy or 0) or -(p.cz or -p.y) end
function V.pose(a,t,angleProvider)
 local G=require('genome');local regions,components,joints=G.copy(a.regions),G.copy(a.components),G.copy(a.joints);local transforms={};local byPart={}
 for _,j in ipairs(joints) do byPart[j.partId]=j end
 local function point(m,x,y) return m.c*x-m.s*y+m.x,m.s*x+m.c*y+m.y end
 for i,r in ipairs(regions) do
  local parent=r.parent and transforms[r.parent] or {c=1,s=0,x=0,y=0,angle=0};local m={c=parent.c,s=parent.s,x=parent.x,y=parent.y,angle=parent.angle};local j=byPart[i]
  if j then local requested=angleProvider and angleProvider(r,j) or math.sin(t*2+i*.7)*math.min(.16,j.range*.18);local angle=math.max(j.minimum,math.min(j.maximum,requested))*j.condition;local ax,ay=point(parent,j.cx,-j.cz);local c,s=math.cos(angle),math.sin(angle);m={c=c*parent.c-s*parent.s,s=s*parent.c+c*parent.s,x=ax+c*(parent.x-ax)-s*(parent.y-ay),y=ay+s*(parent.x-ax)+c*(parent.y-ay),angle=parent.angle+angle};j.playbackAngle=angle;j.x,j.y=ax,ay;j.cx,j.cz=ax,-ay end
  transforms[i]=m;r.x,r.y=point(m,r.x,r.y);r.cx,r.cz=r.x,-r.y;r.orientation=r.orientation+m.angle
  for _,key in ipairs({'start','finish'}) do if r[key] then local px,py=point(m,r[key].x,-r[key].z);r[key].x,r[key].z=px,-py end end
  if r.parent then local p=regions[r.parent];local source=a.regions[r.parent];local ax,ay=point(parent,source.cx+r.attachment.x,-source.cz-r.attachment.z);r.attachment.x,r.attachment.z=ax-p.cx,-ay-p.cz end
 end
 for _,c in ipairs(components) do local m=transforms[c.regionId];c.x,c.y=point(m,c.x,c.y);c.cx,c.cz=c.x,-c.y;c.orientation=c.orientation+m.angle;if c.path then for _,pt in ipairs(c.path) do local px,py=point(m,pt.x,-pt.z);pt.x,pt.z=px,-py end end end
 local posed={regions=regions,parts=regions,components=components,joints=joints}
 for _,name in ipairs({'structures','muscles','fat','skin','organs','sensors','surfaces','gills','mouths','projections'}) do if a[name] then posed[name]={};for _,c in ipairs(a[name]) do posed[name][#posed[name]+1]=components[c.id] end end end
 return setmetatable(posed,{__index=a})
end
local function shape(r,top,factor)
 local x,y=pos(r,top);local angle=top and r.start and r.finish and math.atan2(r.finish.y-r.start.y,r.finish.x-r.start.x) or top and 0 or r.orientation
 local l=r.length*.5;local tissue=(r.tissues.Muscle or 0)+(r.tissues.Fat or 0);local contour=.86+math.min(.22,tissue/math.max(.000001,r.volume)*.42);local h=(top and r.width or r.thickness)*.5*(factor or 1)*contour;local vertices={}
 for i=0,20 do local u=-1+i/10;local profile=math.sqrt(math.max(0,1-u*u));if r.shape=='taper' or r.shape=='hook' then profile=profile*(1-u*(r.taper or .3)*.7) elseif r.shape=='jaw' then profile=profile*.7 end
  local bend=(r.curvature or 0)*(1-u*u)*h;local xx=x+math.cos(angle)*u*l-math.sin(angle)*bend;local yy=y+math.sin(angle)*u*l+math.cos(angle)*bend
  vertices[#vertices+1]={xx-math.sin(angle)*h*profile,yy+math.cos(angle)*h*profile};vertices[#vertices+1]={xx+math.sin(angle)*h*profile,yy-math.cos(angle)*h*profile}
 end
 return love.graphics.newMesh(vertices,'strip','stream')
end
local function connection(a,r,top)
 if not r.parent then return end;local p=a.regions[r.parent];local x,y=pos(r,top);local px,py=pos(p,top);local ax=px+(r.attachment and r.attachment.x or 0);local ay=py+(top and (r.attachment and r.attachment.y or 0) or -(r.attachment and r.attachment.z or 0));local dx,dy=x-ax,y-ay;local len=math.sqrt(dx*dx+dy*dy);if len<.01 then return end
 local width=math.min(top and r.width or r.thickness,top and p.width or p.thickness)*.32;local nx,ny=-dy/len*width,dx/len*width
 love.graphics.polygon('fill',ax+nx,ay+ny,x+nx,y+ny,x-nx,y-ny,ax-nx,ay-ny)
end
function V.draw(o,x,y,scale,t,layer,selected,top)
 local a=o.anatomy;layer=layer or 'External';local combined=type(layer)=='table';local function on(name) return combined and layer[name] or not combined and layer==name end
 local external=on('External') or on('Skin');local tint=require('rendering_legacy').pigment(a.pigment or .5)
 if external and o.alive and o.behavior and o.behavior~='Resting' and t then a=V.pose(a,t) end
 love.graphics.push('all');love.graphics.translate(x,y);if top then love.graphics.rotate(o.angle or 0) end;love.graphics.scale(scale)
 -- Connected lofts share the same source regions and attachment bridges in every layer.
 love.graphics.setColor(tint[1]*.65,tint[2]*.65,tint[3]*.65,external and 1 or .10)
 for _,r in ipairs(a.regions) do connection(a,r,top);love.graphics.draw(shape(r,top)) end
 if external then
  for _,r in ipairs(a.regions) do local flesh=(r.tissues.Muscle or 0)+(r.tissues.Fat or 0);local volume=math.max(.00001,r.volume);local fill=.78+math.min(.20,flesh/volume*.35)
   love.graphics.setColor(tint[1]*.92,tint[2]*.92,tint[3]*.92,1);love.graphics.draw(shape(r,top,fill))
   if r.partType=='lower_jaw' then local xx,yy=pos(r,top);love.graphics.setColor(.12,.18,.19);love.graphics.setLineWidth(.7);love.graphics.line(xx-r.length*.3,yy,xx+r.length*.4,yy) end
  end
 end
 for _,c in ipairs(a.components) do
  local show=on('Skeleton') and (c.type=='Bone' or c.type=='Carapace' or c.type=='Support') or on('Muscle') and c.type=='Muscle' or on('Fat') and c.type=='Fat' or on('Organs') and (c.type=='Heart' or c.type=='Lung' or c.type=='Stomach' or c.type=='Brain') or on('Nervous') and (c.type=='Brain' or c.type=='Nerve')
  local xx,yy=pos(c,top)
  if show then local color=colors[c.type] or {.7,.7,.6};love.graphics.setColor(color[1],color[2],color[3],c.condition)
   if c.type=='Muscle' or c.type=='Bone' or c.type=='Support' or c.type=='Carapace' or c.type=='Fat' then
    local r=a.regions[c.regionId];if c.parent and a.components[c.parent] then local px,py=pos(a.components[c.parent],top);love.graphics.setLineWidth(c.type=='Muscle' and math.max(1,r.thickness*.22) or math.max(.8,c.thickness or 1));love.graphics.line(px,py,xx,yy) end
    love.graphics.draw(shape(r,top,c.type=='Muscle' and .48 or c.type=='Fat' and .65 or .17))
   else love.graphics.ellipse('fill',xx,yy,c.rx,c.ry) end
  end
  if c.type=='Sensor' and (external or on('Nervous')) then love.graphics.setColor(.91,.96,.75);love.graphics.circle('fill',xx,yy,1.8);love.graphics.setColor(.04,.13,.18);love.graphics.circle('fill',xx+.4,yy,.85) end
 end
 if on('Nervous') then for _,n in ipairs(a.nerves or {}) do local p,q=a.components[n.from],a.components[n.to];local px,py=pos(p,top);local qx,qy=pos(q,top);love.graphics.setColor(.7,.5,.95,.8);love.graphics.setLineWidth(.55);love.graphics.line(px,py,qx,qy) end end
 if on('Skeleton') then for _,j in ipairs(a.joints or {}) do local xx,yy=pos(j,top);love.graphics.setColor(.98,.68,.27);love.graphics.circle('line',xx,yy,1.8) end end
 if selected and a.regions[selected] then local r=a.regions[selected];love.graphics.setColor(.1,.85,.7,.45);love.graphics.draw(shape(r,top,1.1)) end
 love.graphics.pop()
end
return V
