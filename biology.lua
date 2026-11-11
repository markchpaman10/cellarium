local G=require('genome');local H=require('habitat');local A=require('anatomy');local K=require('cultivation');local D=require('development');local P=require('physiology');local R=require('reproduction')
local B={types=K.types,genes={}}
B.colors={{.40,.94,.77},{1,.48,.48},{.69,.56,1},{.95,.77,.42},{1,.36,.53},{.60,.85,.57},{.95,.65,.35}}
for i=1,10 do B.genes[i]=G.loci[i].name end
function B.new(seed) return {version=4,seed=seed or 76123,nextId=1,time=0,accumulator=0,cells={},dishes={},frozen={},materials={},gametes={},organisms={},eggs={},food={},history={},experiments={},lineages={},generation=0,discoveries={},collected=0,habitat=H.new(seed or 76123)} end
function B.rand(s) s.seed=(s.seed*48271)%2147483647;return s.seed/2147483647 end
function B.id(s) local n=s.nextId;s.nextId=n+1;return n end
function B.log(s,t) table.insert(s.history,1,t);if #s.history>100 then table.remove(s.history) end end
function B.cell(s,typ,genome,parent,generation,strain)
 local c=K.cell(B.id(s),typ,genome and (genome.chromosomes and genome or G.legacy(genome)) or G.new(function() return B.rand(s) end),parent,generation,strain)
 s.strains=s.strains or {};if not s.strains[c.strain] then s.strains[c.strain]={id=c.strain,name=c.name,founder=c.id,category=typ} else c.name=s.strains[c.strain].name end;return c
end
function B.renameStrain(s,strain,name)
 s.strains=s.strains or {};s.strains[strain]=s.strains[strain] or {id=strain};s.strains[strain].name=name
 for _,list in ipairs({s.cells,s.frozen}) do for _,c in ipairs(list) do if c.strain==strain then c.name=name end end end
 for _,d in ipairs(s.dishes) do if d.cell.strain==strain then d.cell.name=name end end
end
function B.collect(s) for i=1,7 do s.cells[#s.cells+1]=B.cell(s,i) end;s.collected=s.collected+1;B.log(s,'Collected seven primary cell categories.') end
function B.cultivate(s,index,medium)
 if #s.dishes>=3 then return false,'All dishes are occupied.' end;local c=s.cells[index];if not c or c.viability<.1 or c.replicationCapacity<=0 then return false,'Specimen cannot replicate.' end
 table.remove(s.cells,index);s.dishes[#s.dishes+1]=K.dish(c,medium or 1);return true
end
function B.harvest(s,index)
 local d=s.dishes[index];if not d or d.progress<1 then return false end
 for i=1,d.viable do local g=G.copy(d.cell.genome);G.mutate(g,function() return B.rand(s) end,K.mutationRate(d),'Mitosis');local c=B.cell(s,d.cell.type,g,'Cell '..d.cell.id,d.cell.generation+1,d.cell.strain);c.health=d.health;c.viability=d.health;c.replicationCapacity=d.cell.replicationCapacity-1;c.subtype=d.cell.subtype;s.cells[#s.cells+1]=c end
 d.cell.replicationCapacity=math.max(0,d.cell.replicationCapacity-1);s.cells[#s.cells+1]=d.cell
 s.experiments[#s.experiments+1]={kind='cultivation',input={G.copy(d.cell)},conditions={temperature=d.temperature,medium=d.medium,nutrients=d.nutrients,contamination=d.contamination},yield=d.viable,outcome='Harvested',time=s.time}
 table.remove(s.dishes,index);B.log(s,'Harvested '..d.viable..' viable daughter cells; lineage retained.');return true
end
function B.freeze(s,index) local c=table.remove(s.cells,index);if not c then return false end;c.preservation='frozen';c.preservationQuality=1;s.frozen[#s.frozen+1]=c;return true end
function B.thaw(s,index) local c=table.remove(s.frozen,index);if not c then return false end;c.viability=c.viability*(.96+.04*(c.preservationQuality or 1));c.preservation='living';s.cells[#s.cells+1]=c;return true end
function B.queue(s,g,parents,generation,conditions,record)
 if not G.valid(g) then return false,'Invalid chromosome data.' end
 local e=D.new(B.id(s),g,parents,generation,conditions);e.record=record;s.eggs[#s.eggs+1]=e;return e
end
function B.combine(s,ids,options)
 options=options or {}
 if #ids~=3 then return false,'Select three cells.' end;local donors,seen={},{};for _,id in ipairs(ids) do if seen[id] then return false,'Donors must be distinct specimens.' end;seen[id]=true;for _,c in ipairs(s.cells) do if c.id==id then donors[#donors+1]=c end end end
 if #donors~=3 then return false,'A donor is unavailable.' end
 local genomes,names={},{};for _,c in ipairs(donors) do if c.viability<.1 then return false,'Donor viability too low.' end;genomes[#genomes+1]=c.genome;names[#names+1]=c.id end
 local g,seed=G.fuse(genomes,options);local record={kind='fusion',inputs=G.copy(donors),conditions={nutrition=options.nutrition or 1,temperature=options.temperature or 37,minerals=options.minerals or 1,oxygen=options.oxygen or 1,release=options.release or 'auto',recombination=options.recombination or 'majority',exposure=options.exposure or 0},seed=seed,genome=G.copy(g),outcome='Developing',time=s.time};s.experiments[#s.experiments+1]=record
 B.queue(s,g,table.concat(names,' + '),0,record.conditions,#s.experiments)
 for i=#s.cells,1,-1 do if seen[s.cells[i].id] then table.remove(s.cells,i) end end;B.log(s,'Three-source fusion: 24 chromosome pairs assembled.');return true
end
function B.repeatExperiment(s,index) local r=s.experiments[index];if not r then return false end;if r.kind~='fusion' then return false,'Select a fusion experiment.' end
 for _,c in ipairs(r.inputs) do local n=B.cell(s,c.type,c.genome,'Repeat of '..c.id,c.generation,c.strain);s.cells[#s.cells+1]=n end;B.log(s,'Restored three genetic templates from experiment record.');return true
end
function B.spawn(s,genome,parents,gen,x,y,anatomy)
 local g=genome.chromosomes and genome or G.legacy(genome);local a=anatomy or A.generate(g);if not a.viable then return nil,table.concat(a.failures,'; ') end
 H.ensure(s);local point=H.location(s.habitat,a.caps,(a.development or {}).release,{x=.1+B.rand(s)*.8,y=.15+B.rand(s)*.7});local o=P.new(B.id(s),g,parents,gen,x or point.x,y or point.y,B.rand(s)*6.28,a);s.organisms[#s.organisms+1]=o;s.generation=math.max(s.generation,o.generation)
 s.lineages[o.id]={parents=o.parents,parentIds=G.copy(o.parentIds),generation=o.generation,children={}};local key=a.segments..'/'..a.limbPairs..'/'..math.floor(a.pigment*3);s.discoveries[key]=true;return o
end
function B.extract(s,index) local c=s.cells[index];if not c then return false,'Select a cell.' end;s.materials[#s.materials+1]={id=B.id(s),source='Cell '..c.id,genome=G.copy(c.genome),strain=c.strain,generation=c.generation};return true,'DNA template extracted; source cell retained.' end
function B.precursor(s,index,kind)
 local c=s.cells[index];if not c or c.type~=1 then return false,'Only stem cells can form gamete precursors.' end
 if c.viability<.5 then return false,'Stem cell viability must exceed 50%.' end
 local h=G.gamete(c.genome,function() return B.rand(s) end,'Cell '..c.id,true);h.id=B.id(s);h.kind=kind;h.progress=0;h.stage='Gamete precursor';h.generation=c.generation;h.genomeSource=G.copy(c.genome);s.gametes[#s.gametes+1]=h;return true,'Stem-cell precursor created; maturation takes 8 hours.'
end
function B.fertilize(s,eggId,spermId)
 local egg,sperm,ei,si;for i,h in ipairs(s.gametes) do if h.id==eggId then egg=h;ei=i end;if h.id==spermId then sperm=h;si=i end end
 if not egg or not sperm or egg==sperm or egg.kind~='Egg' or sperm.kind~='Sperm' or egg.progress<1 or sperm.progress<1 then return false,'Select one mature egg and one mature sperm.' end
 local g=G.fertilize(egg,sperm);if not g then return false,'Incompatible chromosome data.' end
 local r={kind='fertilization',inputs={G.copy(egg),G.copy(sperm)},genome=G.copy(g),conditions={nutrition=1,temperature=37},outcome='Developing',time=s.time};s.experiments[#s.experiments+1]=r
 B.queue(s,g,egg.source..' + '..sperm.source,math.max(egg.generation,sperm.generation)+1,r.conditions,#s.experiments)
 table.remove(s.gametes,math.max(ei,si));table.remove(s.gametes,math.min(ei,si));B.log(s,'Fertilization: one haploid set from each source.');return true,'Zygote created.'
end
function B.breed(s,a,b)
 local ok,why=R.compatible(a,b);if not ok then return false,why end
 local g,ids,gen,ancestry,common=R.inherit(a,b,function() return B.rand(s) end);local e=B.queue(s,g,a.id..' + '..b.id,gen);e.birthLocation={x=(a.x+b.x)/2,y=(a.y+b.y)/2};e.parentIds=ids;e.ancestry=ancestry;e.inbreeding=common
 a.energy=a.energy-20;b.energy=b.energy-20;a.breed=0;b.breed=0;B.log(s,'Two-parent breeding: embryo generation '..gen..'.');return true,'Offspring developing in incubation.'
end
local function step(s,dt,environment)
 H.ensure(s);s.time=s.time+dt;for _,c in ipairs(s.cells) do c.age=c.age+dt end;s.habitat.environment=environment or s.habitat.environment
 for _,d in ipairs(s.dishes) do K.update(d,dt) end
 for _,h in ipairs(s.gametes) do h.progress=math.min(1,h.progress+dt/8);h.stage=h.progress>=1 and h.kind or 'Gamete precursor' end
 for i=#s.eggs,1,-1 do local e=s.eggs[i];local viable,failures=D.update(e,dt);if viable~=nil then
  local record=e.record and s.experiments[e.record]
  if viable then local o=B.spawn(s,e.genome,e.parents,e.generation,e.birthLocation and e.birthLocation.x,e.birthLocation and e.birthLocation.y,e.anatomy);o.parentIds=e.parentIds or {};o.ancestry=e.ancestry or {};o.inbreeding=e.inbreeding or 0;s.lineages[o.id].parentIds=G.copy(o.parentIds)
   for _,id in ipairs(o.parentIds) do for _,parent in ipairs(s.organisms) do if parent.id==id then parent.children[#parent.children+1]=o.id;if s.lineages[id] then s.lineages[id].children[#s.lineages[id].children+1]=o.id end end end end
   if record then record.outcome='Viable juvenile';record.organism=o.id;record.anatomy=G.copy(o.anatomy) end;B.log(s,'Viable juvenile '..o.id..' released after tissue differentiation.')
  else if record then record.outcome='Failed';record.failures=failures end;B.log(s,'Development failed: '..table.concat(failures,'; ')) end;table.remove(s.eggs,i)
 end end
 if #s.food<60 and B.rand(s)<dt*.7*s.habitat.foodRate then s.food[#s.food+1]=H.resource(s,function() return B.rand(s) end) end
 local living=0;for _,o in ipairs(s.organisms) do if o.alive then living=living+1 end;local was=o.alive;P.update(o,s,dt,s.habitat.environment);if was and not o.alive then B.log(s,o.name..' died: '..o.deathCause..'.');s.food[#s.food+1]={x=o.x,y=o.y,kind='tissue',amount=1} end end
 if living+#s.eggs<30 then for _,a in ipairs(s.organisms) do if a.alive and a.breed>60 and a.maturity>=1 and a.energy>65 then for _,b in ipairs(s.organisms) do if b~=a and b.breed>60 and (a.x-b.x)^2+(a.y-b.y)^2<.008 and R.compatible(a,b) and B.rand(s)<dt*.03*a.caps.fitness then B.breed(s,a,b);return end end end end end
end
function B.update(s,dt,environment) s.accumulator=(s.accumulator or 0)+dt;while s.accumulator>=.05-1e-9 do step(s,.05,environment);s.accumulator=s.accumulator-.05 end end
return B
