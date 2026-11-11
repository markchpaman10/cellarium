local G={version=4}
local DG=require('development_genes')
local EG=require('environment_genes');G.environmentLoci=EG.names
G.developmentLoci=DG.names
local names={'Power','Strength','Dexterity','Intelligence','Health','Vitality','Endurance','Nature','Speed','Attunement','Body size','Body length','Body width','Limb pairs','Bone density','Muscle growth','Fat storage','Skin thickness','Heart capacity','Lung capacity','Digestion','Neural wiring','Pigment','Fertility'}
G.loci={}
for i,name in ipairs(names) do G.loci[i]={id='L'..i,chromosome=i,name=name,mode=(i==18 and 'dominant' or i==24 and 'recessive' or i==23 and 'codominant' or i==8 and 'incomplete' or 'additive'),mutationRate=.003,influence=i<=10 and 'Primary trait' or 'Development'} end
function G.copy(v) if type(v)~='table' then return v end;local r={};for k,x in pairs(v) do r[k]=G.copy(x) end;return r end
function G.valid(g)
 if type(g)~='table' or type(g.chromosomes)~='table' or #g.chromosomes~=24 then return false end
 for i,c in ipairs(g.chromosomes) do
  if c.id~=i or not c.loci or #c.loci<1 then return false end
  for j,l in ipairs(c.loci) do
   if l.id~=(({ 'L','D','E' })[j]..i) then return false end
   for _,side in ipairs({'a','b'}) do local v=l[side];if type(v)~='number' or v<0 or v>3 or v%1~=0 then return false end end
  end
  if (g.version==3 and #c.loci~=2) or (g.version==4 and #c.loci~=3) then return false end
 end;return true
end
function G.upgrade(g)
 assert(G.valid(g),'Invalid genome before schema migration');if g.version==4 then return g end
 local seed=G.hash(g);local rand=G.rng(seed)
 for i,c in ipairs(g.chromosomes) do if not c.loci[2] then c.loci[2]={id='D'..i,a=math.floor(rand()*4),b=math.floor(rand()*4),sourceA='v2 extension',sourceB='v2 extension'} end end
 local defaults={3,1,2,2,2,1,2,2,1,0,1,2,1,1,1,2,1,1,2,0,1,1,1,2}
 for i,c in ipairs(g.chromosomes) do c.loci[3]={id='E'..i,a=defaults[i],b=defaults[i],sourceA='v3 compatible extension',sourceB='v3 compatible extension'} end
 g.version=4;g.schemaMigration='Original primary/developmental loci retained; ecology extension';return g
end
function G.new(rand)
 local g={version=4,chromosomes={},mutations={},lineage={}}
 for i=1,24 do g.chromosomes[i]={id=i,loci={{id='L'..i,a=math.floor(rand()*4),b=math.floor(rand()*4),sourceA='wild',sourceB='wild'}}} end
 for i,c in ipairs(g.chromosomes) do c.loci[2]={id='D'..i,a=math.floor(rand()*4),b=math.floor(rand()*4),sourceA='wild population',sourceB='wild population'} end
 for i,c in ipairs(g.chromosomes) do c.loci[3]={id='E'..i,a=math.floor(rand()*4),b=math.floor(rand()*4),sourceA='wild ecology',sourceB='wild ecology'} end
 return g
end
function G.value(g,i)
 local l=g.chromosomes[i].loci[1];local mode=G.loci[i].mode
 if mode=='dominant' then return math.max(l.a,l.b)/3 elseif mode=='recessive' then return math.min(l.a,l.b)/3 else return (l.a+l.b)/6 end
end
function G.express(g)
 local e={};for i,d in ipairs(G.loci) do e[i]=G.value(g,i);e[d.name]=e[i] end
 e.perception=(e[4]+e[10]+e[22])/3;e.immunity=(e[5]+e[6]+e[18])/3;e.stability=(e[6]+e[22])/2
 e.homozygosity=0;e.recessiveLoad=0;for i,c in ipairs(g.chromosomes) do local l=c.loci[1];if l.a==l.b then e.homozygosity=e.homozygosity+1/24 end;if (i==19 or i==20 or i==24) and l.a==0 and l.b==0 then e.recessiveLoad=e.recessiveLoad+1 end end
 e.development=DG.expression(g);e.ecology=EG.expression(g);e.fitness=math.max(0,(.35+e[24]*.65)*(1-e.recessiveLoad*.23));return e
end
function G.marker(g)
 local bases={'A','C','G','T'};local dna,bits='',0
 for i=1,4 do local l=g.chromosomes[i].loci[1];for _,v in ipairs({l.a,l.b}) do dna=dna..bases[v+1];bits=bits*4+v end end
 return dna,bits
end
function G.hash(g)
 local n=17;for _,c in ipairs(g.chromosomes) do for _,l in ipairs(c.loci) do n=(n*31+l.a*4+l.b+1)%2147483647 end end;return n
end
function G.rng(seed) return function() seed=(seed*48271)%2147483647;return seed/2147483647 end end
function G.mutate(g,rand,rate,stage)
 local changed=0
 for i,c in ipairs(g.chromosomes) do for j,l in ipairs(c.loci) do for _,side in ipairs({'a','b'}) do if rand()<(rate or G.loci[i].mutationRate)*(j==2 and ((i==4 or i==6 or i==17) and .12 or .6) or 1) then local old=l[side];l[side]=math.max(0,math.min(3,old+(rand()<.5 and -1 or 1)));if old~=l[side] then changed=changed+1;g.mutations[#g.mutations+1]={locus=i,site=j,side=side,from=old,to=l[side],stage=stage or 'Replication',effect=(j==2 and 'Developmental instruction shift; context dependent' or i==23 and 'Neutral pigment variation' or (i==11 or i==16 or i==17 or i==8) and 'Context dependent' or l[side]>old and 'Capacity increase; biological cost may rise' or 'Capacity decrease')} end end end end end
 return changed
end
function G.fuse(genomes,options)
 options=options or {}
 local seed=1;for _,g in ipairs(genomes) do seed=(seed+G.hash(g))%2147483647 end;local rand=G.rng(seed);local out=G.copy(genomes[1]);out.mutations={};out.lineage={'Three-source laboratory recombination'}
 for i,c in ipairs(out.chromosomes) do for j,l in ipairs(c.loci) do for _,side in ipairs({'a','b'}) do local a,b,d=genomes[1].chromosomes[i].loci[j][side],genomes[2].chromosomes[i].loci[j][side],genomes[3].chromosomes[i].loci[j][side];local v=(a==b or a==d) and a or (b==d and b or ({a,b,d})[math.floor(rand()*3)+1]);if options.recombination=='mosaic' then local donor=1+((i+j+(side=='a' and 0 or 1))%3);v=genomes[donor].chromosomes[i].loci[j][side] end;l[side]=v;l[side=='a' and 'sourceA' or 'sourceB']='Lab majority' end end end
 for _,parent in ipairs(genomes) do for _,m in ipairs(parent.mutations or {}) do local l=out.chromosomes[m.locus] and out.chromosomes[m.locus].loci[m.site or 1];if l and (l.a==m.to or l.b==m.to) then local inherited=G.copy(m);inherited.inheritedFrom=G.hash(parent);out.mutations[#out.mutations+1]=inherited end end end
 if (options.exposure or 0)>0 then G.mutate(out,rand,options.exposure,'Forge exposure') end
 return out,seed
end
function G.gamete(g,rand,source,mutation)
 local h={alleles={},source=source,events={},mutations={}}
 for i,c in ipairs(g.chromosomes) do local side=rand()<.5 and 'a' or 'b';h.alleles[i]={};for j,l in ipairs(c.loci) do if j>1 and rand()<.2 then side=side=='a' and 'b' or 'a';h.events[#h.events+1]={chromosome=i,locus=j} end;local v=l[side];if mutation and rand()<.003*(1.5-G.express(g).stability)*(j==2 and ((i==4 or i==6 or i==17) and .12 or .6) or 1) then local old=v;v=math.max(0,math.min(3,v+(rand()<.5 and -1 or 1)));if old~=v then h.mutations[#h.mutations+1]={locus=i,site=j,from=old,to=v,stage='Meiosis'} end end;h.alleles[i][j]=v end end
 for _,m in ipairs(g.mutations or {}) do if h.alleles[m.locus] and h.alleles[m.locus][m.site or 1]==m.to then local inherited=G.copy(m);inherited.inheritedFrom=source;h.mutations[#h.mutations+1]=inherited end end
 return h
end
function G.fertilize(a,b)
 local out={version=4,chromosomes={},mutations={},lineage={a.source,b.source}}
 for i=1,24 do if not a.alleles[i] or not b.alleles[i] then return nil end;out.chromosomes[i]={id=i,loci={}};for j,v in ipairs(a.alleles[i]) do out.chromosomes[i].loci[j]={id=({'L','D','E'})[j]..i,a=v,b=b.alleles[i][j],sourceA=a.source,sourceB=b.source} end end
 for _,h in ipairs({a,b}) do for _,m in ipairs(h.mutations or {}) do out.mutations[#out.mutations+1]=G.copy(m) end end
 return G.valid(out) and out or nil
end
function G.similarity(a,b) local n,total=0,0;for i=1,24 do for j,x in ipairs(a.chromosomes[i].loci) do local y=b.chromosomes[i].loci[j];if y then n=n+((x.a==y.a and 1 or 0)+(x.b==y.b and 1 or 0));total=total+2 end end end;return n/math.max(1,total) end
function G.legacy(old)
 local g=G.new(G.rng(76123));local v={};for i=1,7 do v[i]=math.max(0,math.min(3,math.floor(((old or {})[i] or 1)*1.5))) end
 local map={[9]=1,[4]=2,[10]=2,[21]=3,[6]=4,[11]=5,[23]=6,[24]=7}
 for i,j in pairs(map) do local l=g.chromosomes[i].loci[1];l.a=v[j];l.b=v[j] end;g.lineage={'Migrated v1 seven-value genome'};return g
end
function G.importNumeric(str)
 if type(str)~='string' or #str~=16 or str:find('%D') then return nil,'Expected legacy 16 numeric characters.' end
 local g=G.new(G.rng(99));local map={2,6,4,3,14,11,18,23};for j,i in ipairs(map) do local v=math.min(3,math.floor(tonumber(str:sub(j*2-1,j*2))/25));g.chromosomes[i].loci[1].a=v;g.chromosomes[i].loci[1].b=v end;g.lineage={'Explicit import of legacy eight-trait numeric format'};return g
end
return G
