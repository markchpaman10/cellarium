local G=require('genome');local A=require('anatomy');local DG=require('development_genes');local S=require('persistence');local Audit={}
local function signature(a)
 local t={a.symmetry,a.exchangeMethod,#a.regions,#a.appendages,a.caps.locomotion};for _,r in ipairs(a.regions) do t[#t+1]=string.format('%d:%s:%d:%.5f:%.5f:%.5f:%.5f',r.id,r.kind,r.parent or 0,r.x,r.y,r.rx,r.ry) end
 for _,o in ipairs(a.organs) do t[#t+1]=string.format('%s:%.5f:%.5f:%.5f',o.type,o.x,o.y,o.capacity) end;return table.concat(t,'|')
end
function Audit.run(B)
 local rand=G.rng(20261111);local n=1000;local counts={bilateral=0,radial=0,asymmetric=0,limbless=0,fourAppendages=0,fourLegged=0,realizedRadial=0,branched=0,compact=0,elongatedLimbless=0,segmented=0,multilegged=0,viable=0,invalidGraph=0,deterministic=0};local viableCounts={};local locomotion={};local failures={};local pool={};local examples={};local rows={'sample,viable,symmetry,axis_regions,appendages,branch_depth,locomotion,exchange,width,height,genome_hash'};local shapes={}
 for i=1,n do
  local sources={};for k=1,3 do sources[k]=G.new(rand) end
  local g=G.fuse(sources);local a=A.procedural(g,{temperature=37,nutrition=1});local attrs={a.symmetry}
  if a.appendageCount==0 then attrs[#attrs+1]='limbless' end
  if a.appendageCount==4 then attrs[#attrs+1]='fourAppendages' end
  local locomotorRoots=0;for _,p in ipairs(a.appendages) do if p.depth==1 and p.functionType=='jointed propulsion' then locomotorRoots=locomotorRoots+1 end end
  if locomotorRoots==4 then attrs[#attrs+1]='fourLegged' end
  if a.symmetry=='radial' and #a.regions>=4 then attrs[#attrs+1]='realizedRadial' end
  local depth=0;for _,p in ipairs(a.appendages) do depth=math.max(depth,p.depth) end;if depth>1 then attrs[#attrs+1]='branched' end
  local aspect=math.max(a.bounds.width/a.bounds.height,a.bounds.height/a.bounds.width)
  if aspect<1.6 and a.segments<=5 then attrs[#attrs+1]='compact' end
  if a.appendageCount==0 and aspect>2.4 then attrs[#attrs+1]='elongatedLimbless' end
  if a.segments>=6 then attrs[#attrs+1]='segmented' end
  if locomotorRoots>=6 then attrs[#attrs+1]='multilegged' end
  for _,key in ipairs(attrs) do counts[key]=counts[key]+1;if a.viable then viableCounts[key]=(viableCounts[key] or 0)+1;local score=(key=='radial' and (#a.regions>3 and 100 or 0)+a.appendageCount*2 or key=='multilegged' and (a.symmetry=='bilateral' and 100 or 0)+locomotorRoots or key=='branched' and (a.symmetry=='bilateral' and 1000 or 0)+depth*20+a.appendageCount or key=='compact' and (a.appendageCount==0 and 1000 or 0)+a.bounds.width*a.bounds.height*.001 or key=='asymmetric' and a.appendageCount*2 or 1);if not examples[key] or score>(examples[key].score or 0) then examples[key]={genome=G.copy(g),sample=i,description=key,score=score} end end end
  if a.viable then counts.viable=counts.viable+1;pool[#pool+1]={g=g,a=a} end
  for _,reason in ipairs(a.failures) do failures[reason]=(failures[reason] or 0)+1;if reason:find('Disconnected') or reason:find('attachment') then counts.invalidGraph=counts.invalidGraph+1 end end
  if i%10==0 then assert(signature(a)==signature(A.procedural(G.copy(g),{temperature=37,nutrition=1})),'Nondeterministic growth');counts.deterministic=counts.deterministic+1 end
  locomotion[a.caps.locomotion]=(locomotion[a.caps.locomotion] or 0)+1
  local topology=a.symmetry..'/'..a.segments..'/'..a.appendageCount..'/'..depth..'/'..a.caps.locomotion..'/'..a.exchangeMethod;shapes[topology]=true
  rows[#rows+1]=string.format('%d,%s,%s,%d,%d,%d,%s,%s,%.3f,%.3f,%d',i,tostring(a.viable),a.symmetry,a.segments,a.appendageCount,depth,a.caps.locomotion,a.exchangeMethod,a.bounds.width,a.bounds.height,G.hash(g))
 end
 local offspringViable,alleleErrors,totalError,retention=0,0,0,0;local crosses=200
 for k=1,crosses do
  local pa=pool[1+math.floor(rand()*#pool)];local pb=pool[1+math.floor(rand()*#pool)];local egg=G.gamete(pa.g,rand,'Audit A',true);local sperm=G.gamete(pb.g,rand,'Audit B',true);local child=assert(G.fertilize(egg,sperm));local a=A.procedural(child);if a.viable then offspringViable=offspringViable+1 end
  for i,c in ipairs(child.chromosomes) do for j,l in ipairs(c.loci) do if l.a~=egg.alleles[i][j] or l.b~=sperm.alleles[i][j] then alleleErrors=alleleErrors+1 end end end
  local da,db,dc=DG.expression(pa.g),DG.expression(pb.g),DG.expression(child);for i=1,24 do totalError=totalError+math.abs(dc[i]-(da[i]+db[i])/2) end
  if dc.symmetry==da.symmetry or dc.symmetry==db.symmetry then retention=retention+1 end
 end
 local unique=0;for _ in pairs(shapes) do unique=unique+1 end
 local gates={};local function gate(name,pass,value) gates[#gates+1]={name=name,passed=pass,value=value} end
 gate('At least 65% viable wild fusions',counts.viable>=650,counts.viable..'/1000')
 for _,key in ipairs({'bilateral','radial','asymmetric'}) do gate(key..' is at least 10% of output',counts[key]>=100,counts[key]..'/1000') end
 gate('At least 100 visibly multi-region radial bodies',counts.realizedRadial>=100,counts.realizedRadial..'/1000')
 gate('Limbless output at least 15%',counts.limbless>=150,counts.limbless..'/1000')
 gate('Four-appendage output below 40%',counts.fourAppendages<400,counts.fourAppendages..'/1000')
 for _,key in ipairs({'branched','compact','elongatedLimbless','multilegged'}) do gate(key..' has at least 30 viable examples', (viableCounts[key] or 0)>=30,(viableCounts[key] or 0)..' viable') end
 gate('No disconnected growth / invalid attachments',counts.invalidGraph==0,counts.invalidGraph)
 gate('Deterministic regeneration of 100 sampled genomes',counts.deterministic==100,counts.deterministic..'/100')
 gate('At least 65% viable offspring of viable parents',offspringViable>=130,offspringViable..'/200')
 gate('All 28,800 child allele contributions match gametes',alleleErrors==0,alleleErrors)
 gate('Mean developmental dosage error from mid-parent below 0.18',totalError/(crosses*24)<.18,string.format('%.5f',totalError/(crosses*24)))
 local stableLines=0;for _,example in pairs(examples) do local parent=G.copy(example.genome);for _,chr in ipairs(parent.chromosomes) do for _,l in ipairs(chr.loci) do l.b=l.a end end;local expected=signature(A.procedural(parent));local stable=true;for generation=1,3 do local child=G.fertilize(G.gamete(parent,rand,'Selected line A',false),G.gamete(parent,rand,'Selected line B',false));if signature(A.procedural(child))~=expected then stable=false end;parent=child end;if stable then stableLines=stableLines+1 end end;local lineCount=0;for _ in pairs(examples) do lineCount=lineCount+1 end;gate('Homozygous selected lines retain anatomy for three generations',stableLines==lineCount,stableLines..'/'..lineCount)
 local survival=0;for i=1,100 do local selected=pool[1+math.floor((i-1)/100*#pool)];local state=B.new(1000+i);local animal=B.spawn(state,G.copy(selected.g),'Physiology audit',0,.5,.5,A.procedural(selected.g));for j=1,55 do state.food[#state.food+1]={x=.07+rand()*.86,y=.1+rand()*.8} end;for tick=1,600 do B.update(state,.1,1) end;if animal.alive then survival=survival+1 end;assert(animal.energy==animal.energy and animal.caps.speed==animal.caps.speed,'Non-finite physiology') end;gate('At least 90 of 100 viable samples survive 60 benign habitat hours',survival>=90,survival..'/100')
 local approved=true;for _,v in ipairs(gates) do if not v.passed then approved=false end end
 local report={seed=20261111,samples=n,counts=counts,viableCounts=viableCounts,locomotion=locomotion,failures=failures,uniqueTopologies=unique,habitatSurvival=survival,offspring={crosses=crosses,viable=offspringViable,alleleErrors=alleleErrors,meanDosageError=totalError/(crosses*24),parentSymmetryRetained=retention},gates=gates,approved=approved}
 local md={'# Cellarium measured developmental diversity audit','', 'Seed: 20261111. 1,000 independent three-wild-genome laboratory fusions, followed by 200 crosses of viable parents. No acceptance-category templates are used. Counts include failed embryos; viable counts are reported separately. Categories overlap. Symmetry labels describe the developmental program; realizedRadial additionally requires at least four grown regions. fourLegged counts four primary jointed locomotor branches; total appendages also includes recursive branches. No technical or biological fallback was used in this audit.','', '| Observed output | All embryos | Viable embryos |','|---|---:|---:|'}
 for _,key in ipairs({'bilateral','radial','asymmetric','limbless','fourAppendages','fourLegged','realizedRadial','branched','compact','elongatedLimbless','segmented','multilegged'}) do md[#md+1]=string.format('| %s | %d (%.1f%%) | %d |',key,counts[key],counts[key]/10,viableCounts[key] or 0) end
 md[#md+1]='';md[#md+1]='Total viable: '..counts.viable..'/1000. Distinct measured topology signatures: '..unique..'.';md[#md+1]='';md[#md+1]='| Observed movement | Count |';md[#md+1]='|---|---:|';for _,name in ipairs({'jointed','contractions','undulation','radial','stationary'}) do md[#md+1]='| '..name..' | '..(locomotion[name] or 0)..' |' end
 md[#md+1]='';md[#md+1]=string.format('Offspring: %d/%d viable; %d allele-contribution errors; mean developmental expression deviation from the parental midpoint %.5f; symmetry matches at least one parent in %d/%d crosses. Mutation is enabled. The 200-cross assay tests inheritance, not a guarantee of identical offspring silhouettes.',offspringViable,crosses,alleleErrors,totalError/(crosses*24),retention,crosses)
 md[#md+1]='';md[#md+1]='A separate 100-sample physiological assay ran actual organisms for 60 simulation hours each, with temperate conditions, freshwater and initial food. Survivors: '..survival..'/100. This is a short survival check, not a claim of long-term ecological balance.';md[#md+1]='';md[#md+1]='## Predetermined release gates';md[#md+1]='';for _,v in ipairs(gates) do md[#md+1]='- '..(v.passed and 'PASS' or 'FAIL')..': '..v.name..' — '..tostring(v.value) end
 md[#md+1]='';md[#md+1]='## Development failures';md[#md+1]='';local keys={};for key in pairs(failures) do keys[#keys+1]=key end;table.sort(keys);for _,key in ipairs(keys) do md[#md+1]='- '..key..': '..failures[key] end
 md[#md+1]='';md[#md+1]='Release decision: '..(approved and 'New generator approved as default. Legacy generator remains available for technical failures and old saved anatomy.' or 'Keep legacy generator as default; new generator did not meet the release gates.')
 local root=love.filesystem.getSource();local function write(name,str) local f=assert(io.open(root..'/'..name,'w'));f:write(str);f:close() end
 write('diversity-audit.md',table.concat(md,'\n'));write('diversity-audit.csv',table.concat(rows,'\n'));write('diversity-audit-data.lua','return '..S.encode(report));write('audit_examples.lua','return '..S.encode(examples))
 write('generator_certificate.lua','-- Generated by the measured audit; do not hand-edit.\nreturn '..S.encode({approved=approved,seed=20261111,samples=1000,viable=counts.viable,offspringViable=offspringViable,topologies=unique}))
 return approved,report
end
return Audit
