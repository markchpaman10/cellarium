return function(B,test)
 local App=require('desktop_app');local Host=require('desktop_host');local M=require('desktop_model');local Worlds=require('desktop_worlds');local V=require('vessels');local E=require('genome_editor');local G=require('genome')
 local function fixture()
  local s=B.new(20261111);B.collect(s);V.ensure(s);M.ensure(s);Worlds.ensure(s);B.extract(s,1);B.freeze(s,2)
  local o=assert(B.spawn(s,G.copy(require('audit_examples').compact.genome),'UI reference',0));o.worldId='terrarium';B.update(s,1)
  return s
 end
 local function bind(s)
  local prior=Host.context;Host.context={B=B,getState=function() return s end,msg=function() end,classic=function() end};Host.monitors={{id='test',x=0,y=0,w=1920,h=1080,dpi=96}};Host.testing=true
  return function() Host.context=prior;Host.testing=false end
 end
 local function draw(s,page)
  local buttons={};App.page=page or App.page;local canvas=love.graphics.newCanvas(1440,900);love.graphics.push('all');love.graphics.setCanvas({canvas,stencil=true});love.graphics.clear(1,1,1,1)
  local ok,why=xpcall(function() App.draw(s,{register=function(x,y,w,h,fn,label) buttons[#buttons+1]={label=label,fn=fn,x=x,y=y} end}) end,debug.traceback)
  love.graphics.setCanvas();love.graphics.pop();assert(ok,why)
  return buttons,canvas
 end
 local function press(buttons,name) for _,b in ipairs(buttons) do if b.label==name then b.fn();return end end;error('Missing new-UI action '..name) end
 test('New UI defaults to desktop mode and opens every equipment record without classic rendering',function()
  local s=fixture();local cleanup=bind(s);assert(not s.desktop.settings.classicUI);App.openGenome(s.cells[1]);App.preview=false;App.record=1;App.vessel=1;App.source=1
  for _,page in ipairs({'Lab','Cultures','Genome Forge','Assembly','Incubation','Habitats','Records','Research','Cryobank','Behavior','Settings'}) do local buttons=draw(s,page);assert(#buttons>8,page) end
  for _,kind in ipairs({'cells','materials','organisms'}) do App.recordType=kind;App.record=1;draw(s,'Records') end
  local buttons,canvas=draw(s,'Settings');local found=false;for _,b in ipairs(buttons) do if b.label=='Classic interface: OFF' then found=true end;local label=b.label:lower();assert(not label:find('pause') and not label:find('speed') and not label:find('offline catch'),'Time control exposed in Settings') end;assert(found and not s.desktop.settings.classicUI)
  App.page='Genome Forge';E.begin({id=99,name='Audited reference',genome=G.copy(require('audit_examples').compact.genome)});App.name='Edited reference';local _,image=draw(s,'Genome Forge')
  local base=love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or love.filesystem.getSource();local file=assert(io.open(base..'/desktop-forge-preview.png','wb'));file:write(image:newImageData():encode('png'):getString());file:close();cleanup()
 end)
 test('New Cultures UI uses counted dropper samples and has no loose-cell inventory actions',function() local s=fixture();local cleanup=bind(s);App.vessel=1;assert(require('desktop_samples').seed(s,s.vessels[1].id,1));local buttons=draw(s,'Cultures');for _,button in ipairs(buttons) do assert(button.label~='Introduce into container' and button.label~='Collect wild specimens' and button.label~='Restock 6 blank cells / 8') end;press(buttons,'Collect sample');assert(V.count(s.vessels[1])==0 and s.desktop.pipette.sample and s.desktop.pipette.sample.quantity==1);cleanup() end)
 test('Forge previews and archives while physical workshop installation and container incubation conserve cells',function()
  local s=fixture();local cleanup=bind(s);local F=require('physical_cells');F.ensure(s);local station=M.add(s,'workstation','workstation');E.begin({id=99,genome=G.copy(require('audit_examples').compact.genome)});App.name='UI tested strain';App.preview=false
  local buttons=draw(s,'Genome Forge');press(buttons,'Preview body');assert(E.forecast.viable and App.preview);App.preview=false
  local materialCount=#s.materials;local sync=Host.sync;Host.sync=function() end;press(buttons,'Archive genome');assert(#s.materials==materialCount+1 and s.materials[#s.materials].name==App.name);press(buttons,'Use in cell workshop');Host.sync=sync;assert(station.config.genomeId==s.materials[#s.materials].id and #s.cells==0)
  local _,_,input=F.buy(s,'blank');V.add(s,4,true);local output=s.vessels[#s.vessels];local source=M.add(s,'vial',input.id);local dest=M.add(s,'vial',output.id);local D=require('workshop_docking');assert(D.attach(s,station.id,source.id,'input'));assert(D.attach(s,station.id,dest.id,'output'));assert(require('cell_workshop').install(s,station.id));assert(V.count(input)==0 and V.count(output)==1);assert(F.beginDevelopment(s,output.id));assert(#s.eggs==1 and V.count(output)==0 and s.desktop.blankCells==0);B.update(s,s.eggs[1].anatomy.growthModel.duration+1);assert(#s.eggs==0 and #s.organisms==2);cleanup()
 end)
 test('Classic interface can only be enabled through its explicit Settings action',function() local s=fixture();local cleanup=bind(s);local buttons=draw(s,'Settings');assert(not s.desktop.settings.classicUI);press(buttons,'Classic interface: OFF');assert(s.desktop.settings.classicUI==true);cleanup() end)
 test('Genome dosage and regulation survive two-parent inheritance',function() local s=fixture();E.begin(s.cells[1]);E.site=1;E.selected=2;E.operation('duplicate');E.operation('regulate');local g=E.draft;local a=G.gamete(g,G.rng(1),'A',false);local b=G.gamete(g,G.rng(2),'B',false);local child=assert(G.fertilize(a,b));assert(child.chromosomes[2].loci[1].copies==2 and #child.regulation==1 and G.valid(child)) end)
end
