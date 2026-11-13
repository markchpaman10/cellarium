-- Back-to-front desktop order. A workshop and its docked vessels form one group.
local M=require('desktop_model');local Z={}
function Z.groups(s)
 local objects=M.ensure(s).objects;local byId,groups={},{}
 for _,o in ipairs(objects) do byId[o.id]=o end
 local function root(o) local p=o.config and byId[o.config.workshop];return p and p.kind=='workstation' and p or o end
 for _,o in ipairs(objects) do if root(o)==o then groups[#groups+1]={root=o,members={}} end end
 table.sort(groups,function(a,b) if a.root.layer==b.root.layer then return a.root.id<b.root.id end;return (a.root.layer or 0)<(b.root.layer or 0) end)
 local map={};for _,g in ipairs(groups) do map[g.root.id]=g end
 for _,o in ipairs(objects) do local r=root(o);if r~=o then map[r.id].members[#map[r.id].members+1]=o end end
 for _,g in ipairs(groups) do table.sort(g.members,function(a,b) local x=a.config.dockSlot=='input' and 1 or 2;local y=b.config.dockSlot=='input' and 1 or 2;if x==y then return a.id<b.id end;return x<y end) end
 return groups
end
function Z.ordered(s)
 local ordered={};for _,g in ipairs(Z.groups(s)) do ordered[#ordered+1]=g.root;for _,o in ipairs(g.members) do ordered[#ordered+1]=o end end;return ordered
end
function Z.move(s,id,direction)
 local object=M.find(s,id);if not object then return false end
 local parent=M.find(s,object.config.workshop);local root=parent and parent.kind=='workstation' and parent.id or id;local groups=Z.groups(s);local index
 for i,g in ipairs(groups) do if g.root.id==root then index=i;break end end;if not index then return false end
 local destination=direction=='front' and #groups or direction=='back' and 1 or direction=='raise' and math.min(#groups,index+1) or math.max(1,index-1)
 local group=table.remove(groups,index);table.insert(groups,destination,group);local n=0
 for _,g in ipairs(groups) do n=n+1;g.root.layer=n;for _,o in ipairs(g.members) do n=n+1;o.layer=n end end;return true
end
function Z.menu(s,o)
 local items={};for _,entry in ipairs({{'Bring to front','front'},{'Raise one layer','raise'},{'Lower one layer','lower'},{'Send to back','back'}}) do local how=entry[2];items[#items+1]={label=entry[1],action=function() Z.move(s,o.id,how);require('desktop_host').render(true) end} end;return items
end
return Z
