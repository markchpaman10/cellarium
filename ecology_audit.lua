local G=require('genome');local A=require('anatomy');local H=require('habitat');local S=require('persistence');local E={}
function E.run(B)
 local random=G.rng(7132026);local keys={'land','freshwater','saltwater','amphibious','gliding','poweredFlight','softSkin','scales','thickHide','carapace','claws','teeth','hornsSpines','mixedCoverings'};local counts={};for _,key in ipairs(keys) do counts[key]=0 end
 local failures={};local viable=0;local examples={};local founders={};local rows={'sample,viable,land,freshwater,saltwater,gliding,powered_flight,coverings,projections,mass,metabolism,genome_hash'}
 for i=1,1000 do
  local g=G.fuse({G.new(random),G.new(random),G.new(random)});local a=A.procedural(g);local c=a.caps;local flags={land=c.compatibility.land>=.55,freshwater=c.compatibility.freshwater>=.55,saltwater=c.compatibility.saltwater>=.55,amphibious=c.compatibility.land>=.55 and c.compatibility.freshwater>=.55,gliding=c.flight.glide,poweredFlight=c.flight.powered};local coverings={};local kinds=0
  for _,part in ipairs(a.skin) do if not coverings[part.covering] then coverings[part.covering]=true;kinds=kinds+1 end;if part.covering=='soft skin' then flags.softSkin=true elseif part.covering=='scales' then flags.scales=true elseif part.covering=='thick hide' then flags.thickHide=true elseif part.covering=='carapace' then flags.carapace=true end end
  flags.mixedCoverings=kinds>1;for _,p in ipairs(a.projections or {}) do if p.role=='claw' then flags.claws=true elseif p.role=='tooth' then flags.teeth=true elseif p.role=='horn' or p.role=='spine' then flags.hornsSpines=true end end
  if a.viable then viable=viable+1;if #founders<16 and c.fitness>.3 and math.max(c.compatibility.land,c.compatibility.freshwater)>.7 then founders[#founders+1]=G.copy(g) end end
  for _,key in ipairs(keys) do if flags[key] then counts[key]=counts[key]+1;if a.viable and not examples[key] then examples[key]={genome=G.copy(g),sample=i} end end end
  for _,reason in ipairs(a.failures) do failures[reason]=(failures[reason] or 0)+1 end
  rows[#rows+1]=string.format('%d,%s,%.4f,%.4f,%.4f,%s,%s,%d,%d,%.3f,%.3f,%d',i,tostring(a.viable),c.compatibility.land,c.compatibility.freshwater,c.compatibility.saltwater,tostring(c.flight.glide),tostring(c.flight.powered),kinds,#a.projections,c.mass,c.metabolicDemand,G.hash(g))
 end
 local s=B.new(20261111);s.habitat.foodRate=3;local founding=0
 for _,genome in ipairs(founders) do local o=B.spawn(s,genome,'Ecology audit founder',0);if o then o.maturity=1;o.bodyCondition=1;founding=founding+1 end end
 for i=1,80 do s.food[#s.food+1]=H.resource(s,random) end
 local snapshots={'hour,living,births,deaths,max_generation,genome_diversity,mean_land,mean_freshwater,mean_saltwater,mean_cover_hardness'}
 local deaths={};local maxLiving=0
 for hour=0,900 do
  if hour>0 then B.update(s,1) end
  if hour%30==0 then local living,meanL,meanF,meanS,meanK=0,0,0,0,0;local genomes={};for _,o in ipairs(s.organisms) do if o.alive then living=living+1;meanL=meanL+o.caps.compatibility.land;meanF=meanF+o.caps.compatibility.freshwater;meanS=meanS+o.caps.compatibility.saltwater;meanK=meanK+o.caps.coverHardness;genomes[G.hash(o.genome)]=true end end;local diversity=0;for _ in pairs(genomes) do diversity=diversity+1 end;maxLiving=math.max(maxLiving,living)
   snapshots[#snapshots+1]=string.format('%d,%d,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.4f',hour,living,#s.organisms-founding,#s.organisms-living,s.generation,diversity,meanL/math.max(1,living),meanF/math.max(1,living),meanS/math.max(1,living),meanK/math.max(1,living))
  end
 end
 local finalLiving=0;for _,o in ipairs(s.organisms) do if o.alive then finalLiving=finalLiving+1 else deaths[o.deathCause]=(deaths[o.deathCause] or 0)+1 end end
 local report={'# Ecological adaptation generation audit','','Seed 7132026. 1,000 independent three-wild-genome fusions. Counts are actual anatomical/capability outcomes, include failed embryos, and overlap. Compatible means a computed compatibility score of at least 55%; flight uses the explicit lift, control and force requirements. No category quotas or biological fallback substitutions.','','| Outcome | Count | Frequency |','|---|---:|---:|'}
 for _,key in ipairs(keys) do report[#report+1]=string.format('| %s | %d | %.1f%% |',key,counts[key],counts[key]/10) end
 report[#report+1]='';report[#report+1]='Viable: '..viable..'/1000.';report[#report+1]='';report[#report+1]='## Nonviable causes';report[#report+1]='';local sorted={};for reason in pairs(failures) do sorted[#sorted+1]=reason end;table.sort(sorted);for _,reason in ipairs(sorted) do report[#report+1]='- '..reason..': '..failures[reason] end
 report[#report+1]='';report[#report+1]='## Zero-category investigation';report[#report+1]='';local zero=0;for _,key in ipairs(keys) do if counts[key]==0 then zero=zero+1;report[#report+1]='- '..key..': absent in this sample. Inspect the explicit tissue/force thresholds before treating this category as implemented in ordinary wild output.' end end
 report[#report+1]='';if zero==0 then report[#report+1]='All requested adaptation, covering and projection categories appeared in this seed.';report[#report+1]='' end;report[#report+1]='## Seeded 900-hour habitat run';report[#report+1]='';report[#report+1]=string.format('%d mature founders, %d births, %d deaths, %d living at hour 900; peak sampled population %d; maximum generation G%d. Habitat resource renewal 3x baseline, with no automatic healing, genetic fitness grants, immortality, or forced breeding. Full 30-hour snapshots are in ecology-population.csv.',founding,#s.organisms-founding,#s.organisms-finalLiving,finalLiving,maxLiving,s.generation)
 for cause,count in pairs(deaths) do report[#report+1]='- '..cause..': '..count end
 report[#report+1]='';report[#report+1]=(s.generation<2 and 'Population warning: insufficient natural multi-generation reproduction in this seed; inspect food access, maturity, mate encounter rates and fertility. ' or '')..(finalLiving==0 and 'Universal extinction occurred; causes are above. This run is not presented as a balanced ecosystem.' or 'Population survived this finite run. This does not establish general long-term ecological balance.')
 local root=love.filesystem.getSource();local function write(name,value) local f=assert(io.open(root..'/'..name,'w'));f:write(value);f:close() end
 write('ecology-audit.md',table.concat(report,'\n'));write('ecology-audit.csv',table.concat(rows,'\n'));write('ecology-population.csv',table.concat(snapshots,'\n'));write('ecology_examples.lua','return '..S.encode(examples));write('ecology-audit-data.lua','return '..S.encode({counts=counts,viable=viable,founders=founding,births=#s.organisms-founding,finalLiving=finalLiving,generation=s.generation,deaths=deaths}))
 return true
end
return E
