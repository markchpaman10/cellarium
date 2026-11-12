-- One implicit skin envelope over actual structural/muscle/fat/organ volumes.
-- GPU smooth union avoids stamping an oval at each anatomical region.
local M={};local shader
local source=[[
extern Image anatomyTexture;
extern int spanCount;
extern vec4 bodyBounds;
extern vec3 pigment;
extern float alpha;
float covering;
float field(vec2 p) {
 float d=100000.0;
 for(int i=0;i<1024;i++) { if(i>=spanCount) break;
  vec4 span=Texel(anatomyTexture,vec2((float(i)+.5)/1024.0,.25));vec4 tip=Texel(anatomyTexture,vec2((float(i)+.5)/1024.0,.75));vec2 a=span.xy;vec2 b=tip.xy;vec2 ab=b-a;
  float t=clamp(dot(p-a,ab)/max(.00001,dot(ab,ab)),0.0,1.0);
  float r=mix(span.z,tip.z,t);
  float n=length(p-a-t*ab)-r;
  float k=min(2.4,r*.42);float h=max(k-abs(d-n),0.0)/max(.00001,k);
  if(n<d) covering=span.w;d=min(d,n)-h*h*k*.25;
 }
 return d;
}
vec4 effect(vec4 color,Image tex,vec2 uv,vec2 screen) {
 vec2 p=bodyBounds.xy+uv*bodyBounds.zw;float d=field(p);float armor=covering;
 float coverage=1.0-smoothstep(-.4,.4,d);if(coverage<=0.0) discard;
 float normal=field(p+vec2(0.0,-.7))-field(p+vec2(0.0,.7));
 float light=.76+normal*.13;float edge=smoothstep(-1.8,-.3,d);
 float plate=armor>.28 ? step(.76,fract((p.x+floor(p.y/3.0)*2.0)/5.0))*.12*armor : 0.0;vec3 c=pigment*light*(1.0-edge*.34-plate);
 return vec4(c,coverage*alpha)*color;
}
]]
function M.geometry(a,top)
 local spans,tips={},{};local byRegion={};local armor={};for _,c in ipairs(a.skin) do if c.surface=='dorsal' then armor[c.regionId]=(c.armor or 0)*c.condition end end
 local function add(x,y,bx,by,ra,rb,armor,depth) if #spans>=1024 then return end;spans[#spans+1]={x,y,math.max(.00001,ra),armor or 0};tips[#tips+1]={bx,by,math.max(.00001,rb),depth or 0} end
 for _,r in ipairs(a.regions) do
  local volume=0;for _,v in pairs(r.tissues) do volume=volume+v end
  local radius=math.sqrt(math.max(0,volume)*32^3/math.max(.001,r.length*math.pi));local h=top and r.width or r.thickness;radius=math.min(h*.55,radius*(r.cavityAllowed and 1.25 or 1.05))
  if volume>0 and radius>.003 then
   local x,y=r.cx,top and r.cy or -r.cz;local angle=top and r.start and r.finish and math.atan2(r.finish.y-r.start.y,r.finish.x-r.start.x) or top and 0 or r.orientation
   local extent=r.length*.34;if top and r.start and r.finish then extent=math.sqrt((r.finish.x-r.start.x)^2+(r.finish.y-r.start.y)^2)*.34 end
   local dx,dy=math.cos(angle)*extent,math.sin(angle)*extent;local taper=r.partType=='claw' or r.partType=='tail' or r.partType=='horn' or r.partType=='spike'
   add(x-dx,y-dy,x+dx,y+dy,radius,radius*(taper and .15 or r.partType=='snout' and .55 or .9),armor[r.id] or 0,r.cy);byRegion[r.id]={x=x,y=y,radius=radius}
   local parent=r.parent and byRegion[r.parent]
   if parent then local at=r.attachment;local p=a.regions[r.parent];local ax,ay=p.cx+at.x,top and p.cy+at.y or -p.cz-at.z
    local trunk=(r.partType=='abdomen' or r.partType=='pelvis' or r.partType=='trunk');if trunk then add(parent.x,parent.y,x,y,parent.radius*.95,radius*.95) else local bridge=math.min(parent.radius,radius)*.8;add(parent.x,parent.y,ax,ay,bridge,bridge);add(ax,ay,x-dx,y-dy,bridge,radius*.85) end
   end
  end
 end;return spans,tips
end
function M.draw(a,tint,top,alpha)
 shader=shader or love.graphics.newShader(source);local spans,tips=M.geometry(a,top);if #spans==0 then return end
 local b=a.bounds;local minx,miny,maxx,maxy=b.minx,b.miny,b.maxx,b.maxy
 if top then minx,miny,maxx,maxy=1e6,1e6,-1e6,-1e6;for i,p in ipairs(spans) do local q=tips[i];minx=math.min(minx,p[1]-p[3]-3,q[1]-q[3]-3);maxx=math.max(maxx,p[1]+p[3]+3,q[1]+q[3]+3);miny=math.min(miny,p[2]-p[3]-3,q[2]-q[3]-3);maxy=math.max(maxy,p[2]+p[3]+3,q[2]+q[3]+3) end end
 local data=love.image.newImageData(1024,2,'rgba32f');for i,p in ipairs(spans) do data:setPixel(i-1,0,unpack(p));data:setPixel(i-1,1,unpack(tips[i])) end;local texture=love.graphics.newImage(data);texture:setFilter('nearest','nearest');shader:send('spanCount',#spans);shader:send('anatomyTexture',texture);shader:send('bodyBounds',{minx,miny,maxx-minx,maxy-miny});shader:send('pigment',tint);shader:send('alpha',alpha or 1)
 local mesh=love.graphics.newMesh({{minx,miny,0,0},{maxx,miny,1,0},{maxx,maxy,1,1},{minx,maxy,0,1}},'fan','stream');love.graphics.setShader(shader);love.graphics.setColor(1,1,1);love.graphics.draw(mesh);love.graphics.setShader()
end
return M
