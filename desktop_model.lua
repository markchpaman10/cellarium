-- Persistent presentation records. Positions are signed physical desktop pixels;
-- dimensions are device-independent pixels. Preferred placement survives unplugging.
local M={version=1}
M.sizes={dish={236,236},flask={150,220},plate={240,160},vial={94,190},cryovial={94,190},dna={94,190},dropper={88,238},rack={320,118},forge={268,210},workstation={270,205},terrarium={430,320},freshwater={390,300},saltwater={390,300},organism={150,150}}
local function copy(v) return require('genome').copy(v) end
function M.ensure(s)
 s.desktop=s.desktop or {version=1,objects={},groups={laboratory=true,habitats=true,organisms=true},nextObject=1,settings={alwaysOnTop=false},pipette={capacity=1,clean=true},worlds={}}
 return s.desktop
end
function M.add(s,kind,entity,group,x,y)
 local d=M.ensure(s);local id='desktop-'..d.nextObject;d.nextObject=d.nextObject+1;local size=assert(M.sizes[kind])
 local o={id=id,kind=kind,entityId=entity,group=group or 'laboratory',x=x or 40,y=y or 40,w=size[1],h=size[2],scale=1,visible=true,locked=false,layer=d.nextObject,stored=false,config={}}
 d.objects[#d.objects+1]=o;return o
end
function M.find(s,id) for _,o in ipairs(M.ensure(s).objects) do if o.id==id then return o end end end
function M.isVisible(d,o) return o.visible and not o.stored and d.groups[o.group]~=false end
function M.setGroup(s,group,visible) local d=M.ensure(s);d.groups[group]=visible;return true end
function M.monitorAt(monitors,x,y)
 local best,dist
 for _,m in ipairs(monitors) do if x>=m.x and x<m.x+m.w and y>=m.y and y<m.y+m.h then return m end;local dx=math.max(m.x-x,0,x-m.x-m.w);local dy=math.max(m.y-y,0,y-m.y-m.h);local dd=dx*dx+dy*dy;if not dist or dd<dist then best=m;dist=dd end end
 return best
end
function M.dimensions(o,monitor) local dpi=monitor and monitor.dpi or 96;return math.floor(o.w*o.scale*dpi/96+.5),math.floor(o.h*o.scale*dpi/96+.5) end
function M.remember(o,monitors)
 local m=M.monitorAt(monitors,o.x,o.y);if not m then return end
 o.monitor=m.id;o.preferred={monitor=m.id,x=o.x,y=o.y,dx=(o.x-m.x)/(m.dpi/96),dy=(o.y-m.y)/(m.dpi/96),dpi=m.dpi}
end
function M.restore(o,monitors,currentOnly)
 local p=o.preferred;local m
 if p and not currentOnly then for _,v in ipairs(monitors) do if v.id==p.monitor then m=v;break end end end
 if m then o.x=m.x+p.dx*m.dpi/96;o.y=m.y+p.dy*m.dpi/96 else m=M.monitorAt(monitors,o.x,o.y) end
 if not m then return end
 local w,h=M.dimensions(o,m)
 o.x=math.floor(math.max(m.x,math.min(m.x+math.max(0,m.w-w),o.x)));o.y=math.floor(math.max(m.y,math.min(m.y+math.max(0,m.h-h),o.y)));o.monitor=m.id
 -- Do not change o.preferred here: fallback is temporary.
end
function M.beginDrag(o,cursor) if o.locked then return false end;o.drag={dx=cursor.x-o.x,dy=cursor.y-o.y};return true end
function M.drag(o,cursor) if o.drag then o.x=cursor.x-o.drag.dx;o.y=cursor.y-o.drag.dy;return true end end
function M.endDrag(o,monitors) if o.drag then o.drag=nil;M.remember(o,monitors) end end
function M.localPoint(o,monitor,x,y) local factor=o.scale*(monitor and monitor.dpi or 96)/96;return (x-o.x)/factor,(y-o.y)/factor end
function M.layout(s) local d=M.ensure(s);local result={groups=copy(d.groups),objects={}};for _,o in ipairs(d.objects) do local c=copy(o);c.drag=nil;result.objects[#result.objects+1]=c end;return result end
function M.applyLayout(s,layout,monitors)
 local d=M.ensure(s);d.groups=copy(layout.groups)
 local saved={};for _,o in ipairs(layout.objects) do saved[o.id]=o end
 for _,o in ipairs(d.objects) do local prior=saved[o.id];if prior then for _,k in ipairs({'x','y','w','h','scale','visible','locked','layer','stored','monitor','preferred'}) do o[k]=copy(prior[k]) end;M.restore(o,monitors) end end
end
function M.reset(s,monitors)
 local m=monitors[1];if not m then return end
 for i,o in ipairs(M.ensure(s).objects) do o.x=m.x+30+((i-1)%5)*170;o.y=m.y+30+math.floor((i-1)/5)*150;o.scale=math.min(1,math.max(.55,m.w/1600));o.visible=true;o.stored=false;o.drag=nil;M.restore(o,monitors,true);M.remember(o,monitors) end
end
return M
