-- Default detailed UI for the desktop edition. The classic five-workspace UI
-- is retained elsewhere and is rendered only after an explicit Settings choice.
local Host=require('desktop_host');local M=require('desktop_model');local T=require('desktop_samples');local V=require('vessels');local G=require('genome');local E=require('genome_editor');local Worlds=require('desktop_worlds');local R=require('rendering');local Units=require('units')
local Clock=require('realtime')
local A={page='Lab',vessel=1,cell=1,world=1,record=1,recordType='organisms',recordPage=1,sourceType='materials',source=1,query='',editing=nil,name='Untitled genome',site=2,donors={},layer=1,gameteA=1,gameteB=2}
local palette={bg={.94,.955,.96},paper={1,1,1},ink={.11,.18,.21},muted={.38,.47,.50},line={.81,.85,.87},teal={.05,.41,.37},tint={.88,.94,.93},danger={.67,.23,.22}}
local fonts={}
local function set(c) love.graphics.setColor(c[1],c[2],c[3],c[4] or 1) end
local function text(t,x,y,size,c) size=size or 14;fonts[size]=fonts[size] or love.graphics.newFont(size);love.graphics.setFont(fonts[size]);set(c or palette.ink);love.graphics.print(tostring(t),x,y) end
local function card(x,y,w,h) set(palette.paper);love.graphics.rectangle('fill',x,y,w,h,8);set(palette.line);love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,8) end
local function button(label,x,y,w,h,fn,active,danger)
 local mx,my=love.mouse.getPosition();mx=mx/love.graphics.getWidth()*1440;my=my/love.graphics.getHeight()*900;local hover=mx>=x and mx<x+w and my>=y and my<y+h
 set(active and palette.teal or hover and palette.tint or palette.paper);love.graphics.rectangle('fill',x,y,w,h,5);set(active and palette.teal or palette.line);love.graphics.rectangle('line',x+.5,y+.5,w-1,h-1,5)
 fonts[13]=fonts[13] or love.graphics.newFont(13);love.graphics.setFont(fonts[13]);set(active and {1,1,1} or danger and palette.danger or fn and palette.ink or {.6,.65,.66});love.graphics.printf(label,x+4,y+(h-16)/2,w-8,'center')
 if fn then A.context.register(x,y,w,h,fn,label) end
end
local function result(ok,why) Host.message(why or (ok and 'Done.' or 'Action unavailable.')) end
local function heading(title,subtitle) text(title,250,89,29);text(subtitle,250,132,14,palette.muted) end
local function countLiving(s) local n=0;for _,o in ipairs(s.organisms) do if o.alive then n=n+1 end end;return n end
function A.open(mode,id,s)
 if mode=='label' then local o=M.find(s,id);if o then A.beginLabel(s,o.kind,o.entityId,true) end;return
 elseif mode=='forge' or mode=='genomes' then A.page='Genome Forge'
 elseif mode=='research' then A.page='Research';A.recordType='experiments';A.record=1
 elseif mode=='organisms' or mode=='organism' then A.page='Records';A.recordType='organisms';for i,o in ipairs(s.organisms) do if o.id==id then A.record=i;A.recordPage=math.floor((i-1)/11)+1 end end
 elseif mode=='settings' then A.page='Settings'
 elseif mode=='workstation' then A.page='Cultures'
 elseif mode=='inspect' then local o=M.find(s,id);if not o then return end
  if o.group=='habitats' then A.page='Habitats';for i,w in ipairs(s.desktop.worlds) do if w.id==o.entityId then A.world=i end end;for i,v in ipairs(s.organisms) do if v.id==s.desktop.selectedOrganism then A.record=i end end
  elseif o.kind=='dna' then A.page='Genome Forge';A.sourceType='materials';for i,v in ipairs(s.materials) do if v.id==o.entityId then A.source=i end end
  elseif o.kind=='dropper' then A.page='Lab'
  elseif o.kind=='forge' then A.page='Genome Forge'
  else A.page='Cultures';for i,v in ipairs(s.vessels) do if v.id==o.entityId then A.vessel=i end end end
 else A.page='Lab' end
end
function A.openGenome(value) E.begin(value);A.page='Genome Forge';A.name=value.name or 'Edited genome' end
function A.beginLabel(s,kind,id,fromDesktop)
 local record=require('container_labels').record(s,kind,id);if not record then return false end
 A.labelEdit={kind=kind,id=id,draft=record.label or '',selectAll=true,returnPage=A.page,fromDesktop=fromDesktop};A.page='Container label';A.editing=nil;return true
end
function A.finishLabel(s,save)
 local e=A.labelEdit;if not e then return end
 if save then local ok,why=require('container_labels').set(s,e.kind,e.id,e.draft);Host.message(why);if not ok then return end end
 A.labelEdit=nil;A.page=e.returnPage or 'Lab';Host.render(true);if e.fromDesktop then Host.hidePanel() end
end
function A.textinput(t) if A.page=='Container label' and A.labelEdit then local e=A.labelEdit;local value=require('container_labels').input((e.selectAll and '' or e.draft)..t);if value then e.draft=value;e.selectAll=false end;return true end;if A.page=='Anatomy Generator' and require('anatomy_dev_ui').textinput(t) then return true end;if A.editing then if A.editing=='query' then A.query=(A.query..t):sub(1,48);A.recordPage=1 else A.name=(A.name..t):sub(1,40) end;return true end end
function A.keypressed(key)
 if A.page=='Container label' and A.labelEdit then local e=A.labelEdit;if key=='return' then A.finishLabel(Host.state(),true) elseif key=='escape' then A.finishLabel(Host.state(),false) elseif key=='backspace' then e.draft=e.selectAll and '' or require('container_labels').backspace(e.draft);e.selectAll=false elseif key=='a' and love.keyboard.isDown('lctrl','rctrl') then e.selectAll=true end;return true end
 if A.page=='Anatomy Generator' and require('anatomy_dev_ui').keypressed(key) then return true end
 if A.editing then if key=='return' or key=='escape' then if key=='return' and A.editing=='vessel' then local v=T.vessel(Host.state(),A.labelVessel);if v then v.label=A.name end end;A.editing=nil elseif key=='backspace' then if A.editing=='query' then A.query=A.query:sub(1,-2) else A.name=A.name:sub(1,-2) end end;return true end
 return false
end
local function lab(s)
 heading('Desktop laboratory','Physical equipment is the workspace. This window contains records and precise controls.')
 local metrics={{'Persistent containers',#s.vessels},{'Frozen samples',#s.frozen},{'Living organisms',countLiving(s)},{'Lab credits',s.credits}}
 for i,m in ipairs(metrics) do local x=250+(i-1)*290;card(x,182,270,112);text(m[1],x+18,201,13,palette.muted);text(m[2],x+18,228,32,palette.teal) end
 card(250,318,562,252);text('The pipette',274,339,22);local p=s.desktop.pipette
 text(p.sample and 'LOADED / '..p.sample.quantity..' cell equivalent' or p.clean and 'STERILE / empty' or 'USED / empty',274,380,16,palette.teal)
 text('Left-click and hold anywhere on the dropper to drag it.\nRight-click a source and choose the Collect sample menu action.\nRelease the loaded tip over a compatible destination to dispense.\nA rejected transfer retains the loaded sample.',274,418,14,palette.muted)
 button('Sterilize dropper',274,518,228,34,function() result(T.clean(s)) end)
 button('Dispose loaded sample...',518,518,269,34,function() if require('native_windows').confirm('Discard the loaded sample?') then p.sample=nil end end,false,true)
 card(836,318,554,252);text('Desktop visibility',860,339,22)
 for i,g in ipairs({'laboratory','habitats','organisms'}) do button((s.desktop.groups[g] and 'Hide ' or 'Show ')..g,860,382+(i-1)*52,502,37,function() Host.toggle(g) end,s.desktop.groups[g]) end
 card(250,594,1140,210);text('Equipment storage',274,614,22);text('Right-click equipment to lock, resize, label, inspect or return it to storage.\nLeft-drag visible equipment bodies; click without moving to inspect. The tray remains available while this window is closed.\nCultures and organisms keep simulating when hidden. Ctrl+Shift+L opens recovery controls.',274,657,14,palette.muted)
 button('Restore stored equipment',274,745,300,35,function() for _,o in ipairs(s.desktop.objects) do if not o.archivedEntity then o.stored=false;o.visible=true end end end)
 button('Save laboratory',590,745,250,35,function() Host.save() end)
 button('Return to desktop',856,745,506,35,function() Host.hidePanel() end,true)
end
local function cultures(s)
 heading('Cultures & cell engineering','Every quantity below belongs to a persistent physical container or a real specimen.')
 card(250,177,310,646)
 for i,v in ipairs(s.vessels) do if i<=10 then button((v.label or V.types[v.kind].name)..' #'..v.id..'  /  '..V.count(v),267,196+(i-1)*43,276,36,function() A.vessel=i end,A.vessel==i) end end
 text('Purchase supplies from the\nCellarium tray context menu.\n\nCell + supplied vial: 1 credit.\nSeparate containers arrive empty.',267,680,13,palette.muted)
 local v=s.vessels[A.vessel];if not v then return end
 card(580,177,810,270);text(v.label or V.types[v.kind].name,602,198,24);local b=v.contents[1]
 button('Label container',1170,197,196,31,function() A.beginLabel(s,'vessel',v.id,false) end)
 text(string.format('%d / %d cell equivalents   |   %s   |   %s',V.count(v),V.types[v.kind].capacity,v.closed and 'closed' or 'open',v.frozen and 'frozen' or v.cultivating and 'cultivating' or 'idle'),602,239,16,palette.teal)
 text(string.format('Nutrients %.0f%%   Health %.0f%%   Contamination %.1f%%\nTemperature %s   Age %s   Waste %.0f%%',v.nutrients*100,(v.health or 1)*100,v.contamination*100,Units.temperature(v.temperature or 37),Clock.biologyDuration(v.cultureAge or 0),(v.waste or 0)*100),602,275,15,palette.muted)
 text(V.timerText(v),602,342,12,palette.teal)
 if b then text('Cell category: '..require('biology').types[b.cell.type]..' / strain '..b.cell.strain..' / genome '..G.hash(b.cell.genome),602,322,12,palette.muted) end
 button(v.closed and 'Open container' or 'Close container',602,367,173,32,function() v.closed=not v.closed end)
 button('Add food',786,367,173,32,function() result(V.feed(s,A.vessel)) end)
 button('Refresh medium',970,367,173,32,function() v.nutrients=1;v.waste=0;Host.message('Medium refreshed; contents retained.') end)
 text('Use dropper to transfer.',1154,375,12,palette.muted)
 button('- 4 F',602,407,87,27,function() v.temperature=math.max(15,v.temperature-4/1.8) end);button('+ 4 F',698,407,87,27,function() v.temperature=math.min(60,v.temperature+4/1.8) end)
 button(v.frozen and 'Thaw' or 'Freeze',798,407,164,27,function() if v.frozen then result(V.thaw(s,A.vessel)) else result(V.freeze(s,A.vessel)) end end)
 button('Collect sample',974,407,173,27,function() result(T.collect(s,v.id)) end)
 button('Dispense sample',1158,407,208,27,function() for _,o in ipairs(s.desktop.objects) do if o.entityId==v.id then Host.beginDispense(o);break end end end)
 card(580,466,810,357);text('Cells live in physical containers',602,484,24)
 text('Buy one cell in its own vial from the Cellarium tray menu.\nBuy empty containers there separately.\n\nDrag a cell container onto the workshop input dock.\nAttach an empty output container for installation or precursor prep.\nUse the dropper for transfers; cultures grow in their own dishes.\nFreeze loaded dropper contents from its context menu.\nRetrieve frozen samples through the tray/dropper storage menu.',602,535,16,palette.muted)
 button('Show cell workshop',602,764,764,35,function() for _,o in ipairs(s.desktop.objects) do if o.kind=='workstation' then o.visible=true;o.stored=false;require('desktop_controls').expand(s,o);Host.render(true);break end end end)
end
local function forge(s)
 heading('Genome Forge','Copy editing, 24 chromosome pairs, 72 loci. Changes affect development through the actual expression model.')
 local sources=s[A.sourceType] or {};local source=sources[A.source]
 button(A.sourceType=='materials' and 'Source: archived DNA' or 'Source: cells',250,173,210,34,function() A.sourceType=A.sourceType=='materials' and 'cells' or 'materials';A.source=1 end)
 button(source and ((source.name or 'DNA')..' #'..source.id..' >') or 'No source records',472,173,495,34,function() A.source=A.source%math.max(1,#sources)+1 end)
 button('Open editable copy',981,173,199,34,function() if source then A.openGenome(source) end end)
 button('Name: '..A.name,1192,173,198,34,function() A.editing='name' end)
 if not E.draft then card(250,234,1140,440);text('Choose a DNA archive or cell above, then open an editable copy.',280,270,21);text('Use the cell workshop to extract DNA and prepare living samples. Archived DNA remains distinct from living cells.',280,317,14,palette.muted);return end
 for i,name in ipairs({'Primary','Development','Ecology'}) do button(name,250+(i-1)*180,224,168,32,function() E.site=i end,E.site==i) end
 local names=E.site==1 and G.loci or E.site==2 and require('development_genes').names or require('environment_genes').names
 for i=1,24 do local x=250+math.floor((i-1)/12)*580;local y=273+(i-1)%12*34;local l=E.draft.chromosomes[i].loci[E.site];local n=type(names[i])=='table' and names[i].name or names[i]
  button(string.format('%02d',i)..'  '..n,x,y,257,29,function() E.selected=i end,E.selected==i)
  button('-',x+267,y,30,29,function() E.selected=i;E.change('a',-1) end);text(l.a,x+308,y+5,14);button('+',x+326,y,30,29,function() E.selected=i;E.change('a',1) end)
  button('-',x+371,y,30,29,function() E.selected=i;E.change('b',-1) end);text(l.b,x+412,y+5,14);button('+',x+430,y,30,29,function() E.selected=i;E.change('b',1) end)
  text('x'..(l.copies or 1),x+479,y+6,12,l.deleted and palette.danger or palette.muted)
 end
 local l=E.draft.chromosomes[E.selected].loci[E.site];text('Selected chromosome '..E.selected..' / '..tostring(l.sourceA)..' | '..tostring(l.sourceB)..' / D12 regulatory cycle: activate, suppress, off.',250,690,12,palette.muted)
 for i,op in ipairs({'duplicate','delete','restore','regulate','splice'}) do button(op,250+(i-1)*143,720,133,33,function() result(E.operation(op,source)) end) end
 button('Undo',965,720,133,33,function() result(E.undo(),'Last edit undone.') end)
 button('Reset from source',1108,720,282,33,function() if source then E.begin(source) end end)
 button('Preview body',250,768,175,36,function() local ok,a=pcall(require('anatomy').generate,E.draft,{nutrition=1,temperature=37,oxygen=1,minerals=1});if ok then E.forecast=a;A.preview=true;Host.message((a.viable and 'Viable' or 'Nonviable')..' / '..#a.regions..' body regions / '..(a.appendageCount or 0)..' appendages / '..a.caps.locomotion) else Host.message(tostring(a)) end end)
 button('Archive genome',438,768,175,36,function() local ok,why=E.commit(s,require('biology'));if ok then s.materials[#s.materials].name=A.name end;result(ok,why);Host.sync() end)
 button('Use in cell workshop',626,768,220,36,function() local ok,why=E.commit(s,require('biology'));if ok then local dna=s.materials[#s.materials];for _,o in ipairs(s.desktop.objects) do if o.kind=='workstation' then o.config.genomeId=dna.id;o.stored=false;o.visible=true;require('desktop_controls').expand(s,o);break end end;Host.sync() end;Host.message(ok and 'Attach a blank-cell vial and an empty output container to install this DNA.' or why) end)
 button('Incubate exact genome',859,768,220,36,function() result(E.incubate(s,require('biology'))) end)
 button('Export genome',1092,768,145,36,function() result(E.export()) end)
 button('Assembly >',1250,768,140,36,function() A.page='Assembly' end)
 if E.forecast then text('Last forecast: '..(E.forecast.viable and 'viable' or 'nonviable')..' / '..E.forecast.caps.locomotion..' / generation is deterministic for this genome and conditions.',250,823,13,palette.teal) end
end
local function assembly(s)
 heading('Multi-source genome assembly','Choose 2–12 distinct living donor cells. Recombination consumes these donor specimens.')
 card(250,177,1140,565)
 for i=1,math.min(20,#s.cells) do local cell=s.cells[i];local chosen=false;for _,id in ipairs(A.donors) do if id==cell.id then chosen=true end end;local x=273+math.floor((i-1)/10)*554;local y=198+(i-1)%10*49
  button('#'..cell.id..' / '..require('biology').types[cell.type]..' / '..cell.name,x,y,529,40,function() local found;for k,id in ipairs(A.donors) do if id==cell.id then found=k end end;if found then table.remove(A.donors,found) elseif #A.donors<12 then A.donors[#A.donors+1]=cell.id end end,chosen)
 end
 A.conditions=A.conditions or {nutrition=1,minerals=1,oxygen=1,temperature=37,release='auto',recombination='majority',exposure=0}
 local options={{'nutrition',{.7,1,1.3}},{'minerals',{.7,1,1.3}},{'oxygen',{.7,1,1.3}},{'temperature',{33,37,40}},{'recombination',{'majority','mosaic'}},{'exposure',{0,.01,.05}}}
 for i,spec in ipairs(options) do local key,values=spec[1],spec[2];local value=A.conditions[key];button(key..': '..(key=='temperature' and Units.temperature(value) or tostring(value)),250+(i-1)*192,756,180,34,function() local index=1;for j,v in ipairs(values) do if v==A.conditions[key] then index=j end end;A.conditions[key]=values[index%#values+1] end) end
 button('Assemble '..#A.donors..' donors & incubate',250,804,700,35,function() local ok,why=require('biology').combine(s,A.donors,A.conditions);if ok then A.donors={};A.page='Incubation' end;result(ok,why) end,true)
 button('Back to editor',970,804,420,35,function() A.page='Genome Forge' end)
end
local function incubation(s)
 heading('Development & reproduction','Embryos differentiate using their own inherited genome. Biological failure remains possible.')
 for i=1,math.min(5,#s.eggs) do local e=s.eggs[i];local remaining=(1-e.progress)*24/(e.anatomy and e.anatomy.growthFactor or 1);if e.anatomy and e.anatomy.anatomicalVersion==2 then local m=e.anatomy.growthModel;remaining=math.max(0,m.duration*m.embryonicFraction-m.elapsed) end;local y=180+(i-1)*85;card(250,y,1140,70);text('#'..e.id..' / '..e.stage,270,y+13,18);text(math.floor(e.progress*100)..'% / remaining ~'..Clock.biologyDuration(remaining)..' / '..e.parents,270,y+41,13,palette.muted);set(palette.tint);love.graphics.rectangle('fill',960,y+27,400,9,4);set(palette.teal);love.graphics.rectangle('fill',960,y+27,400*e.progress,9,4);if e.anatomy and e.anatomy.anatomicalVersion==2 then R.draw({anatomy=e.anatomy,alive=true,maturity=1,behavior='Resting'},850,y+35,R.fitScale(e.anatomy,140,55,.5),0,'External') elseif e.anatomy and e.anatomy.anatomicalVersion and e.constructionFrame then local a=e.anatomy;local f=a.snapshots[e.constructionFrame];local body=setmetatable({regions=f.regions,components=f.components,joints=f.joints,nerves=f.nerves,vessels=f.vessels},{__index=a});R.draw({anatomy=body,alive=true,maturity=1,behavior='Resting'},850,y+35,R.fitScale(a,140,55,.5),0,'External') end end
 if #s.eggs==0 then text('No embryos developing. Incubate an edited genome or assemble donor cells in the Forge.',250,195,18,palette.muted) end
 card(250,640,1140,182);text('Gamete bank',273,659,21)
 local egg,sperm=s.gametes[A.gameteA],s.gametes[A.gameteB]
 button(egg and (egg.kind..' #'..egg.id..' / '..Clock.biologyDuration((1-egg.progress)*8)..' remaining >') or 'No gametes',273,704,360,35,function() A.gameteA=A.gameteA%math.max(1,#s.gametes)+1 end)
 button(sperm and (sperm.kind..' #'..sperm.id..' / '..Clock.biologyDuration((1-sperm.progress)*8)..' remaining >') or 'No gametes',648,704,360,35,function() A.gameteB=A.gameteB%math.max(1,#s.gametes)+1 end)
 button('Fertilize selected egg + sperm',1023,704,343,35,function() result(require('biology').fertilize(s,egg and egg.id,sperm and sperm.id)) end)
 text('Prepare egg and sperm precursors from stem cells in Cultures. Maturation takes 08:00 of real time.',273,770,14,palette.muted)
end
local function habitats(s)
 heading('Habitats','These are the same environments and organisms displayed in the desktop containers.')
 local worlds=Worlds.ensure(s);for i,w in ipairs(worlds) do button(w.name,250+(i-1)*290,177,278,36,function() A.world=i end,A.world==i) end
 local world=worlds[A.world] or worlds[1];local h=world.habitat;card(250,235,1140,584)
 text(world.name,273,257,24);text(string.format('%s / %d living / capacity %d / quality %.0f%%',Units.temperature(h.temperature),Worlds.population(s,world.id),world.capacity,(h.quality or 1)*100),273,303,15,palette.teal)
 text(string.format('Humidity %.0f%% / water %.2f gal / salinity %.0f%% / dissolved oxygen %.0f%% / waste %.2f',(h.humidity or .65)*100,h.volume or 0,(h.salinity or 0)*100,(h.dissolvedOxygen or 1)*100,h.waste or 0),273,340,14,palette.muted)
 button('Feed environment',273,387,220,34,function() for i=1,20 do world.food[#world.food+1]={x=.1+math.random()*.8,y=.1+math.random()*.8,kind=world.kind=='terrarium' and 'plant' or 'dissolved',amount=1} end end)
 button('- 4 F',506,387,100,34,function() h.temperature=h.temperature-4/1.8 end);button('+ 4 F',619,387,100,34,function() h.temperature=h.temperature+4/1.8 end)
 button('Refresh environment',732,387,220,34,function() h.waste=0;h.quality=1;h.water=1 end)
 button('Oxygen +',965,387,180,34,function() h.dissolvedOxygen=math.min(1.2,(h.dissolvedOxygen or .9)+.1) end)
 button('Humidity >',1158,387,208,34,function() h.humidity=(h.humidity or .65)>.8 and .35 or math.min(1,(h.humidity or .65)+.2) end)
 local organism=s.organisms[A.record];button(organism and (organism.name..' / '..organism.worldId..' >') or 'No living specimens yet',273,455,700,35,function() A.record=A.record%math.max(1,#s.organisms)+1 end)
 button('Move selected here',988,455,378,35,function() if organism then result(Worlds.move(s,organism.id,world.id));Host.sync() end end)
 if organism then text(organism.behavior..' / health '..math.floor(organism.health)..'% / oxygen '..math.floor((organism.oxygen or 1)*100)..'%',273,518,17,palette.teal);R.draw(organism,470,650,R.fitScale(organism.anatomy,250,170,3),Clock.visual(s),'External');button('Open this organism record',670,596,344,36,function() A.page='Records';A.recordType='organisms' end);button('Recall to terrarium',1030,596,336,36,function() result(Worlds.move(s,organism.id,'terrarium'));Host.sync() end) end
 button('Develop audited reference genome',273,750,420,35,function() local e=require('biology').queue(s,G.new(G.rng(20365841)),'Audited reference genotype',0);e.worldId='terrarium';Host.message('Reference genome is developing in incubation.');A.page='Incubation' end)
 button('Open desktop container',710,750,656,35,function() for _,o in ipairs(s.desktop.objects) do if o.entityId==world.id then o.stored=false;o.visible=true;M.setGroup(s,'habitats',true);Host.hidePanel();break end end end)
end
local function records(s,cryobank,research)
 local kind=cryobank and 'frozen' or research and 'experiments' or A.recordType
 heading(cryobank and 'Cryobank' or research and 'Research journal' or 'Specimen records','Search and inspect the authoritative simulation records. No parallel database is maintained.')
 if not cryobank and not research then for i,k in ipairs({'organisms','cells','materials'}) do button(k,250+(i-1)*160,177,148,32,function() A.recordType=k;A.record=1;A.recordPage=1 end,kind==k) end end
 if research then button('Observations & discoveries',250,177,490,32,function() A.page='Observations' end) end
 button('Search: '..A.query..(A.editing=='query' and '_' or ''),760,177,420,32,function() A.editing='query' end)
 button(A.sort and 'Sort: name' or 'Sort: ID',1193,177,197,32,function() A.sort=not A.sort end)
 local list=s[kind] or {};local indices={};for i,v in ipairs(list) do local name=v.name or v.kind or 'DNA';if (name..' '..tostring(v.id or i)..' '..tostring(v.source or '')):lower():find(A.query:lower(),1,true) then indices[#indices+1]=i end end
 table.sort(indices,function(i,j) if A.sort then return (list[i].name or list[i].kind or '')<(list[j].name or list[j].kind or '') end;return (list[i].id or i)<(list[j].id or j) end)
 A.recordPage=math.min(A.recordPage,math.max(1,math.ceil(#indices/11)));card(250,230,330,589)
 for row=0,10 do local index=indices[(A.recordPage-1)*11+row+1];local v=index and list[index];if v then button((v.name or v.kind or 'DNA')..' #'..(v.id or index),266,249+row*44,298,37,function() A.record=index end,A.record==index) end end
 button('<',267,760,70,34,function() A.recordPage=math.max(1,A.recordPage-1) end);text(#indices..' records',354,769,13,palette.muted);button('>',494,760,70,34,function() A.recordPage=A.recordPage%math.max(1,math.ceil(#indices/11))+1 end)
 card(601,230,789,589);local v=list[A.record];if not v then text('No record selected.',625,260,20,palette.muted);return end
 text(v.name or v.kind or 'DNA #'..v.id,625,254,24)
 if kind=='experiments' then
  text('Outcome: '..tostring(v.outcome)..' / elapsed '..Clock.biologyDuration(v.time or 0),625,303,16,palette.teal);local y=352;for k,value in pairs(v.conditions or {}) do text(k..': '..(k=='temperature' and Units.temperature(value) or tostring(value)),625,y,14,palette.muted);y=y+27 end
  if v.failures then text(table.concat(v.failures,'\n'),1000,350,13,palette.danger) end
  button('Restore recorded donor templates',625,752,735,35,function() result(require('biology').repeatExperiment(s,A.record)) end)
 elseif kind=='organisms' then
  local caps=v.caps;local stats=v.stats or require('living_stats').calculate(v);text(string.format('Age %s / %s / %s',Clock.biologyDuration(v.age),v.lifeStage or 'Juvenile',v.worldId or 'terrarium'),625,299,14,palette.muted)
  text(string.format('Health %.0f%% / oxygen %.0f%% / energy %.0f%%',v.health,(v.oxygen or 1)*100,v.energy),625,331,15,palette.teal)
  text(string.format('STR %.2f   DEF %.2f   DEX %.2f\nINT %.2f   VIT %.2f   END %.2f',stats.STR,stats.DEF,stats.DEX,stats.INT,stats.VIT,stats.END),625,374,16)
  R.draw(v,1150,422,R.fitScale(v.anatomy,340,200,3),Clock.visual(s),R.layers[A.layer])
  button('Anatomy: '..R.layers[A.layer]..' >',1004,548,356,33,function() A.layer=A.layer%#R.layers+1 end)
  local cognition=require('cognition').ensure(v);local cap=require('cognition').capabilities(v);local relationships=0;for _ in pairs(cognition.relationships) do relationships=relationships+1 end
  text(v.behavior..' / '..caps.locomotion..'\nMemories '..#cognition.memories..' / neural capacity '..cap.capacity..' / relationships '..relationships..'\nParents '..tostring(v.parents)..' / generation '..v.generation..' / offspring '..#v.children,625,472,14,palette.muted)
  local last=cognition.memories[#cognition.memories];text(last and ('Recent memory: '..last.kind..' / strength '..string.format('%.2f',last.strength)) or 'No retained memories yet.',625,592,13,palette.muted)
  local vitals=v.vitals or {};text(vitals.cardiac and string.format('Heart %.0f bpm / pressure %.2f / transport %.0f%%',vitals.heartRate or 0,vitals.pressure or 0,(vitals.transport or 0)*100) or 'Distributed exchange / no cardiac pulse',625,627,13,palette.muted)
  button('Edit genome copy',625,673,225,32,function() A.openGenome(v) end);button('Sample seven tissues',864,673,236,32,function() if v.alive then for typ=1,7 do s.cells[#s.cells+1]=require('biology').cell(s,typ,v.genome,'Organism '..v.id,v.generation) end;Host.message('Seven tissue specimens collected.') end end)
  button('Release to desktop',1114,673,246,32,function() result(Worlds.move(s,v.id,'desktop'));Host.sync() end)
  button('Set as parent A',625,720,225,32,function() A.parentA=v.id;Host.message('Parent A selected.') end);button('Set as parent B',864,720,236,32,function() A.parentB=v.id;Host.message('Parent B selected.') end)
  button('Breed selected parents',1114,720,246,32,function() local a,b;for _,o in ipairs(s.organisms) do if o.id==A.parentA then a=o end;if o.id==A.parentB then b=o end end;if a and b then result(require('biology').breed(s,a,b)) else Host.message('Select two mature, compatible parents.') end end)
  button('Behavior & social journal',1004,592,356,28,function() A.page='Behavior' end)
  button('Development & mutation history',625,769,735,29,function() A.historyRecord=v;A.historyPage=1;A.page='History' end)
 else
  text('Genome '..G.hash(v.genome)..' / marker '..G.marker(v.genome),625,303,15,palette.teal);text('Generation '..(v.generation or 0)..' / mutations '..#v.genome.mutations..'\nSource: '..tostring(v.source or v.parent or 'Laboratory')..'\n'..(v.type and ('Cell category: '..require('biology').types[v.type]..' / viability '..math.floor(v.viability*100)..'%') or 'Archived DNA sequence; not living material.'),625,352,15,palette.muted)
  button('Inspect / edit genome copy',625,465,735,35,function() A.openGenome(v) end)
  button('Pin genome comparison',625,516,352,35,function() A.pinned=G.copy(v.genome);Host.message('Genome pinned for comparison.') end)
  if A.pinned then text('Allele similarity: '..string.format('%.1f%%',G.similarity(v.genome,A.pinned)*100),996,525,15,palette.teal) end
  if cryobank then button('Retrieve into a container...',625,576,735,35,function() require('desktop_supply_menus').destination(s,v.id) end) elseif v.type then button('Preserve this cell',625,576,352,35,function() result(require('biology').freeze(s,A.record)) end);button('Extract DNA',996,576,364,35,function() result(require('biology').extract(s,A.record));Host.sync() end) end
  if v.type then button('Magnified cell inspection',625,632,735,35,function() A.microscope=v end) end
  button('Mutation history & regulation',625,686,735,35,function() A.historyRecord=v;A.historyPage=1;A.page='History' end)
 end
end
local function behavior(s)
 heading('Behavior & social journal','Perceived experiences, inherited nature and directional relationships from the living simulation.')
 local o=s.organisms[A.record];if not o then text('Choose an organism in Records.',250,190,20);return end
 local Cog=require('cognition');local nature=Cog.nature(o);local cognitive=Cog.ensure(o);local capacity=Cog.capabilities(o)
 card(250,180,1140,150);text(o.name..' / '..o.behavior,273,200,24);text('Memory capacity '..capacity.capacity..' / learning '..string.format('%.2f',capacity.learning)..' / stress '..string.format('%.2f',cognitive.stress or 0),273,243,16,palette.teal)
 text(string.format('Sociability %.2f   Curiosity %.2f   Fearfulness %.2f   Tolerance %.2f   Aggression %.2f',nature.sociability,nature.curiosity,nature.fearfulness,nature.tolerance,nature.aggression),273,286,15,palette.muted)
 card(250,351,550,467);text('Recent memories',273,373,23)
 for i=math.max(1,#cognitive.memories-9),#cognitive.memories do local m=cognitive.memories[i];local row=i-math.max(1,#cognitive.memories-9);text(m.kind..' / outcome '..string.format('%.2f',m.outcome or 0)..' / strength '..string.format('%.2f',m.strength),273,420+row*34,13,palette.muted) end
 card(820,351,570,467);text('Relationships',843,373,23);local row=0
 for id,r in pairs(cognitive.relationships) do if row<9 then text('#'..id..' / trust '..string.format('%.2f',r.trust)..' / fear '..string.format('%.2f',r.fear)..' / familiarity '..string.format('%.2f',r.familiarity),843,420+row*36,13,palette.muted);row=row+1 end end
 text('Signals expressed: '..#cognitive.events..' / no speech or combat',843,766,13,palette.teal)
end
local function settings(s)
 heading('Settings & recovery','Desktop settings are separate from the preserved ecology and engineering versions.')
 card(250,180,1140,640);local d=s.desktop
 button('Classic interface: OFF',275,207,520,44,function() d.settings.classicUI=true;Host.context.classic() end)
 text('Optional compatibility interface. The default desktop edition never opens the classic UI.',820,220,12,palette.muted)
 button('Always on top: '..tostring(d.settings.alwaysOnTop),275,273,520,40,function() d.settings.alwaysOnTop=not d.settings.alwaysOnTop end)
 text('PC-linked time / no speed or pause controls',820,286,14,palette.teal)
 button('Save experiment + layout',275,335,340,40,function() d.savedLayout=M.layout(s);Host.save() end)
 button('Restore saved layout',630,335,340,40,function() if d.savedLayout then M.applyLayout(s,d.savedLayout,Host.monitors) else Host.message('No saved layout yet.') end end)
 button('Reset positions...',985,335,379,40,function() if require('native_windows').confirm('Reset equipment positions? All cultures will remain intact.') then M.reset(s,Host.monitors) end end)
 button('Start a new experiment...',275,398,520,40,function() if require('native_windows').confirm('Start a new desktop experiment? The next desktop save will replace the current session. Other versions are unaffected.') then Host.context.newExperiment() end end,false,true)
 button('Restore all stored objects',820,398,544,40,function() for _,o in ipairs(d.objects) do if not o.archivedEntity then o.stored=false;o.visible=true end end end)
 button('Anatomy Generator / developer tool',820,460,544,40,function() A.page='Anatomy Generator' end)
 text('PERSISTENCE',275,485,14,palette.teal);text('The desktop revision saves on exit and restores on launch.\nDrop a previous experiment.lua file onto this window to migrate it.\nPC elapsed time is preserved, including while hidden or closed.\nClosing this window returns to the real Windows tray. Exit from the tray or press Ctrl+Q.',275,523,15,palette.muted)
 text('Connected monitors: '..#Host.monitors,275,641,15,palette.teal)
 for i,m in ipairs(Host.monitors) do text(m.id..' / '..m.w..'x'..m.h..' / '..m.x..', '..m.y..' / '..m.dpi..' DPI',275,674+(i-1)*25,13,palette.muted) end
 text('Recovery shortcut: Ctrl+Shift+L hides desktop objects and opens this window.',275,778,14,palette.teal)
end
local function history(s)
 heading('Genetic & developmental history','Recorded changes and growth operations from the selected persistent record.')
 local v=A.historyRecord;if not v then return end;local changes={}
 for _,m in ipairs(v.genome.mutations or {}) do changes[#changes+1]=(({'L','D','E'})[m.site or 1] or '?')..m.locus..' / '..tostring(m.from)..' -> '..tostring(m.to)..' / '..tostring(m.stage)..' / '..tostring(m.effect or 'Inherited change') end
 for _,r in ipairs(v.genome.regulation or {}) do changes[#changes+1]='REGULATION / '..r.sourceChromosome..':'..r.sourceSite..' '..r.mode..' '..r.targetChromosome..':'..r.targetSite end
 if v.anatomy then for _,op in ipairs(v.anatomy.operations or {}) do changes[#changes+1]='GROWTH / '..op.operation..' / region '..tostring(op.region)..' / parent '..tostring(op.parent or 'embryo') end end
 card(250,180,1140,639);text((v.name or 'Genome')..' / '..#changes..' records',273,203,24)
 A.historyPage=math.max(1,math.min(A.historyPage or 1,math.max(1,math.ceil(#changes/12))))
 for row=0,11 do local entry=changes[(A.historyPage-1)*12+row+1];if entry then text(entry:sub(1,135),273,260+row*37,13,palette.muted) end end
 button('< Previous',273,755,260,35,function() A.historyPage=math.max(1,A.historyPage-1) end);button('Next >',550,755,260,35,function() A.historyPage=math.min(math.max(1,math.ceil(#changes/12)),A.historyPage+1) end);text('Page '..A.historyPage..' / '..math.max(1,math.ceil(#changes/12)),846,766,14,palette.teal)
end
local function observations(s)
 heading('Research observations','The simulation journal and discovered anatomy families, without a second record store.')
 local discoveries=0;for _ in pairs(s.discoveries) do discoveries=discoveries+1 end;card(250,180,1140,639);text(discoveries..' anatomy / pigment families discovered',273,204,23,palette.teal)
 A.observationPage=A.observationPage or 1;for row=0,11 do local entry=s.history[(A.observationPage-1)*12+row+1];if entry then text(entry:sub(1,142),273,265+row*37,14,palette.muted) end end
 button('< Newer',273,755,260,35,function() A.observationPage=math.max(1,A.observationPage-1) end);button('Older >',550,755,260,35,function() A.observationPage=math.min(math.max(1,math.ceil(#s.history/12)),A.observationPage+1) end)
end
local function containerLabel(s)
 heading('Label this container','Give this individual vial, flask, dish or plate a name.')
 local e=A.labelEdit;if not e then return end;card(250,180,1140,420)
 text('Container #'..e.id..' / '..(e.kind=='dna' and 'DNA vial' or 'physical container'),280,210,18,palette.teal)
 text('Type a label (up to 40 characters)',280,260,16,palette.muted)
 set(palette.tint);love.graphics.rectangle('fill',280,300,1080,64,6);text(e.draft..'_',300,320,22)
 text('Typing replaces the selected name. Ctrl+A selects all. Enter saves; Escape cancels.',280,393,14,palette.muted)
 button('Save label',280,465,340,44,function() A.finishLabel(s,true) end,true)
 button('Clear label',640,465,340,44,function() e.draft='';A.finishLabel(s,true) end)
 button('Cancel',1000,465,360,44,function() A.finishLabel(s,false) end)
end
function A.draw(s,context)
 A.context=context;set(palette.bg);love.graphics.rectangle('fill',0,0,1440,900)
 set({.095,.16,.19});love.graphics.rectangle('fill',0,0,1440,55);text('CELLARIUM',24,17,17,{.9,.98,.96});text('local laboratory  /  '..A.page:lower(),252,19,13,{.69,.81,.82});text(Clock.wallTime(),1110,19,12,{.67,.84,.79});button('Return to desktop',1254,10,167,34,function() Host.hidePanel() end)
 set({.89,.92,.93});love.graphics.rectangle('fill',0,55,220,845);text('LABORATORY',24,88,11,palette.muted)
 for i,page in ipairs({'Lab','Cultures','Genome Forge','Incubation','Habitats','Records','Research','Cryobank','Settings'}) do button(page,16,119+(i-1)*51,188,42,function() A.page=page;A.editing=nil end,A.page==page) end
 text('Desktop edition\nNative equipment & tray\nLocal biological records',25,737,12,palette.muted)
 button('Save laboratory',16,815,188,36,function() Host.save() end)
 if A.page=='Container label' then containerLabel(s) elseif A.page=='Anatomy Generator' then require('anatomy_dev_ui').draw(s,{text=text,button=button,card=card,register=context.register}) elseif A.page=='Lab' then lab(s) elseif A.page=='Cultures' then cultures(s) elseif A.page=='Genome Forge' then forge(s) elseif A.page=='Assembly' then assembly(s) elseif A.page=='Incubation' then incubation(s) elseif A.page=='Habitats' then habitats(s) elseif A.page=='Records' then records(s,false,false) elseif A.page=='Research' then records(s,false,true) elseif A.page=='Cryobank' then records(s,true,false) elseif A.page=='Behavior' then behavior(s) elseif A.page=='History' then history(s) elseif A.page=='Observations' then observations(s) else settings(s) end
 if A.preview and E.forecast and A.page=='Genome Forge' then
  set({.03,.08,.10,.65});love.graphics.rectangle('fill',220,55,1220,806);card(450,180,700,540);text('Developed body forecast',475,205,25);text((E.forecast.viable and 'Viable' or 'Nonviable')..' / '..E.forecast.caps.locomotion..' / '..#E.forecast.regions..' regions',475,249,16,palette.teal)
  R.draw({anatomy=E.forecast,genome=E.draft,caps=E.forecast.caps,maturity=1,alive=true,behavior='Resting',angle=0},800,444,R.fitScale(E.forecast,570,270,4),0,'External')
  text('Forecast only. Incubation must still complete its biological viability checks.',475,637,14,palette.muted);button('Close forecast',475,671,650,34,function() A.preview=false end)
 end
 if A.microscope then
  local cell=A.microscope;set({.03,.08,.1,.65});love.graphics.rectangle('fill',220,55,1220,806);card(450,175,700,555);text('Magnified cell schematic / #'..cell.id,475,199,24);text(require('biology').types[cell.type]..' / viability '..math.floor(cell.viability*100)..'% / genome '..G.hash(cell.genome),475,244,14,palette.muted)
  local c=require('biology').colors[cell.type];local points={};for i=0,63 do local angle=i/64*math.pi*2;local radius=116*(1+.04*math.sin(angle*5+G.hash(cell.genome)%11));points[#points+1]=800+math.cos(angle)*radius;points[#points+1]=442+math.sin(angle)*radius end;set({c[1],c[2],c[3],.3});love.graphics.polygon('fill',points);set(palette.teal);love.graphics.polygon('line',points);set({.2,.42,.48,.5});love.graphics.ellipse('fill',781,448,35,30);for i=1,11 do local angle=i*2.4;set({c[1]*.6,c[2]*.7,c[3]*.7,.7});love.graphics.ellipse('fill',800+math.cos(angle)*(55+i*3),442+math.sin(angle)*(55+i*3),7,4) end
  text('A category-based magnified illustration; colonies in dishes are shown at normal desktop scale.',475,633,13,palette.muted);button('Close magnification',475,677,650,34,function() A.microscope=nil end)
 end
 set({.86,.9,.91});love.graphics.rectangle('fill',220,861,1220,39);text(Clock.busy(s) and Clock.status(s) or Host.notice or 'Left-drag the dropper. Right-click opens actions. Release its loaded tip over a destination to dispense.',244,874,12,palette.muted)
end
return A
