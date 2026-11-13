local M=require('desktop_model');local T=require('desktop_samples');local V=require('vessels');local G=require('genome');local Worlds=require('desktop_worlds');local Store=require('desktop_store');local Native=require('native_windows');local Art=require('desktop_art')
local Host={windows={},canvases={},timer=0,monitorTimer=0,exiting=false,panelVisible=false,inspector=nil,mode='laboratory'}
function Host.state() return Host.context.getState() end
function Host.message(text) Host.notice=text;if Host.context then Host.context.msg(text) end;if not Host.panelVisible and Native.tray and not Host.testing and (not Host.lastNotice or love.timer.getTime()-Host.lastNotice>2) then Native.notify(text);Host.lastNotice=love.timer.getTime() end end
local function vesselKind(v) return ({'dish','flask','plate','vial','cryovial'})[v.kind] end
function Host.sync()
 local s=Host.state();local d=M.ensure(s);V.ensure(s);Worlds.ensure(s);require('physical_cells').ensure(s)
 local present={};for _,o in ipairs(d.objects) do present[o.kind..'/'..tostring(o.entityId)]=o end
 local function add(kind,id,group,x,y) if not present[kind..'/'..tostring(id)] then local o=M.add(s,kind,id,group,x,y);M.restore(o,Host.monitors);M.remember(o,Host.monitors);present[kind..'/'..tostring(id)]=o end end
 local primary=Host.monitors[1];local x,y=primary.x+25,primary.y+25
 for i,v in ipairs(s.vessels) do add(vesselKind(v),v.id,'laboratory',x+((i-1)%4)*210,y+math.floor((i-1)/4)*205) end
 for i,v in ipairs(s.materials) do add('dna',v.id,'laboratory',x+820+(i-1)%4*85,y+40+math.floor((i-1)/4)*190) end
 for i,kind in ipairs({'dropper','rack','forge','workstation'}) do add(kind,kind,'laboratory',x+(i-1)*280,y+460) end
 for i,world in ipairs(d.worlds) do if world.kind~='desktop' then add(world.kind,world.id,'habitats',x+(i-1)*435,y+690) end end
 for _,organism in ipairs(s.organisms) do if organism.worldId=='desktop' then add('organism',organism.id,'organisms',x+organism.x*600,y+organism.y*300) end end
 local existing={};for _,o in ipairs(d.objects) do existing[o.id]=true end;for id,win in pairs(Host.windows) do if not existing[id] then Native.destroy(win);Host.windows[id]=nil;Host.canvases[id]=nil end end
 local live={};for _,v in ipairs(s.vessels) do live[vesselKind(v)..'/'..v.id]=true end;for _,v in ipairs(s.materials) do live['dna/'..v.id]=true end
 for _,o in ipairs(d.objects) do
  require('desktop_controls').prepare(o)
  local stale=(o.kind=='dish' or o.kind=='flask' or o.kind=='plate' or o.kind=='vial' or o.kind=='cryovial' or o.kind=='dna') and not live[o.kind..'/'..o.entityId]
  if o.kind=='organism' then stale=true;for _,v in ipairs(s.organisms) do if v.id==o.entityId and v.worldId=='desktop' then stale=false end end end
  if stale then o.visible=false;o.archivedEntity=true end
  if not Host.windows[o.id] then Host.windows[o.id]=Native.create(o) end
 end
end
function Host.init(context)
 Host.context=context;Host.monitors=Native.init();if not Host.monitors then Host.context=nil;context.setState(nil);love.event.quit();return false end;assert(#Host.monitors>0,'No usable Windows monitor.')
 local restored,why=Store.load(context.B)
 if restored then context.setState(restored);Host.message(restored.desktop.recovery or 'Desktop laboratory restored.') elseif love.filesystem.getInfo('desktop-laboratory.lua') then Host.message('Saved laboratory could not load: '..tostring(why)..'. Original retained; automatic overwrites disabled.');Host.saveBlocked=true end
 local s=Host.state();M.ensure(s);require('realtime').start(s);s.desktop.tool=nil;Worlds.ensure(s);V.ensure(s)
 s.desktop.starterPrepared=true
 Host.sync()
 for _,o in ipairs(s.desktop.objects) do M.restore(o,Host.monitors) end
 Host.context.setDesktopActive(true);Native.panel(false);Host.panelVisible=false
 Host.render(true)
 -- Default launch shows only native equipment and tray, never the classic UI.
end
function Host.open(mode,id)
 Host.mode=mode or 'laboratory';Host.inspector=id
 Host.panelVisible=true;Native.panel(true);Host.context.open(mode,id)
end
function Host.hidePanel() Host.panelVisible=false;Native.panel(false) end
function Host.save()
 if Host.context and require('realtime').hasSession(Host.state()) then require('realtime').observe(Host.state()) end
 if Host.saveBlocked then Host.message('Automatic saving is disabled after load failure. Use New or import a valid experiment first.');return false end
 local ok,why=Store.save(Host.state());Host.message(ok and 'Desktop laboratory saved atomically.' or 'Save failed: '..tostring(why));return ok
end
function Host.toggle(group)
 local s=Host.state();local d=M.ensure(s);M.setGroup(s,group,not d.groups[group]);Host.render(true)
end
function Host.beginDispense(o)
 local s=Host.state();if require('realtime').busy(s) then Host.message('Synchronizing elapsed PC time. Please wait.');return false end;if Host.droplet then Host.message('A sample is already being dispensed.');return false end
 local ok,why=T.canDispense(s,o.entityId);if not ok then Host.message(why);return false end
 Host.droplet={target=o.id,entity=o.entityId,time=0,duration=.45};s.desktop.animation={target=o.id,progress=0};return true
end
function Host.tray()
 local d=M.ensure(Host.state());local items={
  {label='Show Laboratory',checked=d.groups.laboratory,action=function() Host.toggle('laboratory') end},
  {label='Show Habitats',checked=d.groups.habitats,action=function() Host.toggle('habitats') end},
  {label='Show Desktop Organisms',checked=d.groups.organisms,action=function() Host.toggle('organisms') end},{separator=true},
  {label='Research & Cryobank',action=function() Host.open('research') end},{label='Genome Database',action=function() Host.open('genomes') end},{label='Organism Records',action=function() Host.open('organisms') end},
  {separator=true},{label='Save Laboratory + Layout',action=function() d.savedLayout=M.layout(Host.state());Host.save() end},
  {label='Restore Saved Layout',action=function() if d.savedLayout then M.applyLayout(Host.state(),d.savedLayout,Host.monitors) else Host.message('No saved layout yet.') end end},
  {label='Reset Layout...',action=function() if Native.confirm('Reset object positions? Cultures and organisms will be retained.') then M.reset(Host.state(),Host.monitors) end end},
  {label='Restore Objects from Storage',action=function() for _,o in ipairs(d.objects) do if not o.archivedEntity then o.stored=false;o.visible=true end end end},
  {separator=true},{label='Settings & Object Manager',action=function() Host.open('settings') end},{label='About Cellarium',action=function() Native.alert('Cellarium / Windows Desktop Laboratory\nLocal procedural artwork and biological simulation.\nCtrl+Shift+L hides equipment and opens recovery controls.\nRight-click equipment for actions. No administrator privileges required.') end},
  {label='Exit Cellarium',action=function() Host.exiting=true;love.event.quit() end}}
 table.insert(items,1,{label='Buy supplies...',action=function() require('desktop_supply_menus').buy(Host.state()) end});table.insert(items,2,{label='Retrieve frozen cells...',action=function() require('desktop_supply_menus').frozen(Host.state()) end})
 local action=Native.menu(items);if action then action() end
end
function Host.objectMenu(o)
 local Controls=require('desktop_controls')
 if Controls.isContainer(o) then
  local s=Host.state();local items={{label='Show contents',action=function() Controls.expand(s,o);Host.render(true) end}}
  if T.vessel(s,o.entityId) then items[#items+1]={label=s.desktop.pipette.sample and 'Add held sample here' or 'Take sample from this container',action=function() if s.desktop.pipette.sample then Host.beginDispense(o) else local _,why=T.collect(s,o.entityId);Host.message(why) end end} end
  items[#items+1]={label=o.locked and 'Unlock position' or 'Lock position',checked=o.locked,action=function() o.locked=not o.locked end}
  items[#items+1]={label='Put away this container',action=function() o.stored=true end}
  local action=Native.menu(items);if action then if not require('realtime').sync(s,require('biology').update) then Host.message('Synchronizing elapsed PC time. Please wait.') else action() end end;return
 end
 local s=Host.state();local v=T.vessel(s,o.entityId);local items={{label='Inspect / Open',action=function() if o.kind=='forge' or o.kind=='workstation' or v then require('desktop_controls').expand(s,o);Host.render(true) else Host.open('inspect',o.id) end end},
  {label=o.locked and 'Unlock position' or 'Lock position',checked=o.locked,action=function() o.locked=not o.locked end},
  {label='Scale +',action=function() o.scale=math.min(1.8,o.scale+.1);M.restore(o,Host.monitors) end},{label='Scale -',action=function() o.scale=math.max(.5,o.scale-.1) end},
  {label='Bring forward',action=function() local n=0;for _,other in ipairs(s.desktop.objects) do n=math.max(n,other.layer) end;o.layer=n+1 end},
  {label='Send backward',action=function() o.layer=-1 end},{label='Return to storage',action=function() o.stored=true end}}
 if v then
  table.insert(items,1,{label='Use dropper: '..(s.desktop.pipette.sample and 'dispense here' or 'collect 1 cell eq.'),action=function() if s.desktop.pipette.sample then Host.beginDispense(o) else local _,why=T.collect(s,v.id);Host.message(why) end end})
  items[#items+1]={label=v.closed and 'Open container' or 'Close container',action=function() v.closed=not v.closed end}
 elseif o.kind=='dropper' then
  items[#items+1]={label='Freeze contents into storage',action=function() local _,why=T.freezeLoaded(s);Host.message(why) end};items[#items+1]={label='Retrieve frozen cells...',action=function() require('desktop_supply_menus').frozen(s) end}
  items[#items+1]={label='Collect sample beneath tip',action=function() local target=Host.targetAtTip(o);if target then local _,why=T.collect(s,target.entityId);Host.message(why) else Host.message('Position the tip inside an open cell container first.') end end}
  items[#items+1]={label='Sterilize dropper',action=function() local _,why=T.clean(s);Host.message(why) end};items[#items+1]={label='Discard loaded sample...',action=function() if Native.confirm('Dispose of the loaded biological sample?') then s.desktop.pipette.sample=nil;Host.message('Sample discarded. Sterilize before reuse.') end end}
 end
 local action=Native.menu(items);if action then if not require('realtime').sync(s,require('biology').update) then Host.message('Synchronizing elapsed PC time. Please wait.') else action() end end
end
function Host.targetAtTip(o)
 local s=Host.state();local mon=M.monitorAt(Host.monitors,o.x,o.y);local factor=o.scale*mon.dpi/96;local tipx,tipy=o.x+44*factor,o.y+214*factor;local target
 for _,candidate in ipairs(s.desktop.objects) do if candidate.id~=o.id and T.vessel(s,candidate.entityId) and M.isVisible(s.desktop,candidate) then local m=M.monitorAt(Host.monitors,candidate.x,candidate.y);local lx,ly=M.localPoint(candidate,m,tipx,tipy);local inside=lx>=0 and ly>=0 and lx<candidate.w and ly<candidate.h;if candidate.kind=='dish' and not candidate.config.expanded then inside=(lx-118)^2+(ly-112)^2<91^2 end;if inside then target=candidate end end end
 return target
end
function Host.click(o,x,y)
 local s=Host.state();s.desktop.selectedObject=o.id
 if o.kind=='dropper' then Host.open('inspect',o.id);return end
 if o.kind=='forge' or o.kind=='workstation' or require('desktop_controls').isContainer(o) then require('desktop_controls').expand(s,o);Host.render(true)
 elseif o.group=='habitats' then local best,bd;for _,organism in ipairs(s.organisms) do if organism.worldId==o.entityId then local px,py=18+organism.x*(o.w-36),29+organism.y*(o.h-64);local dist=(px-x)^2+(py-y)^2;if not bd or dist<bd then best=organism;bd=dist end end end;if best and bd<35^2 then s.desktop.selectedOrganism=best.id end;Host.open('inspect',o.id)
 elseif o.kind=='organism' then s.desktop.selectedOrganism=o.entityId;Host.open('organism',o.entityId)
 else Host.open('inspect',o.id) end
end
function Host.event(e)
 local s=Host.state();local o=e.id and M.find(s,e.id)
 if e.type=='trayMenu' then Host.tray() elseif e.type=='openPanel' then Host.open('research') elseif e.type=='exit' then Host.exiting=true;love.event.quit()
 elseif e.type=='recovery' then M.setGroup(s,'laboratory',false);M.setGroup(s,'habitats',false);M.setGroup(s,'organisms',false);Host.open('settings')
 elseif e.type=='displays' then Host.monitors=Native.monitors();for _,v in ipairs(s.desktop.objects) do if not v.drag then M.restore(v,Host.monitors) end end
 elseif o then
  local monitor=M.monitorAt(Host.monitors,o.x,o.y);local factor=o.scale*monitor.dpi/96;local x,y=(e.x or 0)/factor,(e.y or 0)/factor
  if e.type=='down' then local control=require('desktop_controls').hit(o,x,y);Host.pressed={id=o.id,x=e.cursor.x,y=e.cursor.y,moved=false,control=control};s.desktop.selectedObject=o.id;s.desktop.tool=nil;if not control and not M.beginDrag(o,e.cursor) then Host.message('Position is locked. Right-click and choose Unlock position.') end
  elseif e.type=='move' and Host.pressed and Host.pressed.id==o.id then if math.abs(e.cursor.x-Host.pressed.x)+math.abs(e.cursor.y-Host.pressed.y)>5 then Host.pressed.moved=true end;if o.drag and Host.pressed.moved then if o.config.workshop then require('workshop_docking').detach(s,o.id) end;M.drag(o,e.cursor);Native.move(Host.windows[o.id],o.x,o.y);if o.kind=='workstation' then require('workshop_docking').layout(s,o,Host.monitors);for _,child in ipairs(s.desktop.objects) do if child.config.workshop==o.id and Host.windows[child.id] then Native.move(Host.windows[child.id],child.x,child.y) end end end end
  elseif e.type=='up' then
   local pressed=Host.pressed;Host.pressed=nil;M.endDrag(o,Host.monitors)
   if pressed and pressed.control then local current=require('desktop_controls').hit(o,x,y);if not pressed.moved and current and current.id==pressed.control.id then if not require('realtime').sync(s,require('biology').update) then Host.message('Synchronizing elapsed PC time. Please wait before changing biology.') else pressed.control.fn() end;Host.render(true) end
   elseif pressed and not pressed.moved then Host.click(o,x,y)
   elseif o.kind=='dropper' and s.desktop.pipette.sample then
    local target=Host.targetAtTip(o)
    if target then Host.beginDispense(target) end
   elseif require('desktop_controls').isContainer(o) then
    local hit,ok,why=require('workshop_docking').drop(s,o,e.cursor,Host.monitors);if hit then Host.message(why);Host.render(true);return end
    if o.kind=='vial' or o.kind=='cryovial' or o.kind=='dna' then for _,rack in ipairs(s.desktop.objects) do if rack.kind=='rack' then local rw,rh=M.dimensions(rack,M.monitorAt(Host.monitors,rack.x,rack.y));if e.cursor.x>=rack.x and e.cursor.x<rack.x+rw and e.cursor.y>=rack.y and e.cursor.y<rack.y+rh then o.config.rack=rack.id;o.config.slot=math.max(1,math.min(8,math.floor((e.cursor.x-rack.x)/rw*8)+1));break else o.config.rack=nil end end end end
   end
  elseif e.type=='objectMenu' then
   if Host.pressed then local moving=M.find(s,Host.pressed.id);if moving then M.endDrag(moving,Host.monitors) end;Host.pressed=nil end;Native.endPointer();s.desktop.tool=nil;Host.objectMenu(o)
  elseif e.type=='hide' then o.stored=true elseif e.type=='wheel' then o.scale=math.max(.5,math.min(1.8,o.scale+(e.delta>0 and .1 or -.1)));M.restore(o,Host.monitors) end
 end
end
function Host.render(force)
 local s=Host.state();if not s or not s.desktop then return end
 for _,station in ipairs(s.desktop.objects) do if station.kind=='workstation' then require('workshop_docking').layout(s,station,Host.monitors) end end
 table.sort(s.desktop.objects,function(a,b) return a.layer<b.layer end)
 for _,o in ipairs(s.desktop.objects) do local win=Host.windows[o.id]
  if win then if M.isVisible(s.desktop,o) then
   local mon=M.monitorAt(Host.monitors,o.x,o.y);local factor=o.scale*mon.dpi/96
   local canvas,data=Art.render(s,o,factor,Host.canvases[o.id]);Host.canvases[o.id]=canvas
   Native.present(win,data,o.x,o.y,s.desktop.settings.alwaysOnTop,o.layer)
  else Native.hide(win) end end
 end
end
function Host.update(dt)
 if Host.context then require('physical_cells').ensure(Host.state()) end
 if not Host.context then return end
 for _,e in ipairs(Native.pump()) do Host.event(e) end
 local s=Host.state();local d=M.ensure(s)
 -- SDL can release capture for a non-SDL, nonactivating tool window. Track only
 -- the gesture begun on our equipment; poll while held so it crosses boundaries.
 if Host.pressed and not Host.testing then
  local o=M.find(s,Host.pressed.id);if o then local cursor,held=Native.pointer();local event={type=held and 'move' or 'up',id=o.id,cursor=cursor,x=cursor.x-o.x,y=cursor.y-o.y};Host.event(event);if not held then Native.endPointer() end else Host.pressed=nil;Native.endPointer() end
 end
 for _,o in ipairs(d.objects) do if o.config.rack and not o.drag then local rack=M.find(s,o.config.rack);if rack and M.isVisible(d,rack) then local f=rack.scale*(M.monitorAt(Host.monitors,rack.x,rack.y).dpi/96);o.x=rack.x+(22+(o.config.slot or 1)*32)*f-47*o.scale;o.y=rack.y+53*f-160*o.scale end end end
 for _,o in ipairs(d.objects) do if o.kind=='organism' and not o.drag then for _,v in ipairs(s.organisms) do if v.id==o.entityId and v.alive then local last=o.config.lastPosition or {x=v.x,y=v.y};o.x=o.x+(v.x-last.x)*1000;o.y=o.y+(v.y-last.y)*700;o.config.lastPosition={x=v.x,y=v.y};M.restore(o,Host.monitors,true) end end end end
 if Host.droplet then Host.droplet.time=Host.droplet.time+dt;d.animation={target=Host.droplet.target,progress=math.min(1,Host.droplet.time/Host.droplet.duration)};if Host.droplet.time>=Host.droplet.duration then local _,why=T.dispense(s,Host.droplet.entity);Host.message(why);Host.droplet=nil;d.animation=nil end end
 Host.timer=Host.timer+dt;Host.monitorTimer=Host.monitorTimer+dt
 if Host.monitorTimer>3 then Host.monitorTimer=0;local monitors=Native.monitors();if require('persistence').encode(monitors)~=require('persistence').encode(Host.monitors) then Host.monitors=monitors;for _,o in ipairs(d.objects) do if not o.drag then M.restore(o,monitors) end end end;Host.sync() end
 if Host.timer>.1 then Host.timer=0;Host.render() end
end
function Host.shutdown()
 if not Host.context then return end
 if require('realtime').hasSession(Host.state()) then require('realtime').observe(Host.state()) end
 if not Host.saveBlocked then local ok,why=Store.save(Host.state());if not ok then Native.alert('Cellarium could not save: '..tostring(why)..'\nThe previous save has been retained.') end end
 Native.shutdown();Host.context=nil
end
return Host
