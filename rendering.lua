local Legacy=require('rendering_legacy');local M=require('silhouette');local R={layers=Legacy.layers,cache=setmetatable({},{__mode='k'})}
R.layers={'External','Skin','Muscle','Fat','Skeleton','Organs','Nervous','Defenses'}
R.pigment=Legacy.pigment;R.init=Legacy.init
function R.fitScale(a,w,h,preferred)
 if a.version~=3 then return preferred end
 return math.min(preferred,w/(a.bounds.width+20),h/(a.bounds.height+20))
end
function R.position(c,t,animate) return c.x,c.y end
local function build(a,frame,method)
 local phase=(frame-1)/4*math.pi*2;local pose=M.pose(a,phase,method);local map=M.raster(a,pose);local data=love.image.newImageData(map.width,map.height);local tint=R.pigment(a.pigment);local texture=a.parameters[15]
 for index in pairs(map.pixels) do
  local x,y=index%map.width,math.floor(index/map.width);local edge=not map.pixels[index-1] or not map.pixels[index+1] or not map.pixels[index-map.width] or not map.pixels[index+map.width]
  local cover;local distance;for i,r in ipairs(pose) do local d=((x+map.x-r.x)/r.rx)^2+((y+map.y-r.y)/r.ry)^2;if not distance or d<distance then distance=d;cover=a.skin[i] end end;local surface=cover and cover.covering;local localTexture=surface=='scales' and .8 or surface=='carapace' and .65 or surface=='soft skin' and .15 or texture
  local shade=.8-(y/map.height)*.17;local noise=(x*13+y*7)%23
  if edge then shade=not map.pixels[index-map.width] and 1.15 or .34
  elseif localTexture<.34 and noise==0 then shade=shade*.78
  elseif localTexture<.68 and (x+y)%9<2 then shade=shade*1.08
  elseif localTexture>=.68 and (x+math.floor(y/3)*3)%8==0 then shade=shade*.72 end
  data:setPixel(x,y,math.min(1,tint[1]*shade),math.min(1,tint[2]*shade),math.min(1,tint[3]*shade),1)
 end
 local img=love.graphics.newImage(data);img:setFilter('nearest','nearest');return {image=img,x=map.x,y=map.y,pose=pose}
end
function R.draw(o,x,y,scale,t,layer,selected,top)
 local a=o.anatomy;if a.anatomicalVersion==2 and a.growthModel and a.growthModel.progress<.23 then local state=require('embryology').evaluate(a.seed or 1,a.growthModel.progress);return require('embryology').draw(state,x,y,math.max(.4,scale*2)) end;if a.anatomicalVersion==2 then return require('reconstruction_rendering').draw(o,x,y,scale,t,layer,selected,top) end;if a.anatomicalVersion then return require('anatomical_rendering').draw(o,x,y,scale,t,layer,selected) end;if a.version~=3 then return Legacy.draw(o,x,y,scale,t,layer,selected) end
 if not next(Legacy.tiles) then Legacy.init() end
 layer=layer or 'External';local animate=layer=='External' and o.alive and o.behavior~='Resting' and a.caps.locomotion~='stationary';local method=animate and (o.caps and o.caps.locomotion or a.caps.locomotion) or nil
 local frame=animate and math.floor((t or 0)*3+(o.phase or 0))%4+1 or 1;local key=(method or 'static')..frame;local cache=R.cache[a];if not cache then cache={};R.cache[a]=cache end
 if not cache[key] then cache[key]=build(a,frame,method) end;local sprite=cache[key];local alpha=o.alive and 1 or .35
 love.graphics.push();love.graphics.translate(math.floor(x),math.floor(y));if layer=='External' then scale=scale*(.65+.35*(o.maturity or 1)) end;love.graphics.scale(scale,scale)
 if layer=='External' and math.cos(o.angle or 0)<0 then love.graphics.scale(-1,1) end
 local function surfaces()
  for _,v in ipairs(a.surfaces or {}) do if v.type=='Membrane' then love.graphics.setColor(.37,.69,.64,.55*alpha);love.graphics.polygon('fill',v.aX,v.aY,v.bX,v.bY,v.x+math.cos(v.orientation+1.57)*v.ry,v.y+math.sin(v.orientation+1.57)*v.ry+((o.altitude or 0)>.08 and math.sin((t or 0)*7)*3 or 0)) else love.graphics.setColor(.3,.64,.7,.55*alpha);love.graphics.ellipse('fill',v.x,v.y,v.rx,v.ry) end end
 end
 local function projections()
  for _,p in ipairs(a.projections or {}) do local angle=p.geometryAngle or 0;local dx,dy=math.cos(angle),math.sin(angle);local length=p.length or 3;local width=p.width or 1;love.graphics.setColor(.82,.80,.57,alpha*p.condition);love.graphics.polygon('fill',p.x-dy*width/2,p.y+dx*width/2,p.x+dy*width/2,p.y-dx*width/2,p.x+dx*length,p.y+dy*length) end
 end
 if layer=='External' or layer=='Skin' then
  surfaces()
  love.graphics.setColor(.01,.02,.025,alpha*.5);love.graphics.draw(sprite.image,sprite.x+1,sprite.y+3)
  love.graphics.setColor(1,1,1,alpha);love.graphics.draw(sprite.image,sprite.x,sprite.y)
  projections()
  for _,sensor in ipairs(a.sensors) do local region=a.regions[sensor.regionId];local posed=sprite.pose[sensor.regionId];local xx,yy=sensor.x+posed.x-region.x,sensor.y+posed.y-region.y
   love.graphics.setColor(.92,.98,.84,alpha*sensor.condition);love.graphics.rectangle('fill',math.floor(xx-1.5),math.floor(yy-1.5),3,3);love.graphics.setColor(.03,.11,.16,alpha);love.graphics.rectangle('fill',math.floor(xx),math.floor(yy-.5),1,2)
  end
 else
  love.graphics.setColor(1,1,1,.12*alpha);love.graphics.draw(sprite.image,sprite.x,sprite.y)
  local function tile(c)
   love.graphics.setColor(1,1,1,alpha);local size=math.max(2,c.size or 8);local kind=c.type=='Support' or c.type=='Carapace' and 'Bone' or c.type
   if c.type=='Support' or c.type=='Carapace' then kind='Bone' end
   local image=Legacy.tiles[kind];if image then love.graphics.draw(image,c.x,c.y,c.orientation or 0,size/16,size/16,8,8) end
   if c.condition<.7 then love.graphics.setColor(.8,.15,.2,.8);love.graphics.rectangle('fill',c.x-1,c.y-1,2,2) end
  end
  if layer=='Skeleton' then
   for _,c in ipairs(a.structures) do if c.parent then local p=a.components[c.parent];love.graphics.setColor(c.type=='Bone' and .83 or .4,.78,.59,alpha);love.graphics.setLineWidth(math.max(1,c.thickness*.45));love.graphics.line(p.x,p.y,c.x,c.y) end;tile(c) end
   for _,j in ipairs(a.joints) do local c=a.components[j.child];love.graphics.setColor(.98,.78,.42,alpha);love.graphics.rectangle('fill',c.x-1.5,c.y-1.5,3,3) end
  elseif layer=='Muscle' then for _,m in ipairs(a.muscles) do local p=a.components[m.origin];love.graphics.setColor(.65,.25,.3,.8);love.graphics.setLineWidth(math.max(1,m.mass));love.graphics.line(p.x,p.y,m.x,m.y);tile(m) end
  elseif layer=='Fat' then for _,c in ipairs(a.fat) do tile(c) end
  elseif layer=='Defenses' then projections()
  elseif layer=='Organs' then for _,v in ipairs(a.vessels) do local p,q=a.components[v.from],a.components[v.to];love.graphics.setColor(.75,.2,.3,.55);love.graphics.setLineWidth(1);love.graphics.line(p.x,p.y,q.x,q.y) end;for _,c in ipairs(a.organs) do tile(c) end;for _,gi in ipairs(a.gills or {}) do love.graphics.setColor(.42,.73,.91,alpha);love.graphics.rectangle('fill',gi.x-gi.rx,gi.y-2,gi.rx*2,4) end
  elseif layer=='Nervous' then for _,v in ipairs(a.nerves) do local p,q=a.components[v.from],a.components[v.to];love.graphics.setColor(.76,.56,.96,.8);love.graphics.setLineWidth(1);love.graphics.line(p.x,p.y,q.x,q.y) end;for _,c in ipairs(a.organs) do if c.type=='Brain' then tile(c) end end;for _,c in ipairs(a.sensors) do love.graphics.setColor(.93,.85,.52);love.graphics.rectangle('fill',c.x-1,c.y-1,2,2) end end
 end
 if selected and a.components[selected] then local c=a.components[selected];love.graphics.setColor(.45,1,.77);love.graphics.setLineWidth(.5);love.graphics.ellipse('line',c.x,c.y,math.max(3,c.rx or 5),math.max(3,c.ry or 5)) end
 love.graphics.pop();love.graphics.setColor(1,1,1);love.graphics.setLineWidth(1)
end
function R.drawTopDown(o,x,y,scale,t)
 if o.anatomy.anatomicalVersion==2 and o.anatomy.growthModel and o.anatomy.growthModel.progress<.23 then return R.draw(o,x,y,scale,t,'External') end
 if o.anatomy.anatomicalVersion==2 then return require('reconstruction_rendering').draw(o,x,y,scale,t,'External',nil,true) end
 if o.anatomy.anatomicalVersion then return require('anatomical_rendering').draw(o,x,y,scale,t,'External',nil,true) end
 love.graphics.push();love.graphics.translate(x,y);love.graphics.rotate(o.angle or 0)
 local projection=setmetatable({angle=0},{__index=o});R.draw(projection,0,0,scale,t,'External');love.graphics.pop()
end
return R
