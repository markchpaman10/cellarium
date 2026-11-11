local G=require('genome');local R={}
function R.compatible(a,b)
 if a==b or a.id==b.id then return false,'Choose two distinct parents.' end
 if not a.alive or not b.alive then return false,'Both parents must be alive.' end
 if a.maturity<1 or b.maturity<1 then return false,'Both parents must be mature.' end
 if a.energy<45 or b.energy<45 then return false,'Parents need at least 45% energy.' end
 if a.caps.fitness<.1 or b.caps.fitness<.1 then return false,'Harmful recessive combinations limit fertility.' end;return true
end
function R.inherit(a,b,rand)
 local egg=G.gamete(a.genome,rand,'Organism '..a.id,true);local sperm=G.gamete(b.genome,rand,'Organism '..b.id,true);local genome=G.fertilize(egg,sperm)
 local common=0;local seen={};for _,id in ipairs(a.ancestry or {}) do seen[id]=true end;for _,id in ipairs(b.ancestry or {}) do if seen[id] then common=common+1 end end
 local ancestry={a.id,b.id};for id in pairs(seen) do ancestry[#ancestry+1]=id end;for _,id in ipairs(b.ancestry or {}) do if not seen[id] then ancestry[#ancestry+1]=id end end
 return genome,{a.id,b.id},math.max(a.generation,b.generation)+1,ancestry,common
end
return R
