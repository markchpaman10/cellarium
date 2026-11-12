-- Controls live inside the equipment's own native window. They are not menus
-- and never open the classic UI or the separate records application.
local M=require('desktop_model');local G=require('genome');local V=require('vessels');local T=require('desktop_samples');local E=require('genome_editor');local B=require('biology');local R=require('rendering')
local C={hits={},fonts={}}
local function color(c) love.graphics.setColor(c[1],c[2],c[3],c[4] or 1) end
local function text(value,x,y,size,shade) size=size or 14;C.fonts[size]=C.fonts[size] or love.graphics.newFont(size);love.graphics.setFont(C.fonts[size]);color(shade or {.8,.91,.91});love.graphics.print(tostring(value),x,y) end
local function say(o,value) o.config.notice=value;require('desktop_host').message(value) end
local function result(o,ok,why) say(o,why or (ok and 'Done.' or 'Unavailable.')) end
function C.isContainer(o) return ({dish=true,flask=true,plate=true,vial=true,cryovial=true,dna=true})[o.kind]==true end
function C.prepare(o)
 if not C.isContainer(o) or o.config.containerUI==4 then return end
 o.config.containerUI=4;o.config.cell=nil;o.config.source=nil;o.config.sourceType=nil;o.config.vessel=nil;o.config.details=false
 if o.config.expanded then o.w=440;o.h=354 end
end
function C.expand(s,o)
 C.prepare(o)
 if o.config.expanded then return end
 o.config.collapsed={w=o.w,h=o.h};o.config.expanded=true
 if o.kind=='forge' then o.w=970;o.h=700 elseif o.kind=='workstation' then o.w=720;o.h=470 else o.w=440;o.h=354 end
 M.restore(o,require('desktop_host').monitors,true);M.remember(o,require('desktop_host').monitors)
end
function C.collapse(s,o)
 local previous=o.config.collapsed;if previous then o.w=previous.w;o.h=previous.h end;o.config.expanded=false;C.hits[o.id]=nil
 M.restore(o,require('desktop_host').monitors,true);M.remember(o,require('desktop_host').monitors)
end
function C.hit(o,x,y) if not o.config.expanded then return end;for i=#(C.hits[o.id] or {}),1,-1 do local h=C.hits[o.id][i];if x>=h.x and x<h.x+h.w and y>=h.y and y<h.y+h.h then return h end end end
local function openForge(s,source)
 if not source then return end;E.begin(source)
 for _,o in ipairs(s.desktop.objects) do if o.kind=='forge' then
  for _,key in ipairs({'materials','cells'}) do for i,record in ipairs(s[key] or {}) do if record.id==source.id then o.config.sourceType=key;o.config.source=i end end end
  o.stored=false;o.visible=true;C.expand(s,o);break
 end end
end
function C.draw(s,o)
 if not o.config.expanded then return false end
 C.hits[o.id]={};local hits=C.hits[o.id];local cfg=o.config
 local function button(label,x,y,w,h,fn,active)
  color(active and {.16,.48,.42} or {.11,.21,.24});love.graphics.rectangle('fill',x,y,w,h,5);color({.39,.59,.61});love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,5)
  C.fonts[12]=C.fonts[12] or love.graphics.newFont(12);love.graphics.setFont(C.fonts[12]);color({.89,.95,.94});love.graphics.printf(label,x+3,y+(h-14)/2,w-6,'center')
  hits[#hits+1]={id=label,x=x,y=y,w=w,h=h,fn=fn}
 end
 color({.03,.055,.07,.98});love.graphics.rectangle('fill',4,4,o.w-8,o.h-8,16);color({.34,.49,.51});love.graphics.rectangle('line',5,5,o.w-10,o.h-10,16)
 color({.16,.25,.28});love.graphics.rectangle('fill',12,12,o.w-24,48,10)
 local title=o.kind=='forge' and 'GENOME FORGE' or o.kind=='workstation' and 'CELL WORKSTATION' or o.kind=='dna' and ('DNA VIAL #'..o.entityId) or ('CONTAINER #'..o.entityId)
 text(title,28,27,17)
 button(C.isContainer(o) and 'Done' or 'Collapse',o.w-112,22,85,29,function() C.collapse(s,o) end)
 for _,point in ipairs({{17,17},{o.w-17,17},{17,o.h-17},{o.w-17,o.h-17}}) do color({.5,.65,.66});love.graphics.circle('line',point[1],point[2],2) end
 local footer=cfg.notice or 'Drag the frame to move. Right-click always opens the context menu.';text(tostring(footer):sub(1,math.floor((o.w-45)/6)),24,o.h-28,11,{.57,.78,.75})
 if o.kind=='forge' then
  cfg.sourceType=cfg.sourceType or 'materials';local sources=s[cfg.sourceType] or {};cfg.source=math.max(1,math.min(cfg.source or 1,math.max(1,#sources)));local source=sources[cfg.source]
  button(cfg.sourceType=='materials' and 'Archived DNA' or 'Living cells',24,77,145,33,function() cfg.sourceType=cfg.sourceType=='materials' and 'cells' or 'materials';cfg.source=1 end)
  button(source and ((source.name or 'DNA')..' #'..source.id..' >') or 'No samples',181,77,373,33,function() cfg.source=cfg.source%math.max(1,#sources)+1 end)
  button('Load editable copy',566,77,188,33,function() if source then E.begin(source);say(o,'Editable genome copy loaded.') end end)
  button('Assemble 2 sources',766,77,180,33,function() if E.draft and source then E.begin({id='assembly',genome=G.fuse({E.draft,source.genome})});say(o,'Two-source synthetic genome assembled; source records retained.') else say(o,'Load a genome and select a second source.') end end)
  if not E.draft then text('Choose a sample above and load a copy to begin.',28,160,21);return true end
  for i,name in ipairs({'Primary','Development','Ecology'}) do button(name,24+(i-1)*178,130,166,31,function() E.site=i end,E.site==i) end
  local names=E.site==1 and G.loci or E.site==2 and require('development_genes').names or require('environment_genes').names
  for i=1,24 do local name=type(names[i])=='table' and names[i].name or names[i];local x=24+math.floor((i-1)/6)*232;local y=182+(i-1)%6*36;button(string.format('%02d ',i)..name:sub(1,23),x,y,220,30,function() E.selected=i end,E.selected==i) end
  local l=E.draft.chromosomes[E.selected].loci[E.site];text('Chromosome '..E.selected..' / allele A '..l.a..' / allele B '..l.b..' / copies '..(l.copies or 1),26,414,17)
  button('A -',24,452,65,34,function() E.change('a',-1) end);button('A +',101,452,65,34,function() E.change('a',1) end)
  button('B -',181,452,65,34,function() E.change('b',-1) end);button('B +',258,452,65,34,function() E.change('b',1) end)
  button('Undo',338,452,90,34,function() E.undo() end);button('Reset copy',440,452,116,34,function() if source then E.begin(source) end end)
  for i,operation in ipairs({'duplicate','delete','restore','regulate','splice'}) do button(operation,24+(i-1)*108,505,98,33,function() result(o,E.operation(operation,source)) end) end
  button('Forecast',24,559,144,35,function() local ok,a=pcall(require('anatomy').generate,E.draft,{nutrition=1,temperature=37,minerals=1,oxygen=1});if ok then E.forecast=a;cfg.preview=true;say(o,(a.viable and 'Viable' or 'Nonviable')..' / '..a.caps.locomotion..' / '..#a.regions..' regions') else say(o,tostring(a)) end end)
  button('Archive DNA',180,559,144,35,function() result(o,E.commit(s,B));require('desktop_host').sync() end)
  button('Install cell',336,559,144,35,function() s.desktop.blankCells=s.desktop.blankCells or 6;if s.desktop.blankCells<1 then say(o,'Restock blank cells at the workstation.');return end;s.cells[#s.cells+1]=B.cell(s,1,E.draft,'Desktop Forge',0);s.desktop.blankCells=s.desktop.blankCells-1;say(o,'Genome installed into one real developmental cell.') end)
  button('Incubate exact',492,559,144,35,function() result(o,E.incubate(s,B)) end)
  button('Export genome',648,559,144,35,function() result(o,E.export()) end)
  button(cfg.preview==false and 'Show specimen' or 'Hide specimen',804,559,142,35,function() if E.forecast then cfg.preview=cfg.preview==false else say(o,'Run Forecast first.') end end)
  text('Blank cells: '..(s.desktop.blankCells or 6)..' / changes affect the real developmental expression model.',26,624,13,{.56,.77,.75})
  if E.forecast and cfg.preview~=false then R.draw({anatomy=E.forecast,caps=E.forecast.caps,maturity=1,alive=true,behavior='Resting',angle=0},760,459,R.fitScale(E.forecast,330,146,2),0,'External') end
 elseif o.kind=='workstation' then
  cfg.cell=math.max(1,math.min(cfg.cell or 1,math.max(1,#s.cells)));cfg.vessel=math.max(1,math.min(cfg.vessel or 1,#s.vessels));cfg.dna=math.max(1,math.min(cfg.dna or 1,math.max(1,#s.materials)))
  local cell=s.cells[cfg.cell];local vessel=s.vessels[cfg.vessel];local dna=s.materials[cfg.dna]
  button(cell and ('Cell #'..cell.id..' / '..B.types[cell.type]..' >') or 'No loose cells',24,80,430,35,function() cfg.cell=cfg.cell%math.max(1,#s.cells)+1 end)
  button('Collect wild cells',467,80,228,35,function() if #s.cells<180 then B.collect(s) end end)
  button(vessel and ((vessel.label or V.types[vessel.kind].name)..' #'..vessel.id..' / '..V.count(vessel)..' >') or 'No vessels',24,132,430,35,function() cfg.vessel=cfg.vessel%#s.vessels+1 end)
  button('Introduce cell',467,132,228,35,function() if vessel then result(o,T.seed(s,vessel.id,cfg.cell)) end end)
  button('Start cultivation',24,184,212,35,function() result(o,V.cultivate(s,cfg.vessel,1)) end)
  button('Extract DNA',248,184,212,35,function() result(o,B.extract(s,cfg.cell));require('desktop_host').sync() end)
  button('Send to Forge',472,184,223,35,function() if cell then openForge(s,cell);say(o,'Cell genome opened in the desktop Forge.') end end)
  button(dna and ('DNA: '..(dna.name or dna.id)..' >') or 'No archived DNA',24,239,430,35,function() cfg.dna=cfg.dna%math.max(1,#s.materials)+1 end)
  button('Install into blank cell',467,239,228,35,function() s.desktop.blankCells=s.desktop.blankCells or 6;if not dna then say(o,'Extract or archive a genome first.');return end;if s.desktop.blankCells<1 then say(o,'No blank developmental cells.');return end;s.cells[#s.cells+1]=B.cell(s,1,dna.genome,'Desktop workstation',0);s.desktop.blankCells=s.desktop.blankCells-1;say(o,'DNA installed into one blank cell.') end)
  button('Buy 6 blanks / 8 credits',24,292,212,35,function() if s.credits>=8 then s.credits=s.credits-8;s.desktop.blankCells=(s.desktop.blankCells or 6)+6;say(o,'Six blank cells restocked.') else say(o,'Not enough credits.') end end)
  button('Preserve selected cell',248,292,212,35,function() result(o,B.freeze(s,cfg.cell)) end)
  button('Withdraw cultured cell',472,292,223,35,function() result(o,V.withdraw(s,cfg.vessel)) end)
  button('Egg precursor',24,346,212,35,function() result(o,B.precursor(s,cfg.cell,'Egg')) end)
  button('Sperm precursor',248,346,212,35,function() result(o,B.precursor(s,cfg.cell,'Sperm')) end)
  button('Buy Petri dish / 12',472,346,223,35,function() result(o,V.add(s,1));require('desktop_host').sync() end)
  text('Blank cells '..(s.desktop.blankCells or 6)..' / credits '..s.credits..' / loose specimens '..#s.cells,26,407,15,{.56,.77,.75})
 elseif o.kind=='dna' then
  local dna;for _,record in ipairs(s.materials) do if record.id==o.entityId then dna=record;break end end
  if not dna then text('This vial is unavailable.',26,90,19);return true end
  text((dna.name or 'DNA template'):sub(1,32),26,84,19)
  text('One stored genome template',26,124,15,{.56,.77,.75})
  text('Genome '..G.hash(dna.genome)..' / '..G.marker(dna.genome),26,163,13)
  text('DNA material — not a living cell culture.',26,199,13,{.56,.77,.75})
  button('Use this DNA in the Forge',24,245,392,36,function() openForge(s,dna);say(o,'This vial\'s DNA copy is loaded in the desktop Forge.') end)
 else
  local vessel=T.vessel(s,o.entityId);if not vessel then text('This container is unavailable.',26,90,19);return true end
  local bucket=vessel.contents[1];local growing=V.types[vessel.kind].growth>0
  text((vessel.label or V.types[vessel.kind].name):sub(1,30),26,82,19)
  text(bucket and (V.count(vessel)..' / '..V.types[vessel.kind].capacity..' '..B.types[bucket.cell.type]..' cell equivalents') or 'Empty',26,118,17,{.56,.82,.75})
  text(bucket and (bucket.cell.name or 'Strain '..bucket.cell.strain):sub(1,40) or 'Add a sample using the dropper.',26,152,13)
  text(vessel.frozen and 'Frozen' or vessel.cultivating and 'Growing culture' or 'Not growing',26,176,12,{.56,.77,.75})
  button(vessel.closed and 'Open cap / lid' or 'Close cap / lid',24,199,392,34,function() local own=T.vessel(s,o.entityId);if own then own.closed=not own.closed end end)
  button('Take sample',24,245,190,34,function() result(o,T.collect(s,o.entityId)) end)
  button('Add held sample',226,245,190,34,function() require('desktop_host').beginDispense(o) end)
  if vessel.kind==5 then button(vessel.frozen and 'Thaw this vial' or 'Freeze this vial',24,293,190,32,function() local own=T.vessel(s,o.entityId);if own then result(o,T.action(s,o.entityId,own.frozen and 'thaw' or 'freeze')) end end)
  elseif growing then button(vessel.cultivating and 'Pause growth' or 'Grow culture',24,293,190,32,function() local own=T.vessel(s,o.entityId);if own and own.cultivating then own.cultivating=false;say(o,'Growth paused in this container.') else result(o,T.action(s,o.entityId,'cultivate',1)) end end) end
  button(cfg.details and 'Less detail' or 'Details',226,293,190,32,function() cfg.details=not cfg.details;o.h=cfg.details and 466 or 354;M.restore(o,require('desktop_host').monitors,true);M.remember(o,require('desktop_host').monitors) end)
  if cfg.details then
   text(require('units').temperature(vessel.temperature or 37)..' / nutrients '..math.floor(vessel.nutrients*100)..'%',26,342,13,{.56,.77,.75})
   text('Health '..math.floor((vessel.health or 1)*100)..'% / contamination '..string.format('%.1f%%',vessel.contamination*100),26,370,13,{.56,.77,.75})
   button('- 4 F',24,398,86,30,function() local own=T.vessel(s,o.entityId);if own then own.temperature=math.max(15,(own.temperature or 37)-4/1.8) end end)
   button('+ 4 F',122,398,92,30,function() local own=T.vessel(s,o.entityId);if own then own.temperature=math.min(60,(own.temperature or 37)+4/1.8) end end)
   if growing then button('Refresh medium',226,398,190,30,function() local own=T.vessel(s,o.entityId);if own then own.nutrients=1;own.waste=0;say(o,'Medium refreshed in this container.') end end) end
  end
 end
 return true
end
return C
