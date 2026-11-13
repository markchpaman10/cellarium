local R={tiles={},layers={'External','Skin','Muscle','Fat','Skeleton','Organs','Nervous'}}
local colors={Skin={.7,.85,.68},Muscle={.87,.37,.40},Fat={.95,.77,.35},Bone={.88,.87,.69},Heart={.95,.25,.38},Lung={.45,.78,.89},Stomach={.84,.65,.28},Brain={.72,.51,.89},Blank={0,0,0}}
local function color(c,k,a) love.graphics.setColor(c[1]*k,c[2]*k,c[3]*k,a or 1) end
function R.init()
 love.graphics.setDefaultFilter('nearest','nearest')
 for kind,c in pairs(colors) do
  local canvas=love.graphics.newCanvas(16,16);love.graphics.setCanvas(canvas);love.graphics.clear(0,0,0,0)
  if kind~='Blank' then
   color(c,.3);love.graphics.rectangle('fill',2,1,12,14);love.graphics.rectangle('fill',1,3,14,10)
   color(c,.72);love.graphics.rectangle('fill',3,2,10,12);love.graphics.rectangle('fill',2,4,12,8)
   color(c,1);love.graphics.rectangle('fill',4,3,7,8);color(c,1.12);love.graphics.rectangle('fill',4,3,5,2)
   color(c,.45)
   if kind=='Skin' then
    love.graphics.clear(0,0,0,0);color(c,.86);love.graphics.rectangle('fill',0,0,16,16)
    color(c,.8);love.graphics.rectangle('fill',3,8,2,2);love.graphics.rectangle('fill',11,3,2,1)
    color(c,.95);love.graphics.rectangle('fill',7,5,2,1);love.graphics.rectangle('fill',12,12,2,1)
   elseif kind=='Bone' then love.graphics.clear(0,0,0,0);color(c,.45);love.graphics.rectangle('fill',1,5,14,6);color(c,.95);love.graphics.rectangle('fill',1,6,14,4);love.graphics.rectangle('fill',2,4,3,8);love.graphics.rectangle('fill',11,4,3,8);color(c,.65);love.graphics.rectangle('fill',5,9,6,1)
   elseif kind=='Muscle' then for y=4,12,3 do color(c,.45);love.graphics.rectangle('fill',3,y,10,1);color(c,1);love.graphics.rectangle('fill',4,y+1,8,1) end
   elseif kind=='Fat' then for i=0,2 do color(c,.8+i*.08);love.graphics.rectangle('fill',3+i*3,4+(i%2)*3,3,5) end
   elseif kind=='Heart' then color(c,.4);love.graphics.rectangle('fill',7,2,2,4);love.graphics.rectangle('fill',4,7,7,1);love.graphics.rectangle('fill',9,8,2,5)
   elseif kind=='Lung' then color(c,.4);love.graphics.rectangle('fill',7,1,2,12);love.graphics.rectangle('fill',3,7,9,1);love.graphics.rectangle('fill',4,4,1,7);love.graphics.rectangle('fill',11,4,1,7)
   elseif kind=='Stomach' then color(c,.4);love.graphics.rectangle('fill',9,1,2,5);love.graphics.rectangle('fill',5,11,2,4)
   elseif kind=='Brain' then color(c,.4);love.graphics.rectangle('fill',7,3,1,10);love.graphics.rectangle('fill',3,6,3,1);love.graphics.rectangle('fill',9,8,4,1);love.graphics.rectangle('fill',4,10,3,1) end
  end
  love.graphics.setCanvas();R.tiles[kind]=canvas
 end
end
function R.pigment(p)
 local stops={{.40,.86,.65},{.39,.69,.94},{.83,.51,.87},{.96,.63,.35}};local n=p*3;local i=math.min(3,math.floor(n)+1);local f=n-(i-1);local a,b=stops[i],stops[i+1];return {a[1]*(1-f)+b[1]*f,a[2]*(1-f)+b[2]*f,a[3]*(1-f)+b[3]*f}
end
function R.position(c,t,animate)
 if c.region=='limb' and animate then return c.x+math.floor(math.sin(t*5+c.x*.13+(c.side or 1))*2*(c.segment or 1)),c.y end;return c.x,c.y
end
function R.draw(o,x,y,scale,t,layer,selectedComponent)
 if not next(R.tiles) then R.init() end;layer=layer or 'External';local a=o.anatomy;local tint=R.pigment(a.pigment);local animate=layer=='External' and o.alive and o.behavior~='Resting';local alpha=o.alive and 1 or .32
 if layer=='External' then scale=scale*(.65+.35*(o.maturity or 1)) end
 love.graphics.push();love.graphics.translate(math.floor(x),math.floor(y));love.graphics.scale(scale,scale)
 -- Upright component tiles preserve crisp pixels. Body heading flips the connected layout.
 if layer=='External' and math.cos(o.angle or 0)<0 then love.graphics.scale(-1,1) end
 local function tile(c,faded)
  local xx,yy=R.position(c,t,animate);if c.type=='Skin' then local shade=1-math.max(0,c.y)/(a.width*16)*.65;love.graphics.setColor(tint[1]*shade,tint[2]*shade,tint[3]*shade,alpha*(faded or 1)) else love.graphics.setColor(1,1,1,alpha*(faded or 1)) end
  if c.type=='Skin' and c.region=='limb' then love.graphics.draw(R.tiles.Skin,xx-4,yy-7,0,.5,.875) else love.graphics.draw(R.tiles[c.type] or R.tiles.Blank,xx-8,yy-8) end
  if c.condition<.8 then love.graphics.setColor(.4,.08,.11,.8);love.graphics.rectangle('fill',xx-2,yy-2,4,3) end
 end
 local showBones=layer=='Skeleton';local showOrgans=layer=='Organs';local showNerves=layer=='Nervous'
 if layer=='External' or layer=='Skin' then
  for _,b in ipairs(a.bones) do if b.region=='limb' then local parent=a.components[b.parent];local xx,yy=R.position(b,t,animate);local px,py=R.position(parent,t,animate);love.graphics.setColor(tint[1]*.5,tint[2]*.5,tint[3]*.5,alpha);love.graphics.setLineWidth(7);love.graphics.line(px,py,xx,yy) end end
  for _,c in ipairs(a.skin) do tile(c) end
  -- Outline only exposed surfaces, so neighboring body components join seamlessly.
  for _,c in ipairs(a.skin) do
   local xx,yy=R.position(c,t,animate)
   if c.region~='limb' then for _,dir in ipairs({{-1,0},{1,0},{0,-1},{0,1}}) do local neighbor=false;for _,other in ipairs(a.skin) do if other~=c and math.abs(other.x-(c.x+dir[1]*16))<1 and math.abs(other.y-(c.y+dir[2]*16))<1 then neighbor=true;break end end
    if not neighbor then love.graphics.setColor(tint[1]*.4,tint[2]*.4,tint[3]*.4,alpha);if dir[1]~=0 then love.graphics.rectangle('fill',xx+(dir[1]<0 and -8 or 7),yy-8,1,16) else love.graphics.rectangle('fill',xx-8,yy+(dir[2]<0 and -8 or 7),16,1) end end
   end end
  end
  for _,b in ipairs(a.bones) do if b.region=='limb' and b.segment==2 then local xx,yy=R.position(b,t,animate);love.graphics.setColor(.78,.8,.59,alpha);love.graphics.rectangle('fill',xx-3,yy+(b.side>0 and 6 or -8),2,3);love.graphics.rectangle('fill',xx+1,yy+(b.side>0 and 6 or -8),2,3) end end
  local brain;for _,c in ipairs(a.organs) do if c.type=='Brain' then brain=c end end
  if brain then for _,side in ipairs({-1,1}) do love.graphics.setColor(.91,.98,.87,alpha);love.graphics.rectangle('fill',brain.x+2,side*(a.width==3 and 4 or 11)-2,5,5);love.graphics.setColor(.05,.12,.17,alpha);love.graphics.rectangle('fill',brain.x+5,side*(a.width==3 and 4 or 11)-1,2,3) end;love.graphics.setColor(.08,.16,.18,alpha);love.graphics.rectangle('fill',brain.x+5,-2,3,4) end
 else
  for _,c in ipairs(a.skin) do tile(c,.09) end
  if showBones then
   for _,b in ipairs(a.bones) do if b.parent then local p=a.components[b.parent];love.graphics.setColor(.65,.68,.53,alpha);love.graphics.setLineWidth(3);love.graphics.line(p.x,p.y,b.x,b.y) end;tile(b) end
   for _,j in ipairs(a.joints) do local b=a.components[j.child];love.graphics.setColor(.99,.83,.43,alpha);love.graphics.rectangle('fill',b.x-2,b.y-2,4,4) end
  elseif layer=='Muscle' then for _,m in ipairs(a.muscles) do local p=a.components[m.origin];love.graphics.setColor(.54,.23,.28,alpha);love.graphics.setLineWidth(4);love.graphics.line(p.x,p.y,m.x,m.y);tile(m) end
  elseif layer=='Fat' then for _,c in ipairs(a.fat) do tile(c) end
  elseif showOrgans then
   for _,v in ipairs(a.vessels) do local p,q=a.components[v.from],a.components[v.to];love.graphics.setColor(.7,.22,.3,.4);love.graphics.setLineWidth(1);love.graphics.line(p.x,p.y,q.x,q.y) end
   for _,c in ipairs(a.organs) do tile(c) end
  elseif showNerves then
   for _,v in ipairs(a.nerves) do local p,q=a.components[v.from],a.components[v.to];love.graphics.setColor(.72,.56,.96,.8);love.graphics.setLineWidth(1);love.graphics.line(p.x,p.y,q.x,q.y);love.graphics.rectangle('fill',q.x-1,q.y-1,2,2) end
   for _,c in ipairs(a.organs) do if c.type=='Brain' then tile(c) end end
  end
 end
 if selectedComponent then local c=a.components[selectedComponent];if c then love.graphics.setColor(.55,1,.8);love.graphics.setLineWidth(.5);love.graphics.rectangle('line',c.x-9,c.y-9,18,18) end end
 love.graphics.pop();love.graphics.setLineWidth(1);love.graphics.setColor(1,1,1)
end
return R
