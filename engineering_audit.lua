local G=require('genome');local A=require('anatomy');local L=require('lab_engineering');local T=require('living_stats');local C=require('cognition');local P=require('physiology');local S=require('persistence');local H=require('habitat');local E={}
function E.run(B)
 local started=love.timer.getTime();local random=G.rng(20261112);local viable,moreThanThree=0,0;local symmetries={};local topologies={};local stats={};local natures={};local capacity={none=0,simple=0,recognition=0};local pool={};local rows={'sample,sources,viable,symmetry,regions,appendages,STR,DEF,DEX,INT,VIT,END,aggression,sociability,memory_capacity,genome_hash'}
 local function observe(summary,name,value) local v=summary[name] or {minimum=value,maximum=value,sum=0,count=0};v.minimum=math.min(v.minimum,value);v.maximum=math.max(v.maximum,value);v.sum=v.sum+value;v.count=v.count+1;summary[name]=v end
 for sample=1,1000 do local s=B.new(math.floor(random()*2147483646)+1);local ids={};local sources=1+(sample-1)%6;for i=1,sources do ids[i]=L.buyVial(s,true).id end;local draft=L.draft(s,ids);local a=A.procedural(draft.genome);local g=draft.genome
  symmetries[a.symmetry]=(symmetries[a.symmetry] or 0)+1;topologies[a.symmetry..'/'..#a.regions..'/'..a.appendageCount..'/'..a.caps.locomotion]=true;if sources>3 then moreThanThree=moreThanThree+1 end
  local o=P.new(1,g,'Batch audit',0,.5,.5,0,a);o.maturity=1;T.updateVitals(o,0);local nature=C.nature(o);local neural=C.capabilities(o)
  for name,value in pairs(o.stats) do observe(stats,name,value) end;for name,value in pairs(nature) do observe(natures,name,value) end
  capacity[neural.capacity==0 and 'none' or neural.recognition and 'recognition' or 'simple']=capacity[neural.capacity==0 and 'none' or neural.recognition and 'recognition' or 'simple']+1
  if a.viable then viable=viable+1;if #pool<8 and a.caps.fitness>.2 then pool[#pool+1]=G.copy(g) end end
  rows[#rows+1]=string.format('%d,%d,%s,%s,%d,%d,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%d,%d',sample,sources,tostring(a.viable),a.symmetry,#a.regions,a.appendageCount,o.stats.STR,o.stats.DEF,o.stats.DEX,o.stats.INT,o.stats.VIT,o.stats.END,nature.aggression,nature.sociability,neural.capacity,G.hash(g))
 end
 local world=B.new(20261112);world.habitat.foodRate=3
 for pair,g in ipairs(pool) do local location
  for _,allele in ipairs({0,3}) do local variant=G.copy(g);variant.chromosomes[8].loci[1].a=allele;variant.chromosomes[8].loci[1].b=allele;local a=A.procedural(variant);if a.viable then if not location then location=H.location(world.habitat,a.caps,'auto',{x=.1+pair*.08,y=.3+pair*.04}) end;local o=B.spawn(world,variant,'Matched Nature pair '..pair,0,location.x,location.y+(allele==3 and .003 or 0),a);if o then o.maturity=1 end end end
 end
 for i=1,80 do world.food[#world.food+1]=H.resource(world,random) end
 local founders=#world.organisms
 for hour=1,60 do B.update(world,1) end
 local alive,memories,relationships,signals=0,0,0,0;local activities={};local encounters=0
 for _,o in ipairs(world.organisms) do if o.alive then alive=alive+1 end;local c=C.ensure(o);memories=memories+#c.memories;signals=signals+#c.events;activities[o.behavior]=(activities[o.behavior] or 0)+1;for _,r in pairs(c.relationships) do relationships=relationships+1;encounters=encounters+r.encounters end end
 local restored=assert(S.decode('return '..S.encode(world),B));local restoredMemories,restoredRelationships=0,0;for _,o in ipairs(restored.organisms) do restoredMemories=restoredMemories+#o.cognition.memories;for _ in pairs(o.cognition.relationships) do restoredRelationships=restoredRelationships+1 end end
 assert(memories==restoredMemories and relationships==restoredRelationships,'Cognitive state changed after round trip')
 local unique=0;for _ in pairs(topologies) do unique=unique+1 end
 local duration=love.timer.getTime()-started;local md={'# Genome engineering development audit','','Seed 20261112. 1,000 genomes constructed from one through six independently generated DNA vials. No predefined organisms, forced viability or personality templates. The 1,000-case measurements include failed embryos; statistics are calculated from actual anatomy at standardized mature condition.','',string.format('Viable: %d/1000. More-than-three-source assemblies: %d/1000. Distinct measured body topology signatures: %d.',viable,moreThanThree,unique),'', '| Dynamic summary | Minimum | Mean | Maximum |','|---|---:|---:|---:|'}
 for _,key in ipairs({'STR','DEF','DEX','INT','VIT','END'}) do local v=stats[key];md[#md+1]=string.format('| %s | %.4f | %.4f | %.4f |',key,v.minimum,v.sum/v.count,v.maximum) end
 md[#md+1]='';md[#md+1]='## Continuous inherited/developed predispositions';md[#md+1]='';md[#md+1]='| Dimension | Minimum | Mean | Maximum |';md[#md+1]='|---|---:|---:|---:|';local names={};for name in pairs(natures) do names[#names+1]=name end;table.sort(names);for _,name in ipairs(names) do local v=natures[name];md[#md+1]=string.format('| %s | %.3f | %.3f | %.3f |',name,v.minimum,v.sum/v.count,v.maximum) end
 md[#md+1]='';md[#md+1]=string.format('Neural memory capacity: %d without persistent memory, %d with simple memory, %d with individual-recognition capacity.',capacity.none,capacity.simple,capacity.recognition)
 md[#md+1]='';md[#md+1]='## Actual 60-hour matched-pair observations';md[#md+1]='';md[#md+1]=string.format('%d founders were placed in pairs in suitable environments, with paired genomes differing at the Nature locus. No relationships or memories were assigned. Adults share a physical neighborhood at the start; the remaining encounters are autonomous. Habitat renewal: 3x. At hour 60: %d living organisms, %d retained memories, %d learned directional relationships, %d recorded relationship encounters, %d retained structured signal events.',founders,alive,memories,relationships,encounters,signals)
 for activity,count in pairs(activities) do md[#md+1]='- '..activity..': '..count end
 md[#md+1]='';md[#md+1]='Memory and relationship counts match after a complete version-5 state round trip. This is a finite regression assay; it does not establish lifelike cognition or a balanced long-term ecosystem.';md[#md+1]=string.format('\nElapsed on this host: %.3f seconds for construction, anatomy, physiology/cohort updates and persistence validation. This is a reproducible workload measurement, not a frame-rate guarantee.',duration)
 local root=love.filesystem.getSource();local function write(name,value) local f=assert(io.open(root..'/'..name,'w'));f:write(value);f:close() end
 write('engineering-audit.md',table.concat(md,'\n'));write('engineering-audit.csv',table.concat(rows,'\n'));write('engineering-audit-data.lua','return '..S.encode({seed=20261112,viable=viable,moreThanThreeSources=moreThanThree,topologies=unique,stats=stats,nature=natures,capacity=capacity,founders=founders,alive=alive,memories=memories,relationships=relationships,encounters=encounters,signals=signals,activities=activities,seconds=duration,persistence=true}))
 return true
end
return E
