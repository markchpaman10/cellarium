local L=require('lab_engineering');local G=require('genome');local A=require('anatomy');local R=require('rendering');local X=require('gene_expression');local C=require('cognition')
local U={mode='editor',selected={},vial=1,page=1,draft=1,chromosome=1,site=1,organism=1,naming=false,nameBuffer=''}
function U.textinput(value) if U.naming then U.nameBuffer=(U.nameBuffer..value):sub(1,30) end end
function U.keypressed(key,s)
 if not U.naming then return false end
 if key=='escape' then U.naming=false elseif key=='backspace' then U.nameBuffer=U.nameBuffer:sub(1,-2) elseif key=='return' then local d=L.ensure(s).drafts[U.draft];if d and #U.nameBuffer>0 then d.name=U.nameBuffer end;U.naming=false end;return true
end
function U.draw(s,c)
 L.starter(s);local lab=L.ensure(s);local text,button,panel,col,msg=c.text,c.button,c.panel,c.col,c.msg;local palette=c.C
 local function result(ok,why) msg(why or (ok and 'Done.' or 'Operation unavailable.')) end
 panel(32,202,260,650);button('DNA workshop',49,220,226,32,function() U.mode='editor' end,U.mode=='editor');button('Life & observations',49,262,226,32,function() U.mode='life' end,U.mode=='life')
 if U.mode=='life' then
  for i=1,math.min(13,#s.organisms) do local o=s.organisms[i];button(o.name,49,318+(i-1)*33,226,28,function() U.organism=i end,U.organism==i) end
  panel(314,202,1094,650);local o=s.organisms[U.organism];if not o then text('Install a genome, grow an embryo, then return here.',340,240,22,palette.muted);return end
  text(o.name..' / '..(o.lifeStage or 'Juvenile'),340,224,24);text('Inherited predispositions, learned memories and current vital signs are distinct.',340,266,13,palette.muted)
  local stats=o.stats or require('living_stats').calculate(o);for i,key in ipairs({'STR','DEF','DEX','INT','VIT','END'}) do local x=340+(i-1)*174;text(key,x,307,13,palette.muted);text(string.format('%.2f',stats[key]),x,335,28,palette.mint) end
  local vital=o.vitals or {};text(string.format('Oxygen %.0f%% / energy %.0f%% / stamina %.0f%% / hydration %.0f%%',100*(o.oxygen or 1),o.energy,o.stamina,o.hydration),340,392,14,palette.mint)
  text('Cardiac function: '..(vital.cardiac and string.format('%.0f beats/min / pressure %.2f / volume %.2f',vital.heartRate or 0,vital.pressure or 0,vital.bloodVolume or 0) or 'no cardiac pump modeled'),340,421,13,palette.muted)
  local nature=o.nature or C.nature(o);local keys={'sociability','aggression','fearfulness','curiosity','territoriality','dominance','tolerance','attachment','exploration','flexibility','stressSensitivity','socialLearning'}
  text('INHERITED / DEVELOPED PREDISPOSITIONS',340,469,12,palette.mint)
  for i,key in ipairs(keys) do local x=340+math.floor((i-1)/6)*305;local y=506+(i-1)%6*32;text(key,x,y,12,palette.muted);col(palette.line);love.graphics.rectangle('fill',x+158,y+5,113,5);col(palette.mint);love.graphics.rectangle('fill',x+158,y+5,113*(nature[key] or 0),5) end
  local brain=C.ensure(o);local cap=C.capabilities(o);text('MEMORY / ACTUAL EXPERIENCE',985,469,12,palette.mint);text(#brain.memories..' / '..cap.capacity..' memories; recognition '..tostring(cap.recognition),985,504,12,palette.muted)
  for row=0,5 do local m=brain.memories[#brain.memories-row];if m then text(m.kind..(m.subject and ' # '..m.subject or '')..' / '..math.floor(m.strength*100)..'%',985,541+row*31,12,palette.muted) end end
  text('Activity: '..(o.behavior or '')..' / '..(o.behaviorReason or 'Physiological needs'),340,731,13,palette.mint)
  local relations=0;for _ in pairs(brain.relationships) do relations=relations+1 end;text(relations..' recognized relationships / '..#brain.events..' signaling events / '..#(o.observationHistory or {})..' observations',340,771,13,palette.muted)
  text('Communication uses implemented posture/chemical signals. Speech and desktop control are unavailable.',340,810,12,palette.muted);return
 end
 text('DNA VIALS / '..lab.credits..' credits',49,316,12,palette.mint)
 button('Purchase DNA vial / 10',49,343,226,31,function() local v,why=L.buyVial(s);if v then U.vial=#lab.vials;U.page=math.ceil(#lab.vials/8);msg('New unidentified DNA sequence acquired.') else msg(why) end end)
 local start=(U.page-1)*8+1;for row=0,7 do local index=start+row;local v=lab.vials[index];if v then local y=391+row*41
  button((U.selected[v.id] and '+ ' or '')..v.name,49,y,226,35,function() U.selected[v.id]=not U.selected[v.id];U.vial=index end,U.selected[v.id])
 end end
 button('<',49,728,50,28,function() U.page=math.max(1,U.page-1) end);button('>',225,728,50,28,function() U.page=math.min(math.max(1,math.ceil(#lab.vials/8)),U.page+1) end)
 button('Assemble selected DNA',49,775,226,43,function() local ids={};for _,v in ipairs(lab.vials) do if U.selected[v.id] then ids[#ids+1]=v.id end end;local draft,why=L.draft(s,ids);if draft then U.draft=#lab.drafts;msg('Complete genome assembled from '..#ids..' DNA sources.') else msg(why) end end)
 panel(314,202,760,650);panel(1094,202,314,650);text('Engineer the starting instructions.',340,224,26);text('Splice DNA, compare expression, install a complete genome into a blank cell.',340,266,13,palette.muted)
 local d=lab.drafts[U.draft];local vial=lab.vials[U.vial]
 button('< strain',340,302,110,28,function() U.draft=math.max(1,U.draft-1) end);button('strain >',940,302,108,28,function() U.draft=math.min(#lab.drafts,U.draft+1) end)
 text(d and d.name or 'No assembled genome yet',464,307,16,palette.mint)
 local names={'Primary tissue','Development','Ecology'};for site,name in ipairs(names) do button(name,340+(site-1)*236,347,221,30,function() U.site=site end,U.site==site) end
 if d then
  for chromosome=1,24 do local x=340+math.floor((chromosome-1)/12)*354;local y=394+(chromosome-1)%12*25;local l=d.genome.chromosomes[chromosome].loci[U.site];local name=U.site==1 and G.loci[chromosome].name or (U.site==2 and G.developmentLoci or G.environmentLoci)[chromosome]
   button(string.format('%02d',chromosome)..' '..name:sub(1,21),x,y,228,22,function() U.chromosome=chromosome end,U.chromosome==chromosome);text(l.a..'|'..l.b..' x'..(l.copies or 1),x+240,y+4,11,l.deleted and {1,.5,.4} or palette.mint)
  end
  text('Target '..U.chromosome..' / site '..U.site..' / expressed '..math.floor(X.value(d.genome,U.chromosome,U.site)*100)..'%',340,710,12,palette.muted)
  for i,action in ipairs({'splice','duplicate','delete','restore','mutate','regulate'}) do local x=340+(i-1)%3*236;local y=743+math.floor((i-1)/3)*43;button(action,x,y,221,33,function() result(L.edit(s,d,action,U.chromosome,U.site,vial)) end) end
 else text('Select one or more vials on the left, then assemble a genome.\nMore than three sources are supported. No species is selected.\n\nEach chromosome retains its three existing modeled loci.\nDeletion suppresses expression; duplication alters dosage.\nRegulation links developmental activity to a target locus.\nGenome installation initiates the existing embryonic growth system.',340,434,16,palette.muted) end
 text('BLANK-CELL INSTALLATION',1116,224,12,palette.mint)
 local a;if d then local key=G.hash(d.genome)..'/'..d.revision;if U.previewKey~=key then U.preview=A.generate(G.copy(d.genome));U.previewKey=key end;a=U.preview;R.draw({anatomy=a,caps=a.caps,alive=true,maturity=1,angle=0,behavior='Resting'},1250,342,R.fitScale(a,245,150,2.5),0,'External')
  text(a.viable and 'Functional developmental forecast' or 'Nonviable: inspect your edits',1116,444,12,a.viable and palette.mint or {1,.5,.4});text(#d.sources..' DNA sources / revision '..d.revision,1116,470,12,palette.muted)
 end
 button('Install genome / single embryo',1116,508,268,37,function() result(L.install(s,d,c.B,false)) end,false,not d)
 button('Batch engineer / 6 stem cells',1116,555,268,37,function() result(L.install(s,d,c.B,true)) end,false,not d)
 button('Name engineered strain',1116,603,268,30,function() if d then U.naming=true;U.nameBuffer=d.name end end,false,not d)
 button('Archive genome',1116,643,128,30,function() result(L.archive(s,d)) end,false,not d);button('Reuse archive',1253,643,131,30,function() if L.restore(s,#lab.archives) then U.draft=#lab.drafts;msg('Archived genome copied into a fresh draft.') else msg('Archive a genome first.') end end)
 button('Blank cells +6 / 8 credits',1116,685,268,30,function() result(L.restock(s)) end)
 text('Blank cells '..lab.blankCells..' / embryos '..#s.eggs..'\nSpecialized cells remain research materials.',1116,731,12,palette.muted)
 if vial then button(vial.sequenced and 'Sequence identified' or vial.assay and 'Sequencing '..math.floor(vial.progress*100)..'%' or 'Sequence selected vial / 6 h',1116,780,268,31,function() vial.assay=true end,vial.sequenced);text(vial.sequenced and ('Organization: '..vial.findings.bodySymmetry..' / '..vial.findings.sequenceLength..' bases') or 'Unidentified sequence / assay to research',1116,822,11,palette.muted);end
 if U.naming then panel(450,390,600,143);text('Strain name / Enter accepts / Esc cancels',475,410,14,palette.mint);text(U.nameBuffer..'_',475,455,24) end
end
return U
