local X={}
local function clamp(x) return math.max(0,math.min(1,x)) end
local function raw(l,mode)
 if not l or l.deleted or l.copies==0 then return 0 end
 local value=mode=='dominant' and math.max(l.a,l.b)/3 or mode=='recessive' and math.min(l.a,l.b)/3 or (l.a+l.b)/6
 return clamp(value*(.65+.35*(l.copies or 1)))
end
function X.value(g,chromosome,site,mode)
 local c=g.chromosomes[chromosome];local value=raw(c and c.loci[site],mode)
 -- Regulators read source dosage once; cycles cannot recurse or explode.
 for _,r in ipairs(g.regulation or {}) do if r.targetChromosome==chromosome and r.targetSite==site then local source=g.chromosomes[r.sourceChromosome];local activity=raw(source and source.loci[r.sourceSite]);value=value*(1+(r.mode=='suppress' and -1 or 1)*math.min(.8,r.gain or .25)*activity) end end
 return clamp(value)
end
return X
