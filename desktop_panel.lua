local Host=require('desktop_host');local M=require('desktop_model');local T=require('desktop_samples');local V=require('vessels');local Worlds=require('desktop_worlds');local G=require('genome');local P={page=1,cell=1,organism=1,query='',searching=false,sort=1,filter='all'}
function P.textinput(t) if P.naming then P.name=(P.name..t):sub(1,45);return true elseif P.searching then P.query=(P.query..t):sub(1,45);return true end end
function P.keypressed(k,s)
 if P.naming then if k=='return' then local o=M.find(s,Host.inspector);local v=o and T.vessel(s,o.entityId);if v then v.label=P.name else if o then o.config.label=P.name end end;P.naming=false elseif k=='escape' then P.naming=false elseif k=='backspace' then P.name=P.name:sub(1,-2) end;return true end
 if P.searching then if k=='return' or k=='escape' then P.searching=false elseif k=='backspace' then P.query=P.query:sub(1,-2) end;return true end
 return false
end
function P.draw(s,c)
 local text,button,panel,msg,C=c.text,c.button,c.panel,c.msg,c.C
 local function result(ok,why) msg(why or (ok and 'Done.' or 'Unavailable.')) end
 local d=M.ensure(s);panel(32,202,345,650);text('DESKTOP OBJECTS',50,224,16,C.mint)
 button('Search: '..P.query..(P.searching and '_' or ''),49,256,310,31,function() P.searching=true end)
 button('Group: '..P.filter,49,295,150,29,function() P.filter=({all='laboratory',laboratory='habitats',habitats='organisms',organisms='all'})[P.filter];P.page=1 end)
 button(P.sort==1 and 'Sort: kind' or 'Sort: ID',208,295,150,29,function() P.sort=P.sort%2+1 end)
 local objects={};for _,o in ipairs(d.objects) do if not o.archivedEntity and (P.filter=='all' or o.group==P.filter) and (o.kind..' '..o.id..' '..tostring(o.entityId)..' '..(o.config.label or '')):lower():find(P.query:lower(),1,true) then objects[#objects+1]=o end end
 table.sort(objects,function(a,b) if P.sort==1 and a.kind~=b.kind then return a.kind<b.kind end;return a.id<b.id end)
 P.page=math.min(P.page,math.max(1,math.ceil(#objects/12)))
 for row=0,11 do local o=objects[(P.page-1)*12+row+1];if o then button((o.stored and '[stored] ' or '')..o.kind..' / '..o.id,49,337+row*33,309,29,function() Host.inspector=o.id;Host.mode='inspect' end,Host.inspector==o.id) end end
 button('<',49,749,60,30,function() P.page=math.max(1,P.page-1) end);button('>',298,749,60,30,function() P.page=math.min(math.max(1,math.ceil(#objects/12)),P.page+1) end);text(P.page..' / '..math.max(1,math.ceil(#objects/12)),180,757,12)
 button('Hide panel to tray',49,799,309,32,function() Host.hidePanel() end)
 panel(397,202,1011,650)
 if Host.mode=='settings' or not Host.inspector then
  text('Your desktop is the laboratory.',423,230,28);text('Rims and frames move equipment. Interior clicks inspect. Right-click opens object actions.',423,276,14,C.muted)
  for i,g in ipairs({'laboratory','habitats','organisms'}) do button((d.groups[g] and 'Hide ' or 'Show ')..g,423+(i-1)*310,320,290,38,function() Host.toggle(g) end,d.groups[g]) end
  button('Save experiment + layout',423,381,290,37,function() d.savedLayout=M.layout(s);Host.save() end)
  button('Restore saved layout',733,381,290,37,function() if d.savedLayout then M.applyLayout(s,d.savedLayout,Host.monitors) else msg('No saved layout yet.') end end)
  button('Reset layout...',1043,381,290,37,function() if require('native_windows').confirm('Reset equipment positions? Biological contents will be retained.') then M.reset(s,Host.monitors) end end)
  button('Always on top: '..tostring(d.settings.alwaysOnTop),423,443,290,37,function() d.settings.alwaysOnTop=not d.settings.alwaysOnTop end,d.settings.alwaysOnTop)
  button('Restore all stored objects',733,443,290,37,function() for _,o in ipairs(d.objects) do if not o.archivedEntity then o.stored=false;o.visible=true end end end)
  button('Offline cap: '..d.settings.offlineCap..' sec',1043,443,290,37,function() d.settings.offlineCap=d.settings.offlineCap==300 and 60 or d.settings.offlineCap==60 and 0 or 300 end)
  text('PERSISTENCE / desktop schema 1',423,515,14,C.mint)
  text('This desktop revision saves on exit and restores on launch in its own save folder.\nOffline catch-up is bounded to at most 3 simulation hours (5 real minutes).\nBiology continues while equipment or the detailed window is hidden.\nCtrl+Shift+L hides all objects and opens this recovery panel.\nClosing this window returns to the tray. Use Exit in the tray or Ctrl+Q to quit.',423,550,15,C.muted)
  text('Monitors detected: '..#Host.monitors,423,696,15,C.mint)
  for i,m in ipairs(Host.monitors) do text(m.id..'  '..m.w..'x'..m.h..'  ('..m.x..', '..m.y..')  '..m.dpi..' DPI',423,724+(i-1)*23,12,C.muted) end
  return
 end
 local o=M.find(s,Host.inspector);if not o then return end
 text((o.config.label or o.kind):upper()..' / '..o.id,423,226,22,C.mint)
 text(string.format('Position %d, %d / scale %.1f / %s',o.x,o.y,o.scale,o.monitor or 'monitor pending'),423,267,13,C.muted)
 button(o.locked and 'Unlock position' or 'Lock position',423,302,170,32,function() o.locked=not o.locked end,o.locked)
 button(o.stored and 'Restore object' or 'Return to storage',605,302,190,32,function() o.stored=not o.stored end)
 button('Rename label',807,302,160,32,function() P.naming=true;P.name=o.config.label or '' end)
 button('Scale -',980,302,100,32,function() o.scale=math.max(.5,o.scale-.1) end);button('Scale +',1090,302,100,32,function() o.scale=math.min(1.8,o.scale+.1);M.restore(o,Host.monitors) end)
 button('Reset position',1200,302,170,32,function() local m=Host.monitors[1];o.x=m.x+40;o.y=m.y+40;M.remember(o,Host.monitors) end)
 local v,vi=T.vessel(s,o.entityId)
 if v then
  local n=V.count(v);local b=v.contents[1]
  text((v.label or V.types[v.kind].name)..' / persistent container #'..v.id,423,361,20)
  text(string.format('Population %d / %d cell equivalents\nNutrients %.0f%% / health %.0f%% / contamination %.1f%%\nTemperature %s / age %.1f simulation hours\n%s / %s / cultivation %s',n,V.types[v.kind].capacity,v.nutrients*100,(v.health or 1)*100,v.contamination*100,require('units').temperature(v.temperature or 37),v.cultureAge or 0,v.closed and 'Closed' or 'Open',v.frozen and 'Frozen' or 'Living',v.cultivating and 'active' or 'idle'),423,402,15,C.muted)
  if b then text('Strain '..b.cell.strain..' / '..c.B.types[b.cell.type]..' / genome '..G.hash(b.cell.genome),423,517,14,C.mint) end
  local source=s.cells[P.cell];button('Loose cell: '..(source and source.id..' '..c.B.types[source.type] or 'none')..' >',423,552,360,33,function() P.cell=P.cell%math.max(1,#s.cells)+1 end)
  button('Introduce selected cell',800,552,260,33,function() result(T.seed(s,v.id,P.cell)) end)
  button(v.closed and 'Open lid' or 'Close lid',1075,552,295,33,function() v.closed=not v.closed end)
  button('Collect 1 cell eq.',423,603,210,33,function() result(T.collect(s,v.id)) end)
  button('Dispense sample',645,603,210,33,function() Host.beginDispense(o) end)
  button('Start cultivation',868,603,230,33,function() result(V.cultivate(s,vi,v.medium)) end)
  button('Withdraw cell',1110,603,260,33,function() result(V.withdraw(s,vi)) end)
  button('Refresh medium',423,654,210,33,function() v.nutrients=1;v.waste=0;v.medium=v.medium==1 and 2 or 1;msg('Medium replenished; culture retained.') end)
  button('- 4 F',645,654,100,33,function() v.temperature=math.max(15,v.temperature-4/1.8) end);button('+ 4 F',755,654,100,33,function() v.temperature=math.min(60,v.temperature+4/1.8) end)
  button(v.sterility==1 and 'Unseal sterility test' or 'Reseal sterile cover',868,654,230,33,function() v.sterility=v.sterility==1 and 0 or 1 end)
  button(v.frozen and 'Thaw vial' or 'Freeze cryovial',1110,654,260,33,function() if v.frozen then result(V.thaw(s,vi)) else result(V.freeze(s,vi)) end end)
  button('Inspect genome',423,706,210,33,function() if b then local index;for i,cell in ipairs(s.cells) do if cell.id==b.cell.id then index=i end end;Host.context.openGenome(b.cell) end end)
  button('Dispose culture...',645,706,210,33,function() if require('native_windows').confirm('Permanently dispose of this culture and clean the vessel?') then result(V.discard(s,vi)) end end)
  text('Normal-scale dots represent colonies / cell equivalents. Genome and microscope views use magnification.',423,772,12,C.muted)
 elseif o.kind=='dropper' then
  local p=d.pipette;text(p.sample and 'Loaded biological sample' or 'No sample loaded',423,372,24)
  if p.sample then text('Source vessel #'..p.sample.sourceContainerId..' / '..p.sample.quantity..' cell eq.\nViability '..math.floor(p.sample.viability*100)..'% / contamination '..math.floor(p.sample.contamination*100)..'%\nGenetic identity '..G.hash(p.sample.genome),423,422,16,C.muted) end
  button(d.tool=='dropper' and 'Deselect dropper' or 'Select dropper tool',423,540,320,38,function() d.tool=d.tool=='dropper' and nil or 'dropper';Host.hidePanel() end)
  button('Sterilize',760,540,250,38,function() result(T.clean(s)) end)
  button('Dispose sample...',1026,540,340,38,function() if require('native_windows').confirm('Dispose of the loaded sample?') then p.sample=nil end end)
  text('Select the dropper, click an open source, then click an open destination.\nYou can also drag a loaded dropper by its bulb and release its tip over a target.\nThe sample is counted and retained if a transfer is rejected.',423,612,16,C.muted)
 elseif o.group=='habitats' then
  local world=Worlds.find(s,o.entityId);local h=world.habitat;local list={};for _,organism in ipairs(s.organisms) do if organism.worldId==world.id then list[#list+1]=organism end end
  text(world.name,423,366,24);text(string.format('%s / quality %.0f%% / waste %.2f / %d living / capacity %d',require('units').temperature(h.temperature),(h.quality or 1)*100,h.waste or 0,Worlds.population(s,world.id),world.capacity),423,409,14,C.muted)
  if world.kind~='terrarium' then text(string.format('Water %.2f gal / salinity %.0f%% / dissolved oxygen %.0f%%',h.volume or 2.6,(h.salinity or 0)*100,(h.dissolvedOxygen or .9)*100),423,437,14,C.mint) end
  button('Feed habitat',423,477,210,33,function() for i=1,20 do world.food[#world.food+1]={x=.1+math.random()*.8,y=.1+math.random()*.8,kind=world.kind=='terrarium' and 'plant' or 'dissolved',amount=1} end end)
  button('- 4 F',645,477,100,33,function() h.temperature=h.temperature-4/1.8 end);button('+ 4 F',755,477,100,33,function() h.temperature=h.temperature+4/1.8 end)
  button('Clean / refresh water',870,477,230,33,function() h.waste=0;h.quality=1;h.water=1 end)
  button('Oxygen +',1115,477,250,33,function() h.dissolvedOxygen=math.min(1.2,(h.dissolvedOxygen or .9)+.1) end)
  local chosen;for _,organism in ipairs(list) do if organism.id==d.selectedOrganism then chosen=organism end end
  if not chosen and list[1] then chosen=list[1];d.selectedOrganism=chosen.id end
  button('Organism: '..(chosen and chosen.name..' #'..chosen.id or 'none')..' >',423,535,650,35,function() if #list>0 then local index=1;for i,vv in ipairs(list) do if vv.id==d.selectedOrganism then index=i end end;d.selectedOrganism=list[index%#list+1].id end end)
  button('Open organism record',1090,535,280,35,function() if chosen then Host.open('organism',chosen.id) end end)
  if chosen then local stats=chosen.stats or require('living_stats').calculate(chosen);text(string.format('Health %.0f%% / oxygen %.0f%% / %s\nSTR %.2f  DEF %.2f  DEX %.2f  INT %.2f  VIT %.2f  END %.2f',chosen.health,(chosen.oxygen or 1)*100,chosen.behavior,stats.STR,stats.DEF,stats.DEX,stats.INT,stats.VIT,stats.END),423,594,15,C.muted) end
  for i,target in ipairs({'terrarium','freshwater','saltwater','desktop'}) do button('Move to '..target,423+(i-1)*238,666,225,34,function() if chosen then result(Worlds.move(s,chosen.id,target));Host.sync() end end) end
  button('Add from other habitats >',423,722,330,33,function() P.organism=P.organism%math.max(1,#s.organisms)+1 end)
  local incoming=s.organisms[P.organism];text(incoming and incoming.name..' / '..incoming.worldId or 'No organisms yet; incubate a genome in the Forge.',775,731,13,C.muted)
  button('Move selected organism here',423,770,330,33,function() if incoming then result(Worlds.move(s,incoming.id,world.id));Host.sync() end end)
  button('Develop reference specimen',775,770,330,33,function() local g=G.copy(require('audit_examples').compact.genome);local e=c.B.queue(s,g,'Audited reference genotype',0);e.worldId='terrarium';msg('Reference genome incubating in terrestrial mesocosm.') end)
 elseif o.kind=='dna' then
  local dna;for _,vial in ipairs(s.materials) do if vial.id==o.entityId then dna=vial end end;if not dna then return end
  text(dna.name or 'Archived DNA',423,373,25);text('DNA is a genome record, not a living culture.\nGenome '..G.hash(dna.genome)..' / marker '..G.marker(dna.genome)..'\n144 alleles / '..#dna.genome.mutations..' recorded mutations',423,425,16,C.muted)
  button('Send to Forge / edit a copy',423,550,410,42,function() Host.context.openGenome(dna) end)
  button('Prepare developmental cell',855,550,510,42,function() d.blankCells=d.blankCells or 6;if d.blankCells<1 then msg('No blank developmental cells remain; restock at workstation.') else local cell=c.B.cell(s,1,dna.genome,'DNA '..dna.id,0);s.cells[#s.cells+1]=cell;d.blankCells=d.blankCells-1;msg('Genome installed into one blank developmental cell. Find it in the cell library.') end end)
  text('Blank developmental cells: '..(d.blankCells or 6)..' / rack placement: drag vial onto a rack.',423,625,14,C.muted)
 else
  text('Physical '..o.kind,423,380,25);text('Click the instrument body to open its existing detailed workspace.\nNo biological records are copied when a desktop object moves or hides.',423,435,16,C.muted)
  button('Open detailed workspace',423,534,440,40,function() Host.open(o.kind=='forge' and 'forge' or 'workstation',o.id) end)
  button('Restock 6 blank cells / 8 credits',889,534,475,40,function() if s.credits<8 then msg('Insufficient credits.') else s.credits=s.credits-8;d.blankCells=(d.blankCells or 6)+6;msg('Six blank developmental cells acquired.') end end)
 end
 if P.naming then panel(480,415,600,150);text('Label / Enter accepts, Esc cancels',500,437,16,C.mint);text(P.name..'_',500,490,24) end
end
return P
