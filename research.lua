local G=require('genome');local EG=require('environment_genes');local Units=require('units');local DG=require('development_genes');local A=require('anatomy');local R=require('rendering');local K=require('cultivation')
local U={genomePage=1,operationIndex=1,view='Genome',source='cells',index=1,page=1,layer='External',component=1,locus=1,compare=nil,parentA=nil,parentB=nil,egg=nil,sperm=nil,experiment=1,naming=false,nameBuffer=''}
local sources={'cells','organisms','materials','frozen'}
local function count(t) return #t end
function U.openOrganism(s,index) U.view='Anatomy';U.source='organisms';U.index=index;U.component=1 end
function U.mousepressed(x,y) if U.view~='Anatomy' then return end;for i=#(U.hits or {}),1,-1 do local r=U.hits[i];if x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h then U.component=r.id;return end end end
function U.textinput(t) if U.naming then U.nameBuffer=(U.nameBuffer..t):sub(1,28) end end
function U.keypressed(k,s)
 if not U.naming then return false end
 if k=='escape' then U.naming=false elseif k=='backspace' then U.nameBuffer=U.nameBuffer:sub(1,-2) elseif k=='return' then local v=(s[U.source] or {})[U.index];if v and #U.nameBuffer>0 then if v.strain and v.type then require('biology').renameStrain(s,v.strain,U.nameBuffer) else v.name=U.nameBuffer end end;U.naming=false end;return true
end
function U.draw(s,c)
 local text,button,panel,col,msg=c.text,c.button,c.panel,c.col,c.msg;local C=c.C;local B=c.B
 for i,name in ipairs({'Genome','Anatomy','Development','Physiology','Engineering','Experiments','Cultures','Environment'}) do button(name,314+(i-1)*137,202,127,35,function() U.view=name;if name=='Anatomy' then U.source='organisms';U.index=1;U.component=1 end end,U.view==name) end
 panel(32,202,260,650);text('RESEARCH COLLECTION',51,222,13,C.mint)
 for i,key in ipairs(sources) do button(({cells='Cells',organisms='Creatures',materials='DNA',frozen='Frozen'})[key],49+(i-1)%2*115,256+math.floor((i-1)/2)*37,108,30,function() U.source=key;U.index=1;U.page=1 end,U.source==key) end
 local list=s[U.source] or {};local start=math.floor((U.index-1)/12)*12+1
 for row=0,math.min(11,#list-start) do local i=start+row;local v=list[i];local label=v.name or (U.source=='materials' and 'DNA '..v.id or B.types[v.type]..' '..v.id)
  button(label:sub(1,25),49,349+row*31,226,27,function() U.index=i;U.component=1 end,U.index==i)
 end
 button('<',49,743,55,28,function() U.index=math.max(1,start-12) end);button('>',220,743,55,28,function() U.index=start+12<=#list and start+12 or 1 end)
 text(#list..' records',120,750,12,C.muted);text('Shared simulation.\nInspect only as deeply as you like.',51,796,12,C.muted)
 local v=list[U.index];panel(314,251,1094,601)
 local function result(ok,why) msg(why or (ok and 'Done.' or 'Action unavailable.')) end
 if U.view=='Genome' then
  if not v then text('Select a specimen, creature or extracted DNA.',340,280,20,C.muted);return end
  local g=v.genome;local e=G.express(g);local marker,bits=G.marker(g);local site=U.genomePage
  button(({'Primary loci >','Development loci >','Ecology loci >'})[site],938,269,226,34,function() U.genomePage=U.genomePage%3+1 end)
  text(v.name or 'DNA template '..v.id,340,271,24);text('24 chromosome pairs / 144 alleles  |  Marker '..marker..' / '..string.format('%04X',bits),340,310,14,C.mint)
  button('Pin comparison',1180,269,202,34,function() U.compare=G.copy(g);msg('Genome pinned. Differences now appear in amber.') end)
  for i,definition in ipairs(G.loci) do local d=site==1 and definition or {name=(site==2 and DG.names or EG.names)[i],mode='additive'};local x=340+math.floor((i-1)/12)*525;local y=353+(i-1)%12*32;local l=g.chromosomes[i].loci[site];local expression=site==1 and e[i] or (l.a+l.b)/6;local difference=U.compare and (l.a~=U.compare.chromosomes[i].loci[site].a or l.b~=U.compare.chromosomes[i].loci[site].b)
   button(string.format('%02d',i)..'  '..d.name,x,y,175,27,function() U.locus=i end,U.locus==i)
   text(l.a..' | '..l.b,x+192,y+5,14,difference and {.98,.73,.35} or C.mint)
   text(d.mode,x+250,y+6,11,C.muted);col(C.line);love.graphics.rectangle('fill',x+355,y+11,105,5);col(difference and {.98,.73,.35} or C.mint);love.graphics.rectangle('fill',x+355,y+11,105*expression,5);text(math.floor(expression*100)..'%',x+470,y+5,11,C.muted)
  end
  local l=g.chromosomes[U.locus].loci[site];text((site==1 and G.loci[U.locus].name or (site==2 and DG.names or EG.names)[U.locus])..': A from '..tostring(l.sourceA)..' | B from '..tostring(l.sourceB),340,752,13,C.muted)
  text('Mutations '..#g.mutations..'   /   Homozygosity '..math.floor(e.homozygosity*100)..'%   /   Reproductive fitness '..math.floor(e.fitness*100)..'%',340,780,13,C.mint)
  if U.compare then text('Similarity to pinned genome: '..math.floor(G.similarity(g,U.compare)*100)..'%  |  amber = changed alleles',340,811,13,C.muted) else text('The eight-base marker describes only the first four loci, never the entire genome.',340,811,13,C.muted) end
 elseif U.view=='Anatomy' then
  if not v or not v.anatomy then text('Choose Creatures, then select an organism.',340,280,20,C.muted);return end
  local a=v.anatomy;local caps=A.capabilities(a,v.genome)
  text(v.name..' / '..(v.lifeStage or 'Juvenile'),340,271,24);text(a.version==3 and (#a.regions..' grown regions / '..a.appendageCount..' extensions / '..a.symmetry..' / '..caps.locomotion) or (a.segments..' skeletal segments / legacy body'),340,310,13,C.muted)
  for i,layer in ipairs(R.layers) do button(layer,340+(i-1)*80,345,73,29,function() U.layer=layer;U.component=1 end,U.layer==layer) end
  local filtered={};for _,part in ipairs(a.components) do if U.layer=='External' or U.layer=='Skin' and part.type=='Skin' or U.layer=='Muscle' and part.type=='Muscle' or U.layer=='Fat' and part.type=='Fat' or U.layer=='Skeleton' and (part.type=='Bone' or part.type=='Support' or part.type=='Carapace') or U.layer=='Organs' and (part.type=='Heart' or part.type=='Lung' or part.type=='Brain' or part.type=='Stomach') or U.layer=='Organs' and (part.type=='Gill' or part.type=='Airway' or part.type=='Mouth') or U.layer=='Defenses' and part.type=='Projection' or U.layer=='Nervous' and part.type=='Brain' then filtered[#filtered+1]=part end end
  local matches=false;for _,p in ipairs(filtered) do if p.id==U.component then matches=true end end;if not matches and filtered[1] then U.component=filtered[1].id end
  local renderScale=R.fitScale(a,590,305,3.5);U.hits={};for _,p in ipairs(filtered) do local rx,ry=math.max(3,p.rx or 8)*renderScale,math.max(3,p.ry or 8)*renderScale;U.hits[#U.hits+1]={x=650+p.x*renderScale-rx,y=535+p.y*renderScale-ry,w=rx*2,h=ry*2,id=p.id} end
  R.draw(v,650,535,renderScale,s.time,U.layer,U.component)
  text(string.format('Mass %.1f  /  Effective force %.2f  /  Speed %.3f',caps.mass,caps.force,caps.speed),340,725,14,C.mint)
  text(string.format('Supply %.0f%%  /  Support %.0f%%  /  Coordination %.0f%%',caps.supply*100,caps.support*100,caps.coordination*100),340,754,13,C.muted)
  text(a.generator=='legacy-fallback' and 'Legacy fallback anatomy retained; genetic information is unchanged.' or 'Continuous tissue envelope follows the grown graph; no rectangular body tiles.',340,809,12,C.muted)
  panel(997,390,388,394)

  local current=1;for i,p in ipairs(filtered) do if p.id==U.component then current=i end end
  button('< structure',1014,406,160,30,function() local p=filtered[current-1] or filtered[#filtered];if p then U.component=p.id end end)
  button('structure >',1190,406,178,30,function() local p=filtered[current+1] or filtered[1];if p then U.component=p.id end end)
  local p=a.components[U.component];if p then text(p.type..' / component '..p.id,1014,457,18,C.mint);local fields=p.type=='Skin' and {'covering','parent','condition','thickness','hardness','flexibility','mineralization','segmentation','armor','regeneration','mass'} or p.type=='Projection' and {'role','parent','length','width','sharpness','hardness','strength','attachmentStrength','mass','condition','effectiveness','regeneration'} or {'parent','region','mass','condition','length','thickness','strength','capacity','efficiency','flexibility','rigidity','acuity','origin','insertion'};local yy=496;for _,key in ipairs(fields) do if p[key]~=nil then text(key..'   '..(type(p[key])=='number' and string.format('%.2f',p[key]) or tostring(p[key])),1014,yy,13,C.muted);yy=yy+21 end end end
  button('Rename',1185,269,190,34,function() U.naming=true;U.nameBuffer=v.name end)
 elseif U.view=='Development' then
  if not v or not v.anatomy then text('Select a creature to inspect its actual developmental history.',340,280,20,C.muted);return end
  local a=v.anatomy
  text(v.name..' / developmental construction',340,271,24)
  if a.version~=3 then text('Preserved legacy body. Its offspring use the new developmental loci.',340,325,15,C.muted);return end
  text(a.symmetry..' / '..a.caps.locomotion..' / '..a.exchangeMethod..' exchange / '..#a.regions..' regions of budget '..a.budget,340,310,14,C.mint)
  text('GENETIC INSTRUCTIONS',340,361,12,C.mint)
  for i,name in ipairs(DG.names) do local x=340+math.floor((i-1)/12)*255;local y=400+(i-1)%12*26;text(name,x,y,11,C.muted);text(string.format('%.2f',a.parameters[i]),x+191,y,12,C.mint) end
  text('RECORDED GROWTH OPERATIONS',885,361,12,C.mint)
  U.operationIndex=math.max(1,math.min(U.operationIndex,#a.operations-12))
  for row=0,12 do local op=a.operations[U.operationIndex+row];if op then text(op.operation..' R'..tostring(op.region)..' < '..tostring(op.parent or 'embryo'),885,400+row*25,12,C.mint) end end
  button('< earlier',885,744,220,30,function() U.operationIndex=math.max(1,U.operationIndex-13) end);button('later >',1120,744,235,30,function() U.operationIndex=math.min(#a.operations-12,U.operationIndex+13) end)
  text(#a.operations..' operations / '..#a.structures..' support elements / '..#a.joints..' joints / '..#a.organs..' organs',340,762,13,C.muted)
  text('Limitations: '..(#(a.limitations or {})>0 and table.concat(a.limitations,'; ') or 'No critical limitations detected'),340,805,12,C.muted)
 elseif U.view=='Physiology' then
  if not v or not v.anatomy then text('Select a creature to inspect its living condition.',340,280,20,C.muted);return end
  local caps=v.caps;local e=v.traits
  text(v.name..' / living systems',340,271,24)
  text('Parents '..v.parents..' / G'..v.generation..' / I'..v.inbreeding..' / '..#v.children..' offspring',340,310,14,C.mint)
  local values={{'Health',string.format('%.1f / %.1f',v.health*caps.maxHealth/100,caps.maxHealth)},{'Energy',string.format('%.0f%%',v.energy)},{'Stamina',string.format('%.0f%%',v.stamina)},{'Hunger',string.format('%.0f%%',(1-v.energy/100)*100)},{'Thirst',string.format('%.0f%%',100-v.hydration)},{'Immunity',string.format('%.0f%%',caps.immunity*100)},{'Sickness',string.format('%.1f%%',v.sickness*100)},{'Fat reserves',string.format('%.2f mass units',v.fatMass)},{'Muscle mass',string.format('%.2f mass units',v.muscleMass)},{'Body growth',string.format('%.0f%%',v.bodyCondition*100)},{'Mental condition',string.format('%.0f%%',v.mentalCondition*100)},{'Metabolic demand',string.format('%.2f energy / h',caps.metabolicDemand)},{'Growth rate',string.format('%.2f%% / h',caps.growthRate*100)},{'Maturity',string.format('%.0f%%',v.maturity*100)},{'Expected lifespan',string.format('%.0f h',caps.lifespan)},{'Reproductive fitness',string.format('%.0f%%',caps.fitness*100)},{'Salt / heat tolerance',string.format('%.0f%%',caps.tolerance*100)},{'Sensory range',string.format('%.3f habitat units',caps.perception)},{'Stride efficiency',string.format('%.2f',caps.stride*caps.coordination)},{'Current activity',v.behavior}}
  for i,item in ipairs(values) do local x=340+math.floor((i-1)/10)*520;local y=360+(i-1)%10*34;text(item[1],x,y,13,C.muted);text(item[2],x+211,y,14,C.mint) end
  text('RECENT INHERITED MUTATIONS',340,720,12,C.mint)
  for i=math.max(1,#v.genome.mutations-2),#v.genome.mutations do local m=v.genome.mutations[i];local y=750+(i-math.max(1,#v.genome.mutations-2))*26;text((m.site==2 and 'D' or 'L')..m.locus..' '..m.from..' > '..m.to..' / '..m.stage..' / '..(m.effect or 'Inherited variation'),340,y,12,C.muted) end
  if #v.genome.mutations==0 then text('No recorded inherited mutations.',340,754,13,C.muted) end
 elseif U.view=='Environment' then
  if not v or not v.anatomy then text('Select a creature to examine its environmental capabilities.',340,280,20,C.muted);return end
  local caps=A.capabilities(v.anatomy,v.genome);text(v.name..' / ecological physiology',340,271,24)
  text('Capabilities overlap. Anatomy determines compatibility; there are no fixed land/water/air species.',340,310,13,C.muted)
  for i,kind in ipairs({'land','freshwater','saltwater','flight'}) do local x=340+(i-1)*258;local value=caps.compatibility[kind];text(kind:upper(),x,367,13,C.muted);text(math.floor(value*100)..'%',x,397,32,C.mint) end
  local rows={{'Air exchange',caps.airRespiration},{'Aquatic exchange',caps.aquaticRespiration},{'Oxygen demand',caps.oxygenDemand},{'Oxygen reserve',(v.oxygen or 1)*100},{'Buoyancy',caps.buoyancy},{'Moisture retention',caps.moistureRetention},{'Salinity tolerance',caps.salinityTolerance},{'Metabolic upkeep',caps.metabolicDemand},{'Lift-producing area',caps.flight.surfaceArea},{'Lift / mass ratio',caps.flight.liftRatio},{'Control',caps.flight.control},{'Propulsion / load',caps.flight.propulsion},{'Plant digestion',caps.diet.plant},{'Dissolved nutrients',caps.diet.dissolved},{'Organic debris',caps.diet.debris},{'Animal tissue',caps.diet.tissue}}
  for i,item in ipairs(rows) do local x=340+math.floor((i-1)/8)*520;local y=475+(i-1)%8*31;text(item[1],x,y,13,C.muted);text(string.format('%.2f',item[2]),x+230,y,14,C.mint) end
  text('Movement: '..(v.locomotion or caps.locomotion)..' / glide '..tostring(caps.flight.glide)..' / powered flight '..tostring(caps.flight.powered),340,752,14,C.mint)
  text('Current habitat: '..(v.environment or 'land')..' / biological projections '..#(v.anatomy.projections or {})..' / no combat simulation',340,792,13,C.muted)
 elseif U.view=='Engineering' then
  text('A closer hand in inheritance.',340,271,24);text('Optional tools. Three-cell fusion remains the quickest path to life.',340,309,14,C.muted)
  local cell=U.source=='cells' and v
  button('Extract DNA template',340,352,247,38,function() result(B.extract(s,U.index)) end,false,not cell)
  button('Stem > egg precursor',603,352,247,38,function() result(B.precursor(s,U.index,'Egg')) end,false,not cell or cell.type~=1)
  button('Stem > sperm precursor',866,352,247,38,function() result(B.precursor(s,U.index,'Sperm')) end,false,not cell or cell.type~=1)
  if cell then text('Source '..cell.id..' | '..K.functions[cell.type]..' | viability '..math.floor(cell.viability*100)..'%',340,407,13,C.mint)
   button('Name strain',1140,352,235,38,function() U.naming=true;U.nameBuffer=cell.name end)
   if cell.type==4 then button('Specialize digestive tissue',340,435,247,31,function() cell.subtype='Digestive';cell.differentiation='digestive epithelium';msg('Epithelial specimen specialized for digestion; genome unchanged.') end) end
  elseif U.source=='materials' and v then button('Recover stem-cell template',340,435,300,31,function() s.cells[#s.cells+1]=B.cell(s,1,v.genome,v.source,v.generation,v.strain);msg('Stem cell generated from archived template.') end) end
  text('GAMETE BANK / 24 haploid chromosome contributions',340,485,13,C.mint)
  for i=1,math.min(4,#s.gametes) do local h=s.gametes[i];local yy=514+(i-1)*33;local chosen=h.id==U.egg or h.id==U.sperm
   button(h.kind..' '..h.id..' / '..h.source..' / '..math.floor(h.progress*100)..'%',340,yy,480,28,function() if h.kind=='Egg' then U.egg=h.id else U.sperm=h.id end end,chosen)
  end
  if #s.gametes>4 then button('Rotate bank',680,650,140,27,function() table.insert(s.gametes,table.remove(s.gametes,1)) end) end
  button('Fertilize selected egg + sperm',340,688,480,38,function() result(B.fertilize(s,U.egg,U.sperm)) end)
  text('Each parent contributes one haploid set. Primary, developmental\nand ecological loci segregate and can recombine during meiosis.',340,747,12,C.muted)
  text('SELECTIVE BREEDING',873,485,13,C.mint)
  button('Set selected creature as A',873,519,492,33,function() if U.source=='organisms' and v then U.parentA=v.id;msg('First parent selected.') else msg('Choose a creature in the collection.') end end)
  button('Set selected creature as B',873,562,492,33,function() if U.source=='organisms' and v then U.parentB=v.id;msg('Second parent selected.') else msg('Choose a creature in the collection.') end end)
  text('Parents: '..tostring(U.parentA or '?')..' + '..tostring(U.parentB or '?'),873,615,16,C.mint)
  button('Breed selected parents',873,654,492,38,function() local a,b;for _,o in ipairs(s.organisms) do if o.id==U.parentA then a=o end;if o.id==U.parentB then b=o end end;if a and b then result(B.breed(s,a,b)) else msg('Choose both parents first.') end end)
  if U.source=='organisms' and v then text('Children: '..(#v.children>0 and table.concat(v.children,', ') or 'none')..'\nGeneration '..v.generation..' | Shared-ancestry I'..v.inbreeding..'\nFertility follows recessive load, not an arbitrary I10 cutoff.',873,730,12,C.muted) end
 elseif U.view=='Experiments' then
  text('Experiments with a memory.',340,271,24);text('Replaying fusion templates preserves the same alleles and tie-break seed.',340,310,14,C.muted)
  local total=#s.experiments;U.experiment=math.max(1,math.min(U.experiment,total));local r=s.experiments[U.experiment]
  button('< previous',340,350,180,32,function() U.experiment=math.max(1,U.experiment-1) end);button('next >',532,350,180,32,function() U.experiment=math.min(total,U.experiment+1) end)
  if r then
   text('RECORD '..U.experiment..' / '..total..'   '..r.kind:upper(),340,415,18,C.mint);text('Outcome: '..r.outcome,340,460,18);local yy=503
   for key,value in pairs(r.conditions or {}) do text(key..': '..(key=='temperature' and Units.temperature(value) or type(value)=='number' and string.format('%.3f',value) or tostring(value)),340,yy,14,C.muted);yy=yy+28 end
   if r.genome then text('Genome marker '..G.marker(r.genome)..' / hash '..G.hash(r.genome),810,415,14,C.mint);text('Mutations '..#r.genome.mutations,810,451,14,C.muted) end
   if r.failures then text(table.concat(r.failures,'\n'),810,500,14,{1,.5,.45}) end
   if r.inputs then for i,input in ipairs(r.inputs) do text('Input '..i..': '..(input.name or input.source or input.id),810,540+(i-1)*28,14,C.muted) end end
   button('Restore three fusion templates',340,732,380,40,function() result(B.repeatExperiment(s,U.experiment)) end,false,r.kind~='fusion')
  else text('Cultivate, combine or fertilize to create a structured record.',340,440,18,C.muted) end
 elseif U.view=='Cultures' then
  text('A living environment.',340,271,24);text('Defaults are safe. Temperature, waste and contamination affect yield and mutation.',340,310,13,C.muted)
  for i=1,3 do local d=s.dishes[i];local x=340+(i-1)*348;panel(x,359,329,413);text('DISH '..i,x+17,378,16,C.mint)
   if d then
    text(d.cell.name,x+17,413,18);text(string.format('Temperature %.0f °F\nNutrients %.0f%% / energy %.0f%%\nWaste %.0f%% / contamination %.1f%%\nHealth %.0f%% / population %.1f\nReplication remaining %d\nMutation rate %.2f%% / allele',Units.f(d.temperature),d.nutrients*100,d.energy*100,d.waste*100,d.contamination*100,d.health*100,d.population,d.cell.replicationCapacity,K.mutationRate(d)*100),x+17,455,13,C.muted)
    button('- 4 °F',x+17,610,135,30,function() d.temperature=math.max(15,d.temperature-4/1.8) end);button('+ 4 °F',x+166,610,145,30,function() d.temperature=math.min(60,d.temperature+4/1.8) end)
    button('Refresh sterile medium',x+17,654,294,34,function() d.nutrients=1;d.energy=1;d.waste=0;d.contamination=0;d.sterility=1;msg('Medium refreshed; culture retained.') end)
    button(d.failed and 'Discard failed culture' or 'Unseal / contamination test',x+17,705,294,32,function() if d.failed then table.remove(s.dishes,i) else d.sterility=d.sterility==1 and 0 or 1;msg(d.sterility==0 and 'Dish unsealed. Contamination accumulates over time.' or 'Dish resealed.') end end)
   else text('Seed a cell in Cultivation.\nThe culture appears here\nwith safe default conditions.',x+17,455,14,C.muted) end
  end
 end
 if U.naming then panel(480,388,510,150);text('Enter a name, then press Enter. Esc cancels.',500,410,14,C.mint);text(U.nameBuffer..'_',500,459,24) end
end
return U
