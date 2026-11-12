local G=require('genome')
local A=require('anatomy')
local DG=require('development_genes')
local EG=require('environment_genes')
local E={draft=nil,origin=nil,selected=1,site=2,history={},forecast=nil,forecastHash=nil}
local function names(site) return site==1 and G.loci or site==2 and DG.names or EG.names end
local function title(site,i)
 local n=names(site)[i];return type(n)=='table' and n.name or n
end
function E.begin(source)
 if not source or not source.genome then return false end
 E.draft=G.copy(source.genome);E.origin=source.id;E.selected=1;E.site=2;E.history={};E.forecast=nil;E.forecastHash=nil
 return true
end
function E.change(side,delta)
 if not E.draft then return false end
 local locus=E.draft.chromosomes[E.selected].loci[E.site]
 local old=locus[side];local new=math.max(0,math.min(3,old+delta))
 if new==old then return false end
 E.history[#E.history+1]={chromosome=E.selected,site=E.site,side=side,old=old,new=new,before=G.copy(locus)}
 locus[side]=new;locus[side=='a' and 'sourceA' or 'sourceB']='Direct laboratory edit'
 E.forecast=nil;E.forecastHash=nil
 return true
end
function E.undo()
 local h=table.remove(E.history);if not h then return false end
 if h.genomeBefore then E.draft=h.genomeBefore elseif h.before then E.draft.chromosomes[h.chromosome].loci[h.site]=h.before else local l=E.draft.chromosomes[h.chromosome].loci[h.site];l[h.side]=h.old end
 E.forecast=nil;E.forecastHash=nil;return true
end
function E.commit(s,B)
 if not E.draft or not G.valid(E.draft) then return false,'Invalid genome.' end
 local g=G.copy(E.draft)
 g.mutations=g.mutations or {}
 for _,h in ipairs(E.history) do
  if h.side then g.mutations[#g.mutations+1]={locus=h.chromosome,site=h.site,side=h.side,from=h.old,to=h.new,stage='Direct genome editing',effect='Targeted allele modification'} end
 end
 s.materials=s.materials or {}
 local id=B.id(s)
 s.materials[#s.materials+1]={id=id,name='Engineered DNA '..id,source='Genome Editor',genome=g,generation=0,engineeringHistory=G.copy(E.history)}
 return true,'Engineered DNA '..id..' saved. Research > Engineering can recover a stem cell from this DNA.'
end
function E.operation(action,donor)
 if not E.draft then return false,'Open a genome draft first.' end
 local before=G.copy(E.draft);local l=E.draft.chromosomes[E.selected].loci[E.site]
 if action=='duplicate' then l.copies=math.min(6,(l.copies or 1)+1);l.deleted=false
 elseif action=='delete' then l.copies=0;l.deleted=true
 elseif action=='restore' then l.copies=1;l.deleted=false
 elseif action=='splice' then if not donor then return false,'Select archived DNA as splice donor.' end;E.draft.chromosomes[E.selected].loci[E.site]=G.copy(donor.genome.chromosomes[E.selected].loci[E.site])
 elseif action=='regulate' then E.draft.regulation=E.draft.regulation or {};local found;for i,r in ipairs(E.draft.regulation) do if r.targetChromosome==E.selected and r.targetSite==E.site then found=i end end;if found then local r=E.draft.regulation[found];if r.mode=='activate' then r.mode='suppress' else table.remove(E.draft.regulation,found) end else E.draft.regulation[#E.draft.regulation+1]={sourceChromosome=12,sourceSite=2,targetChromosome=E.selected,targetSite=E.site,mode='activate',gain=.5} end
 else return false,'Unknown edit operation.' end
 E.history[#E.history+1]={chromosome=E.selected,site=E.site,action=action,genomeBefore=before};E.forecast=nil;return true,'Draft '..action..' applied. Preview to inspect biological consequences.'
end
function E.export()
 if not E.draft then return false,'Open a draft first.' end
 local name='engineered-genome-'..os.time()..'.lua';local ok,why=love.filesystem.write(name,'return '..require('persistence').encode(E.draft));return ok,ok and ('Exported to '..love.filesystem.getSaveDirectory()..'/'..name) or why
end
function E.incubate(s,B)
 if not E.draft or not G.valid(E.draft) then return false,'Open a valid genome draft first.' end
 if s.desktop then s.desktop.blankCells=s.desktop.blankCells or 6;if s.desktop.blankCells<1 then return false,'Restock blank developmental cells at the workstation.' end end
 local g=G.copy(E.draft);g.mutations=g.mutations or {};for _,h in ipairs(E.history) do if h.side then g.mutations[#g.mutations+1]={locus=h.chromosome,site=h.site,side=h.side,from=h.old,to=h.new,stage='Direct genome editing',effect='Targeted allele modification'} end end
 local record={kind='genome installation',inputs={{source='Edited draft',id=E.origin}},genome=G.copy(g),conditions={nutrition=1,minerals=1,oxygen=1,temperature=37,release='auto'},outcome='Developing',time=s.time,engineeringHistory=G.copy(E.history)}
 local embryo,why=B.queue(s,g,'Direct genome engineering',0,record.conditions,#s.experiments+1)
 if not embryo then return false,why end
 s.experiments[#s.experiments+1]=record;if s.desktop then s.desktop.blankCells=s.desktop.blankCells-1 end
 return true,'Exact genome installed into one developmental cell; incubation started.'
end
function E.draw(s,c)
 local text,button,msg,C=c.text,c.button,c.msg,c.C
 if not E.draft then text('Select a source in Research > Genome and choose Edit copy.',340,280,19,C.muted);return end
 text('DIRECT GENOME EDITOR / draft from specimen '..tostring(E.origin),340,271,20)
 text('COPY editing / dosage '..(E.draft.chromosomes[E.selected].loci[E.site].copies or 1)..' / D12 regulator cycles activate, suppress, off. Splice donor: '..tostring((s.materials[E.donor or 1] or {}).name or 'none'),340,306,12,C.muted)
 local pages={'Primary','Development','Ecology'}
 for j,name in ipairs(pages) do button(name,340+(j-1)*155,337,145,30,function() E.site=j end,E.site==j) end
 for i=1,24 do
  local x=340+math.floor((i-1)/12)*524;local y=385+((i-1)%12)*29
  local l=E.draft.chromosomes[i].loci[E.site]
  button(string.format('%02d',i)..' '..tostring(title(E.site,i)):sub(1,19),x,y,255,25,function() E.selected=i end,E.selected==i)
  text(l.a..' / '..l.b,x+269,y+4,13,C.mint)
 end
 local l=E.draft.chromosomes[E.selected].loci[E.site]
 text('Selected: '..pages[E.site]..' / chromosome '..E.selected..' / '..tostring(title(E.site,E.selected)),340,749,13,C.mint)
 button('A -',340,776,70,30,function() E.change('a',-1) end)
 text(tostring(l.a),419,782,18,C.mint)
 button('A +',447,776,70,30,function() E.change('a',1) end)
 button('B -',530,776,70,30,function() E.change('b',-1) end)
 text(tostring(l.b),608,782,18,C.mint)
 button('B +',635,776,70,30,function() E.change('b',1) end)
 button('Undo',725,776,95,30,function() if not E.undo() then msg('Nothing to undo.') end end)
 button('Reset draft',827,776,125,30,function() if c.source then E.begin(c.source) end end)
 button('Preview',960,776,112,30,function()
  local ok,a=pcall(A.generate,E.draft,{nutrition=1,minerals=1,oxygen=1,temperature=37})
  if ok and a then E.forecast=a;msg('Predicted body: '..#a.regions..' regions, '..(a.appendageCount or 0)..' appendages; '..(a.viable and 'viable' or 'nonviable')) else msg('Preview failed: '..tostring(a)) end
 end)
 button('Save DNA copy',1090,776,290,34,function() local ok,why=E.commit(s,c.B);msg(why) end)
 button('Incubate exact edited genome',1090,816,290,30,function()
  if not G.valid(E.draft) then msg('Invalid genome.');return end
  if s.desktop then s.desktop.blankCells=s.desktop.blankCells or 6;if s.desktop.blankCells<1 then msg('No blank developmental cells. Restock at the workstation inspector.');return end end
  local g=G.copy(E.draft);g.mutations=g.mutations or {};for _,h in ipairs(E.history) do if h.side then g.mutations[#g.mutations+1]={locus=h.chromosome,site=h.site,side=h.side,from=h.old,to=h.new,stage='Direct genome editing',effect='Targeted allele modification'} end end
  local record={kind='genome installation',inputs={{source='Edited draft',id=E.origin}},genome=G.copy(g),conditions={nutrition=1,minerals=1,oxygen=1,temperature=37,release='auto'},outcome='Developing',time=s.time,engineeringHistory=G.copy(E.history)}
  local embryo,why=c.B.queue(s,g,'Direct genome engineering',0,record.conditions,#s.experiments+1)
  if embryo then s.experiments[#s.experiments+1]=record;if s.desktop then s.desktop.blankCells=s.desktop.blankCells-1 end end
  msg(embryo and 'Exact genome installed into one developmental cell; incubation started.' or tostring(why))
 end)
 for i,action in ipairs({'duplicate','delete','restore','regulate','splice'}) do button(action,340+(i-1)*115,816,108,30,function() local _,why=E.operation(action,s.materials[E.donor or 1]);msg(why) end) end
 button('Donor >',919,816,75,30,function() E.donor=(E.donor or 1)%math.max(1,#s.materials)+1 end)
 button('Export',1000,816,72,30,function() local _,why=E.export();msg(why) end)
 if E.forecast then text('Forecast: '..#E.forecast.regions..' regions / '..(E.forecast.appendageCount or 0)..' appendages / '..(E.forecast.viable and 'viable' or 'nonviable'),960,740,12,C.mint) end
end
return E

