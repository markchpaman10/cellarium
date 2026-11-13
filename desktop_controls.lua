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
 if o.kind=='workstation' and o.config.workshopUI~=1 then o.config.workshopUI=1;o.config.cell=nil;o.config.vessel=nil;o.config.dna=nil;if o.config.expanded then o.w=1050;o.h=640 end end
 if not C.isContainer(o) or o.config.containerUI==4 then return end
 o.config.containerUI=4;o.config.cell=nil;o.config.source=nil;o.config.sourceType=nil;o.config.vessel=nil;o.config.details=false
 if o.config.expanded then o.w=440;o.h=354 end
end
function C.expand(s,o)
 C.prepare(o)
 if o.config.expanded then return end
 o.config.collapsed={w=o.w,h=o.h};o.config.expanded=true
 if o.kind=='forge' then o.w=970;o.h=700 elseif o.kind=='workstation' then o.w=1050;o.h=640 else o.w=440;o.h=354 end
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
  button('Use in workshop',336,559,144,35,function() local ok,why=E.commit(s,B);if ok then local dna=s.materials[#s.materials];for _,station in ipairs(s.desktop.objects) do if station.kind=='workstation' then station.config.genomeId=dna.id;station.visible=true;station.stored=false;C.expand(s,station);break end end;require('desktop_host').sync() end;say(o,ok and 'Genome sent to workshop. Attach a blank-cell vial and an empty output.' or why) end)
  button('Incubate exact',492,559,144,35,function() result(o,E.incubate(s,B)) end)
  button('Export genome',648,559,144,35,function() result(o,E.export()) end)
  button(cfg.preview==false and 'Show specimen' or 'Hide specimen',804,559,142,35,function() if E.forecast then cfg.preview=cfg.preview==false else say(o,'Run Forecast first.') end end)
  text('Install DNA at the cell workshop using an attached blank-cell vial.',26,624,13,{.56,.77,.75})
  if E.forecast and cfg.preview~=false then R.draw({anatomy=E.forecast,caps=E.forecast.caps,maturity=1,alive=true,behavior='Resting',angle=0},760,459,R.fitScale(E.forecast,330,146,2),0,'External') end
 elseif o.kind=='workstation' then
  require('cell_workshop_ui').draw(s,o,{text=text,button=button,result=result})
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
  text(bucket and (V.count(vessel)..' / '..V.types[vessel.kind].capacity..' '..require('physical_cells').label(bucket.cell)) or 'Empty',26,118,17,{.56,.82,.75})
  text(bucket and (bucket.cell.name or 'Strain '..bucket.cell.strain):sub(1,40) or 'Add a sample using the dropper.',26,152,13)
  text((growing and ('Food '..math.floor(vessel.nutrients*100)..'% / ') or '')..V.timerText(vessel),26,176,12,{.56,.77,.75})
  button(vessel.closed and 'Open cap / lid' or 'Close cap / lid',24,199,392,34,function() local own=T.vessel(s,o.entityId);if own then own.closed=not own.closed end end)
  button('Take sample',24,245,190,34,function() result(o,T.collect(s,o.entityId)) end)
  button('Add held sample',226,245,190,34,function() require('desktop_host').beginDispense(o) end)
  if vessel.kind==5 then button(vessel.frozen and 'Thaw this vial' or 'Freeze this vial',24,293,190,32,function() local own=T.vessel(s,o.entityId);if own then result(o,T.action(s,o.entityId,own.frozen and 'thaw' or 'freeze')) end end)
  elseif growing then button('Add food',24,293,190,32,function() result(o,T.action(s,o.entityId,'feed')) end) end
  if bucket and bucket.cell.developmentalCell then button('Begin development',226,293,190,32,function() result(o,require('physical_cells').beginDevelopment(s,o.entityId)) end) else button(cfg.details and 'Less detail' or 'Details',226,293,190,32,function() cfg.details=not cfg.details;o.h=cfg.details and 466 or 354;M.restore(o,require('desktop_host').monitors,true);M.remember(o,require('desktop_host').monitors) end) end
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
