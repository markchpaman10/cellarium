local B=require('biology');local Habi=require('habitat');local Units=require('units');local Library=require('cell_library');local Forge=require('forge_ui');local HabitatView=require('habitat_view')
local G=require('genome');local R=require('rendering');local U=require('research');local S=require('persistence');local V=require('vessels');local VesselUI=require('vessel_ui')
local Host=require('desktop_host');local DesktopPanel=require('desktop_panel');local DesktopApp=require('desktop_app');local desktopActive=false
local RealClock=require('realtime')
local s,tab,selected,donors,medium,environment,notice,toastTime
local buttons,fonts={},{}
local W,H=1440,900
local smoke=false
local developmentRun=false
local uiTest=false
local gallery=false
local C={bg={.027,.047,.063},panel={.048,.077,.094},line={.12,.20,.23},text={.86,.92,.91},muted={.43,.58,.61},mint={.45,.95,.76}}
local function col(c,a) love.graphics.setColor(c[1],c[2],c[3],a or 1) end
local function text(t,x,y,size,c) size=size or 14;fonts[size]=fonts[size] or love.graphics.newFont(size);love.graphics.setFont(fonts[size]);col(c or C.text);love.graphics.print(t,x,y) end
local function panel(x,y,w,h) col(C.panel);love.graphics.rectangle('fill',x,y,w,h,12);col(C.line);love.graphics.rectangle('line',x,y,w,h,12) end
local function msg(t) notice=t;toastTime=4 end
local function button(label,x,y,w,h,fn,active,disabled)
 local mx,my=love.mouse.getPosition();mx=mx/love.graphics.getWidth()*W;my=my/love.graphics.getHeight()*H
 local hover=mx>=x and mx<x+w and my>=y and my<y+h
 col(active and C.mint or (hover and {.14,.24,.26} or {.09,.15,.17}),disabled and .35 or 1);love.graphics.rectangle('fill',x,y,w,h,7)
 col(active and C.mint or C.line);love.graphics.rectangle('line',x,y,w,h,7)
 love.graphics.setFont(fonts[13]);col(active and C.bg or (disabled and C.muted or C.text));love.graphics.printf(label,x,y+h/2-8,w,'center')
 if not disabled then buttons[#buttons+1]={x=x,y=y,w=w,h=h,fn=fn,label=label} end
end
local function ring(x,y,r,c,a) col(c,a);love.graphics.circle('line',x,y,r) end
local function cell(x,y,r,typ,g,t)
 local c=B.colors[typ];love.graphics.setLineWidth(1)
 for j=5,1,-1 do col(c,.015*j);love.graphics.circle('fill',x,y,r+j*3) end
 local pts={};for i=0,63 do local a=i/64*math.pi*2;local rad=r*(1+.055*math.sin(a*(typ%3+3)+t));pts[#pts+1]=x+math.cos(a)*rad;pts[#pts+1]=y+math.sin(a)*rad end
 col(c,.13);love.graphics.polygon('fill',pts);col(c,.65);love.graphics.polygon('line',pts)
 ring(x,y,r*.88,c,.2)
 for i=1,8 do local a=i*2.399+typ;local d=r*(.35+(i%3)*.14);local px,py=x+math.cos(a+t*.06)*d,y+math.sin(a+t*.06)*d;col(c,.35);love.graphics.ellipse('fill',px,py,2+i%3,1.5+i%2) end
 col(c,.45);love.graphics.circle('fill',x-r*.16,y+r*.08,r*.31);ring(x-r*.16,y+r*.08,r*.32,c,.8)
 col(c,.9);love.graphics.circle('fill',x-r*.2,y+r*.05,r*.09)
 col({1,1,1},.45);love.graphics.arc('line','open',x,y,r*.95,3.5,4.5)
 if typ==3 then for i=1,6 do local a=i*math.pi/3;col(c,.4);love.graphics.line(x+math.cos(a)*r,y+math.sin(a)*r,x+math.cos(a+.16)*r*1.4,y+math.sin(a+.16)*r*1.4) end end
end
local function organism(o,x,y,scale,t,detail) local adjusted=scale*.65;if scale>1 then adjusted=R.fitScale(o.anatomy,270,185,adjusted) end;R.draw(o,x,y,adjusted,t,'External') end
local function save() if desktopActive then Host.save();return end;local ok,why=S.save(s);msg(ok and 'Experiment saved with canonical genomes and anatomy.' or ('Save failed: '..tostring(why))) end
local function loadSave()
 if desktopActive then local restored,why=require('desktop_store').load(B);if restored then s=restored;donors={};selected=nil;Host.saveBlocked=false;Host.sync();msg('Desktop experiment restored.');return true end;msg(tostring(why));return false end
 local raw=love.filesystem.read('experiment.lua');if not raw then return false end
 local data,why=S.decode(raw,B);if data then s=data;V.ensure(s);donors={};selected=nil;environment=s.habitat.environment;msg('Experiment restored.');return true end
 msg('Save could not load: '..tostring(why));return false
end
function love.load()
 for _,a in ipairs(arg or {}) do if a=='--desktop-test' or a=='--desktop-native-test' then local ok,result=xpcall(function() return require('desktop_tests').run(B,a=='--desktop-native-test') end,debug.traceback);local f=assert(io.open((love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or love.filesystem.getSource())..'/desktop-test-results.txt','w'));f:write(result);f:close();love.event.quit(ok and 0 or 1);return end end
 for _,a in ipairs(arg or {}) do if a=='--audit' or a=='--ecology-audit' then local ok,result=pcall(function() return require(a=='--ecology-audit' and 'ecology_audit' or 'audit').run(B) end);if not ok then local f=io.open(love.filesystem.getSource()..'/audit-error.txt','w');if f then f:write(tostring(result));f:close() end end;love.event.quit(ok and result and 0 or 1);return end end
 for _,a in ipairs(arg or {}) do if a=='--test' then local ok,result=pcall(require('tests'),B);local f=io.open(love.filesystem.getSource()..'/test-results.txt','w');if f then f:write(ok and result or tostring(result));f:close() end;love.event.quit(ok and 0 or 1);return end end
 for _,n in ipairs({11,12,13,14,16,18,20,24,28,32,40}) do fonts[n]=love.graphics.newFont(n) end
 R.init();love.graphics.setBackgroundColor(C.bg);s=B.new();B.collect(s);tab=1;donors={};medium=1;environment=1;toastTime=0
 V.ensure(s);B.log(s,'New experiment. Select a strain to begin cultivation. Load restores a manual save.')
 for _,a in ipairs(arg or {}) do
  if a=='--ui-test' then uiTest=true;developmentRun=true;s=B.new(34);B.collect(s);toastTime=0 end
  if a:find('smoke') then smoke=true;developmentRun=true;toastTime=0;s=B.new(42);B.collect(s)
   if a~='--smoke' then for i=1,7 do local o=B.spawn(s,s.cells[i].genome,'Render check',0);if o then o.maturity=1;o.bodyCondition=1 end end;for i=1,40 do B.update(s,.05,1) end;tab=3;selected=1 end
   if a=='--habitat-smoke' then for i=1,180 do B.update(s,.1) end elseif a=='--diversity-smoke' then gallery=true;local fixtures=require('audit_examples');s=B.new(42);for _,key in ipairs({'compact','elongatedLimbless','multilegged','radial','asymmetric','branched'}) do local specimen=fixtures[key];local o=assert(B.spawn(s,G.copy(specimen.genome),'Audit sample '..specimen.sample,0));o.name=key;o.sample=specimen.sample;o.maturity=1;o.behavior='Exploring' end elseif a=='--development-smoke' then tab=5;U.source='organisms';U.index=1;U.view='Development' elseif a=='--development-genome-smoke' then tab=5;U.source='cells';U.index=1;U.view='Genome';U.genomePage=2 elseif a=='--ecology-smoke' then tab=5;U.source='organisms';U.index=1;U.view='Environment' elseif a=='--defenses-smoke' then tab=5;U.openOrganism(s,1);U.layer='Defenses' elseif a=='--ecology-smoke' then tab=5;U.source='organisms';U.index=1;U.view='Environment' elseif a=='--defenses-smoke' then tab=5;U.openOrganism(s,1);U.layer='Defenses' elseif a=='--genome-smoke' then tab=5;U.view='Genome' elseif a=='--anatomy-smoke' then tab=5;U.openOrganism(s,1);U.layer='Organs' elseif a=='--engineering-smoke' then tab=5;U.view='Engineering';B.precursor(s,1,'Egg');B.precursor(s,1,'Sperm') elseif a=='--physiology-smoke' then tab=5;U.source='organisms';U.index=1;U.view='Physiology' elseif a=='--incubation-smoke' then B.combine(s,{s.cells[1].id,s.cells[2].id,s.cells[3].id});B.update(s,12,1);tab=2 elseif a=='--culture-smoke' then B.cultivate(s,1,1);tab=5;U.view='Cultures' elseif a=='--forge-smoke' then tab=2;donors={s.cells[1].id,s.cells[2].id,s.cells[3].id} end
  end
 end
 local enable=true;for _,a in ipairs(arg or {}) do if a=='--no-desktop' or a:find('smoke') or a=='--ui-test' then enable=false end end
 if enable then
  Host.init({B=B,getState=function() return s end,setState=function(value) s=value end,msg=msg,setDesktopActive=function(v) desktopActive=v end,
   classic=function() tab=6;Host.inspector=nil;Host.mode='settings' end,
   newExperiment=function() s=B.new();B.collect(s);V.ensure(s);require('desktop_model').ensure(s);require('desktop_worlds').ensure(s);RealClock.start(s);Host.saveBlocked=false;donors={};selected=nil;Host.sync();DesktopApp.page='Lab';msg('New desktop experiment started.') end,
   openGenome=function(value) if not s.desktop.settings.classicUI then DesktopApp.openGenome(value) else require('genome_editor').begin(value);U.view='Genome Edit';tab=5 end;Host.panelVisible=true;require('native_windows').panel(true) end,
   open=function(mode,id)
    selected=nil
    if not s.desktop.settings.classicUI then DesktopApp.open(mode,id,s);return end
    if mode=='workstation' then tab=1 elseif mode=='forge' then tab=2 elseif mode=='research' then tab=4 elseif mode=='genomes' then tab=5;U.view='Genome';U.source='materials';U.index=1
    elseif mode=='organisms' or mode=='organism' then tab=5;U.view='Physiology';U.source='organisms';U.index=1;for i,v in ipairs(s.organisms) do if v.id==id then U.index=i end end
    else tab=6 end
   end})
 end
end
function love.update(dt)
 if not s then return end
 if uiTest then
  uiTest=false
  local ok,why=pcall(function()
   local function click(x,y) love.draw();love.mousepressed(x/W*love.graphics.getWidth(),y/H*love.graphics.getHeight(),1) end
   local function press(label) love.draw();for i=#buttons,1,-1 do if buttons[i].label==label then local b=buttons[i];click(b.x+b.w/2,b.y+b.h/2);return end end;error('Missing UI button: '..label) end
   click(120,418);press('Seed selected cell');assert(#s.dishes==1,'Seed UI');B.update(s,100);love.draw();click(420,608);assert(#s.dishes==0,'Harvest UI')
   click(120,418);press('Freeze specimen');assert(#s.frozen==1,'Freeze UI');click(1000,115);click(600,330);assert(#s.frozen==0,'Thaw UI')
   click(450,115);click(120,418);click(462,430);click(120,456);click(686,430);click(120,494);click(910,430);assert(#donors==3,'Donor UI');press('Fuse genomes & begin development');assert(#s.eggs==1,'Fusion UI');B.update(s,70);assert(#s.organisms==1,'Development UI')
   click(700,115);local o=s.organisms[1];click(49+o.x*981,256+o.y*576-(o.altitude or 0)*65);press('Inspect anatomy & chromosomes');assert(tab==5 and U.source=='organisms','Inspect UI')
   press('Rename');love.textinput('Test');love.keypressed('return');assert(o.name:find('Test'),'Rename UI')
   click(90,270);click(120,363);press('Engineering');press('Extract DNA template');assert(#s.materials==1,'Extraction UI')
   B.collect(s);U.index=#s.cells-6;press('Stem > egg precursor');press('Stem > sperm precursor');assert(#s.gametes==2,'Precursor UI');B.update(s,9);click(500,528);click(500,561);press('Fertilize selected egg + sperm');assert(#s.gametes==0 and #s.eggs==1,'Fertilization UI')
   local b=assert(B.spawn(s,o.genome,'UI second parent',0));o.maturity=1;b.maturity=1;o.energy=90;b.energy=90;click(200,270);click(120,363);press('Set selected creature as A');click(120,394);press('Set selected creature as B');press('Breed selected parents');assert(#s.eggs==2,'Breeding UI')
   press('Environment');assert(U.view=='Environment','Ecology inspection UI');press('Genome');press('Primary loci >');press('Development loci >');assert(U.genomePage==3,'Ecology chromosome page UI')
   press('New');assert(#s.organisms==0 and #s.cells==7 and tab==1,'New session UI')
  end)
  local f=io.open(love.filesystem.getSource()..'/ui-test-results.txt','w');if f then f:write(ok and 'PASS: real mouse/key callbacks for seeding, harvesting, freezing, thawing, donor selection, fusion, development, inspection, naming, extraction, gamete formation, fertilization, selective breeding.' or tostring(why));f:close() end
  love.event.quit(ok and 0 or 1);return
 end
 local visualDt=math.min(dt,.1);if not developmentRun then RealClock.update(s,B.update) else B.update(s,dt) end;if desktopActive then Host.update(visualDt) end;toastTime=math.max(0,toastTime-visualDt)
end
local function genePanel(c,x,y)
 local e=G.express(c.genome)
 for i=1,6 do text(B.genes[i],x,y+(i-1)*25,12,C.muted);col(C.line);love.graphics.rectangle('fill',x+125,y+(i-1)*25+3,140,5);col(B.colors[c.type or 1]);love.graphics.rectangle('fill',x+125,y+(i-1)*25+3,140*e[i],5) end
 text('Marker '..G.marker(c.genome)..' / G'..c.generation,x,y+158,12,C.mint)
 text('Viability '..math.floor(c.viability*100)..'% / divisions '..c.replicationCapacity,x,y+184,12,C.muted)
 text('Full chromosomes in Research',x,y+211,12,C.muted)
end
local function header()
 text('C E L L A R I U M',32,23,24);text('L I V I N G   L A B O R A T O R Y',34,57,11,C.muted)
 text('EXPERIMENT  /  001',1030,26,12,C.muted);text(RealClock.wallTime(),1030,47,20,C.mint)
 button('Save',1180,26,76,36,save);button('Load',1264,26,76,36,function() if not loadSave() then msg('No saved experiment yet.') end end)
 button('New',1348,26,60,36,function() s=B.new();B.collect(s);V.ensure(s);tab=1;selected=nil;donors={};Library.filter=0;Library.page=1;Library.favoritesOnly=false;medium=1;environment=1;U.index=1;U.compare=nil;msg('New experiment started. Manual save has not been overwritten.') end)
 local names={'01   Cell workstations','02   Genome forge','03   Living habitat','04   Cryobank & records','05   Research'}
 for i,n in ipairs(names) do button(n,32+(i-1)*277,94,265,43,function() tab=i;selected=nil end,tab==i) end
 local alive=0;for _,o in ipairs(s.organisms) do if o.alive then alive=alive+1 end end
 text(#s.cells..' specimens    /    '..#s.frozen..' preserved    /    '..alive..' living    /    generation '..s.generation,34,158,13,C.muted)
 if desktopActive then button('New UI',1348,148,60,32,function() s.desktop.settings.classicUI=false;Host.open('settings') end) end
end
local function library(x,y,w,h,forForge)
 Library.draw(s,x,y,w,h,{text=text,button=button,panel=panel,col=col,msg=msg,C=C,B=B,selected=selected,donors=donors,select=function(i) selected=i end})
end
local function cultivation()
 library(32,202,260,650)
 VesselUI.draw(s,{text=text,button=button,panel=panel,msg=msg,C=C,B=B,selected=selected,clearSelection=function() selected=nil end})
end

local function forge()
 library(32,202,260,650,true)
 Forge.draw(s,{text=text,button=button,panel=panel,col=col,msg=msg,C=C,B=B,selected=selected,donors=donors,cell=cell,organism=organism,finished=function() donors={};selected=nil end})
end
local function habitat()
 HabitatView.draw(s,{text=text,button=button,panel=panel,col=col,msg=msg,C=C,B=B,organism=organism,selected=selected})
 panel(1067,202,341,650);text('FIELD OBSERVATIONS',1089,225,13,C.mint)
 local o=selected and s.organisms[selected]
 if o then organism(o,1235,355,2.2,s.time);text(o.name,1089,454,24);text('Generation '..o.generation..'  /  '..o.behavior,1089,493,14,C.mint);text('Parents: '..o.parents,1089,522,12,C.muted)
  for i,v in ipairs({{'Energy',o.energy},{'Health',o.health}}) do text(v[1],1089,556+(i-1)*35,12,C.muted);col(C.line);love.graphics.rectangle('fill',1160,561+(i-1)*35,220,6);col(i==1 and {.93,.76,.41} or C.mint);love.graphics.rectangle('fill',1160,561+(i-1)*35,220*v[2]/100,6) end
  text('Age '..RealClock.biologyDuration(o.age)..' / '..(o.lifeStage or 'Juvenile'),1089,635,13,C.muted)
  text(string.format('%s / O2 %.0f%%',o.environment or 'land',(o.oxygen or 1)*100),1089,675,13);button('Inspect anatomy & chromosomes',1089,704,297,32,function() U.openOrganism(s,selected);tab=5 end)
  button('Sample living tissue',1089,770,297,42,function() if o.alive then for typ=1,7 do s.cells[#s.cells+1]=B.cell(s,typ,o.genome,'Organism '..o.id,o.generation) end;msg('Seven tissue samples collected with the inherited genome.') else msg('This organism is no longer alive.') end end)
 else text('Click a creature to inspect it.',1089,292,18);text('Creatures seek food and fresh water,\nrest when tired, mature and age.\n\nBones, muscles, nerves and organs\nshape their actual capabilities.\n\nCompatible mature pairs can breed\nautomatically when well nourished.\nOffspring inherit chromosomes from\nboth parents.\n\nClick a creature, then inspect its\nanatomy and chromosomes to\nunderstand its strengths and costs.',1089,342,14,C.muted) end
end
local function records()
 panel(32,202,665,650);text('The genetic archive.',55,225,28);text('Frozen specimens retain their exact genome. Thaw to use again.',55,271,14,C.muted)
 for i=1,math.min(9,#s.frozen) do local c=s.frozen[i];local yy=316+(i-1)*53;cell(83,yy+15,15,c.type,c.genome,s.time*.2);text(B.types[c.type]..'  /  '..c.id,115,yy,16);text(G.marker(c.genome)..' / '..c.name,115,yy+24,11,C.muted);button('Thaw',566,yy,106,36,function() B.thaw(s,i);msg('Specimen thawed into the cell library.') end) end
 if #s.frozen==0 then text('Preserve a promising strain from Cultivation.\nIts genes will remain unchanged in cold storage.',55,355,16,C.muted) end
 if #s.frozen>9 then button('Rotate archive',55,807,180,28,function() table.insert(s.frozen,table.remove(s.frozen,1)) end) end
 panel(717,202,691,650);text('EXPERIMENT JOURNAL',740,229,13,C.mint);local n=0;for _ in pairs(s.discoveries) do n=n+1 end;text(n..' anatomy / pigment families discovered',740,268,18)
 for i=1,math.min(13,#s.history) do text(string.format('%02d',#s.history-i+1),740,321+(i-1)*37,11,C.mint);text(s.history[i],778,318+(i-1)*37,13,C.muted) end
end
local function drawGallery()
 text('G R O W N ,  N O T  S E L E C T E D .',32,26,28,C.text)
 text('Six actual viable results from the seeded 1,000-wild-fusion audit. One developmental generator; no animal templates.',34,76,16,C.muted)
 local titles={'Compact','Elongated, limbless','Multiple jointed appendages','Radial growth','Asymmetric growth','Recursive branches'}
 for i,o in ipairs(s.organisms) do local x=32+(i-1)%3*464;local y=126+math.floor((i-1)/3)*364;local a=o.anatomy;panel(x,y,440,344)
  text(titles[i],x+18,y+17,20,C.mint);text('WILD FUSION / SAMPLE '..o.sample,x+18,y+49,11,C.muted)
  local scale=R.fitScale(a,385,192,5);R.draw(o,x+220,y+174,scale,0,'External')
  text(a.symmetry..' / '..a.appendageCount..' extensions / '..a.caps.locomotion,x+18,y+278,13,C.text)
  text(#a.regions..' regions / '..a.exchangeMethod..' exchange / DNA '..G.marker(o.genome),x+18,y+308,12,C.muted)
 end
 text('Preserved legacy generator remains available as fallback. Genotypes and full frequency measurements accompany this build.',34,870,12,C.muted)
end
function love.draw()
 if not s then return end
 love.graphics.push();love.graphics.scale(love.graphics.getWidth()/W,love.graphics.getHeight()/H);buttons={}
 if desktopActive and not s.desktop.settings.classicUI then DesktopApp.draw(s,{register=function(x,y,w,h,fn,label) buttons[#buttons+1]={x=x,y=y,w=w,h=h,fn=fn,label=label} end});love.graphics.pop();return end
 if not gallery then header() end
 if gallery then drawGallery() elseif tab==1 then cultivation() elseif tab==2 then forge() elseif tab==3 then habitat() elseif tab==4 then records() elseif tab==6 then DesktopPanel.draw(s,{text=text,button=button,panel=panel,col=col,msg=msg,C=C,B=B}) else U.draw(s,{text=text,button=button,panel=panel,col=col,msg=msg,C=C,B=B}) end
 if not gallery then text('PC real time   ·   1–5 workspaces   ·   S save   ·   Click creatures to inspect',34,875,11,C.muted);text('PROCEDURAL LIFE / SEEDED GENETICS',1110,875,11,C.muted) end
 if toastTime>0 and notice then col({.12,.25,.23},.98);love.graphics.rectangle('fill',320,822,760,45,8);text(notice,338,836,14,C.mint) end
 love.graphics.pop()
 if smoke then smoke=false;love.graphics.captureScreenshot(function(data) local bytes=data:encode('png');local f=io.open(love.filesystem.getSource()..'/preview.png','wb');if f then f:write(bytes:getString());f:close() end;love.event.quit() end) end
end
function love.mousepressed(mx,my,b)
 if b~=1 then return end;local x,y=mx/love.graphics.getWidth()*W,my/love.graphics.getHeight()*H
 for i=#buttons,1,-1 do local v=buttons[i];if x>=v.x and x<=v.x+v.w and y>=v.y and y<=v.y+v.h then if not RealClock.sync(s,B.update) then msg('Synchronizing elapsed PC time. Please wait.') else v.fn() end;return end end
 if desktopActive and not s.desktop.settings.classicUI then return end
 if tab==5 then U.mousepressed(x,y) end
 if tab==3 then local dist=50^2;selected=nil;for i,o in ipairs(s.organisms) do local d=(x-(49+o.x*981))^2+(y-(256+o.y*576-(o.altitude or 0)*65))^2;if d<dist then selected=i;dist=d end end end
end
function love.textinput(t) if desktopActive and not s.desktop.settings.classicUI then DesktopApp.textinput(t) elseif tab==6 then DesktopPanel.textinput(t) elseif tab==5 then U.textinput(t) end end
function love.keypressed(k)
 if desktopActive and not s.desktop.settings.classicUI then if DesktopApp.keypressed(k) then return end
 elseif tab==6 and DesktopPanel.keypressed(k,s) then return elseif tab==5 and U.keypressed(k,s) then return end
 if k=='q' and love.keyboard.isDown('lctrl','rctrl') then Host.exiting=true;love.event.quit();return end
 if k=='escape' and desktopActive then Host.hidePanel();return end
 if k=='s' then save() elseif (not desktopActive or s.desktop.settings.classicUI) and tonumber(k) and tonumber(k)>=1 and tonumber(k)<=6 then tab=tonumber(k);selected=nil end
end
function love.quit() if desktopActive then if not Host.exiting then Host.hidePanel();return true end;Host.shutdown() end end
function love.filedropped(file)
 file:open('r');local raw=file:read();file:close();local restored,why=require('desktop_store').decode(raw,B)
 if not restored then msg('Import rejected: '..tostring(why));return end
 if desktopActive and not require('native_windows').confirm('Import this experiment into the desktop revision? The current in-memory laboratory will be replaced. Other versions are unaffected.') then return end
 s=restored;donors={};selected=nil;if desktopActive then Host.saveBlocked=false;Host.sync();Host.open('settings') end;msg('Experiment imported through the versioned migration path.')
end
function love.errorhandler(errorMessage)
 local log=io.open((love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or love.filesystem.getSource())..'/desktop-error.txt','w');if log then log:write(tostring(errorMessage)..'\n'..debug.traceback());log:close() end
 pcall(function() require('native_windows').panel(true);Host.exiting=true;require('native_windows').shutdown() end);desktopActive=false
 if not love.graphics then return function() return 1 end end
 pcall(function() love.graphics.setCanvas();love.graphics.reset() end)
 local errorFont=love.graphics.newFont(15)
 return function()
  love.event.pump();for name,a in love.event.poll() do if name=='quit' or (name=='keypressed' and a=='escape') then return 1 end end
  love.graphics.clear(.04,.07,.09,1);love.graphics.setFont(errorFont);love.graphics.setColor(.95,.86,.76,1);love.graphics.printf('Cellarium stopped safely. Native equipment and the tray icon have been removed.\n\n'..tostring(errorMessage)..'\n\nClose this window to exit. A diagnostic was written beside the application. The previous desktop save was retained.',35,45,love.graphics.getWidth()-70);love.graphics.present();love.timer.sleep(.05)
 end
end
-- Keep event processing alive with SDL's detail window hidden, without spinning at full CPU.
function love.run()
 if love.load then love.load(love.arg.parseGameArguments(arg),arg) end
 if love.timer then love.timer.step() end
 return function()
  if love.event then love.event.pump();for name,a,b,c,d,e,f in love.event.poll() do if name=='quit' then if not love.quit or not love.quit() then return a or 0 end end;love.handlers[name](a,b,c,d,e,f) end end
  local dt=love.timer and love.timer.step() or .016;if love.update then love.update(dt) end
  if love.graphics and love.graphics.isActive() then love.graphics.origin();love.graphics.clear(love.graphics.getBackgroundColor());if love.draw then love.draw() end;love.graphics.present() end
  if love.timer then love.timer.sleep(desktopActive and not Host.panelVisible and .02 or .005) end
 end
end

