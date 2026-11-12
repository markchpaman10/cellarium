local G=require('genome');local A=require('anatomy');local L={}
local function uid(s) local id=s.nextId;s.nextId=id+1;return id end
local function random(s) s.seed=s.seed*48271%2147483647;return s.seed/2147483647 end
function L.ensure(s)
 s.lab=s.lab or {version=1,credits=120,blankCells=8,vials={},drafts={},archives={},installations={},events={}};return s.lab
end
function L.sequence(g)
 local bases={'A','C','G','T'};local sequence={};for _,c in ipairs(g.chromosomes) do for _,l in ipairs(c.loci) do sequence[#sequence+1]=bases[l.a+1];sequence[#sequence+1]=bases[l.b+1] end end;return table.concat(sequence)
end
function L.buyVial(s,free)
 local lab=L.ensure(s);if not free and lab.credits<10 then return nil,'A DNA vial costs 10 lab credits.' end
 local seed=s.seed;local g=G.new(function() return random(s) end);local vial={id=uid(s),name='DNA vial '..#lab.vials+1,genome=g,seed=seed,sequence=L.sequence(g),progress=0,sequenced=false,assay=false,source='Synthetic sequence supplier'}
 lab.vials[#lab.vials+1]=vial;if not free then lab.credits=lab.credits-10 end;return vial
end
function L.starter(s)
 local lab=L.ensure(s);if lab.started then return end;lab.started=true
 for i=1,3 do L.buyVial(s,true) end
end
function L.draft(s,ids)
 local lab=L.ensure(s);local sources,seen={},{};for _,id in ipairs(ids) do if not seen[id] then for _,v in ipairs(lab.vials) do if v.id==id then sources[#sources+1]=v;seen[id]=true end end end end
 if #sources==0 then return nil,'Select at least one DNA vial.' end
 local g=G.copy(sources[1].genome);g.regulation={};g.lineage={};g.mutations={}
 for _,v in ipairs(sources) do g.lineage[#g.lineage+1]='DNA vial '..v.id end
 for i,c in ipairs(g.chromosomes) do for site,l in ipairs(c.loci) do for sideIndex,side in ipairs({'a','b'}) do local source=sources[1+((i-1)*6+(site-1)*2+sideIndex-1)%#sources];l[side]=source.genome.chromosomes[i].loci[site][side];l[side=='a' and 'sourceA' or 'sourceB']='DNA vial '..source.id end end end
 local draft={id=uid(s),name='Engineered strain '..#lab.drafts+1,genome=g,sources=G.copy(ids),history={{action='Constructed',sources=#sources,time=s.time}},revision=1};lab.drafts[#lab.drafts+1]=draft;return draft
end
function L.edit(s,draft,action,chromosome,site,vial)
 if not draft or not draft.genome.chromosomes[chromosome] or not draft.genome.chromosomes[chromosome].loci[site] then return false,'Select a valid genome locus.' end
 local l=draft.genome.chromosomes[chromosome].loci[site]
 if action=='splice' then if not vial then return false,'Select a donor DNA vial.' end;local source=vial.genome.chromosomes[chromosome].loci[site];l.a=source.a;l.b=source.b;l.copies=source.copies or 1;l.deleted=false;l.sourceA='Vial '..vial.id;l.sourceB=l.sourceA
 elseif action=='duplicate' then l.copies=math.min(6,(l.copies or 1)+1);l.deleted=false
 elseif action=='delete' then l.copies=0;l.deleted=true
 elseif action=='restore' then l.copies=1;l.deleted=false
 elseif action=='mutate' then local from=l.a;l.a=(l.a+1)%4;draft.genome.mutations[#draft.genome.mutations+1]={locus=chromosome,site=site,side='a',from=from,to=l.a,stage='Engineering',effect='Locus allele substitution'}
 elseif action=='regulate' then local regs=draft.genome.regulation or {};draft.genome.regulation=regs;local found;for i,r in ipairs(regs) do if r.targetChromosome==chromosome and r.targetSite==site then found=i;break end end
  if found then if regs[found].mode=='activate' then regs[found].mode='suppress' else table.remove(regs,found) end else regs[#regs+1]={sourceChromosome=12,sourceSite=2,targetChromosome=chromosome,targetSite=site,mode='activate',gain=.5} end
 else return false,'Unknown engineering operation.' end
 draft.revision=draft.revision+1;draft.history[#draft.history+1]={action=action,chromosome=chromosome,site=site,time=s.time};return true,'Genome edited. Development forecast updated.'
end
function L.archive(s,draft)
 if not draft then return false,'Select a draft.' end;local lab=L.ensure(s);lab.archives[#lab.archives+1]=G.copy(draft);return true,'Named genome archived with its engineering history.'
end
function L.restore(s,index)
 local lab=L.ensure(s);if not lab.archives[index] then return nil end;local d=G.copy(lab.archives[index]);d.id=uid(s);d.name=d.name..' / restored';lab.drafts[#lab.drafts+1]=d;return d
end
function L.install(s,draft,B,batch)
 local lab=L.ensure(s);local count=batch and 6 or 1;if not draft or not G.valid(draft.genome) then return false,'A valid assembled genome is required.' end
 if lab.blankCells<count then return false,'Not enough blank developmental cells. Replenish the blank-cell stock.' end
 if batch then
  for i=1,count do local cell=B.cell(s,1,draft.genome,'Engineered strain '..draft.id,0,draft.id);cell.name=draft.name;s.cells[#s.cells+1]=cell end
  lab.blankCells=lab.blankCells-count;lab.installations[#lab.installations+1]={draft=draft.id,batch=true,population=count,genome=G.copy(draft.genome),time=s.time};return true,'Six engineered stem cells are ready for cultivation.'
 end
 local record={kind='synthetic installation',inputs={{source=draft.name,id=draft.id}},genome=G.copy(draft.genome),conditions={nutrition=1,temperature=37,minerals=1,oxygen=1,release='auto'},outcome='Genome activation',time=s.time,engineeringHistory=G.copy(draft.history)};s.experiments[#s.experiments+1]=record
 local embryo,why=B.queue(s,draft.genome,'Engineered '..draft.name,0,record.conditions,#s.experiments);if not embryo then return false,why end;embryo.synthetic=true;embryo.population=1;lab.blankCells=lab.blankCells-1;lab.installations[#lab.installations+1]={draft=draft.id,batch=false,embryo=embryo.id,time=s.time};return true,'Genome installed into a blank cell. Embryogenesis has begun.'
end
function L.restock(s)
 local lab=L.ensure(s);if lab.credits<8 then return false,'Blank-cell stock costs 8 credits.' end;lab.credits=lab.credits-8;lab.blankCells=lab.blankCells+6;return true,'Six blank developmental cells acquired.'
end
function L.update(s,dt)
 local lab=L.ensure(s);for _,v in ipairs(lab.vials) do if v.assay and not v.sequenced then v.progress=math.min(1,v.progress+dt/6);if v.progress>=1 then v.sequenced=true;v.assay=false;v.findings={bodySymmetry=G.express(v.genome).development.symmetry,sequenceLength=#v.sequence,marker=G.marker(v.genome)} end end end
end
return L
