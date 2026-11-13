-- One physical vial per slot; shared geometry for artwork, snapping and layout.
local M=require('desktop_model');local Rack={capacity=8,spacing=106,padding=70,slotY=54}
local function eligible(o) return o.kind=='vial' or o.kind=='cryovial' or o.kind=='dna' end
function Rack.detach(o) o.config.rack=nil;o.config.slot=nil end
function Rack.layout(s,rack,monitors)
 local monitor=M.monitorAt(monitors,rack.x,rack.y);local factor=rack.scale*(monitor and monitor.dpi or 96)/96
 local children={};local occupied={};local spacing=Rack.spacing
 for _,o in ipairs(M.ensure(s).objects) do if o.config.rack==rack.id then children[#children+1]=o end end
 table.sort(children,function(a,b) return a.id<b.id end)
 for _,o in ipairs(children) do
  local slot=math.floor(tonumber(o.config.slot) or 0)
  if not eligible(o) or o.config.workshop then Rack.detach(o)
  else
   if slot<1 or slot>Rack.capacity or occupied[slot] then slot=nil;for i=1,Rack.capacity do if not occupied[i] then slot=i;break end end end
   if not slot then Rack.detach(o) else occupied[slot]=o;o.config.slot=slot;local width=M.dimensions(o,monitor);spacing=math.max(spacing,width/factor+12) end
  end
 end
 local width=Rack.padding*2+(Rack.capacity-1)*spacing;local resize=rack.w~=width or rack.config.rackUI~=2
 rack.config.slotSpacing=spacing;rack.config.rackUI=2;rack.w=width;rack.h=130
 if resize then M.restore(rack,monitors,true);M.remember(rack,monitors) end
 for slot,o in pairs(occupied) do if not o.drag then
  local childFactor=o.scale*(monitor and monitor.dpi or 96)/96
  o.x=math.floor(rack.x+(Rack.padding+(slot-1)*spacing)*factor-47*childFactor)
  o.y=math.floor(rack.y+Rack.slotY*factor-160*childFactor);M.remember(o,monitors)
 end end
 return occupied
end
function Rack.layoutAll(s,monitors) for _,o in ipairs(M.ensure(s).objects) do if o.kind=='rack' then Rack.layout(s,o,monitors) end end end
function Rack.drop(s,o,cursor,monitors)
 if not eligible(o) then return false end
 local ordered=require('desktop_depth').ordered(s)
 for i=#ordered,1,-1 do local rack=ordered[i]
  if rack.kind=='rack' and M.isVisible(s.desktop,rack) then
   local occupied=Rack.layout(s,rack,monitors);local x,y=M.localPoint(rack,M.monitorAt(monitors,rack.x,rack.y),cursor.x,cursor.y)
   if x>=0 and x<rack.w and y>=0 and y<rack.h then
    local nearest,distance
    for slot=1,Rack.capacity do if not occupied[slot] or occupied[slot]==o then local d=math.abs(x-(Rack.padding+(slot-1)*rack.config.slotSpacing));if not distance or d<distance then nearest,distance=slot,d end end end
    if not nearest then return true,false,'Sample rack is full. The vial remains separate.' end
    require('desktop_controls').collapse(s,o);Rack.detach(o);o.config.rack=rack.id;o.config.slot=nearest;Rack.layout(s,rack,monitors);return true,true,'Vial placed in sample rack slot '..nearest..'.'
   end
  end
 end
 return false
end
return Rack
