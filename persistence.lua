local G=require('genome');local K=require('cultivation');local A=require('anatomy');local P=require('physiology');local D=require('development');local S={}
function S.encode(v)
 if type(v)=='number' then assert(v==v and math.abs(v)<math.huge,'Invalid number');return string.format('%.17g',v) elseif type(v)=='boolean' then return tostring(v) elseif type(v)=='string' then return string.format('%q',v) elseif type(v)=='table' then local p={'{'};local keys={};for k in pairs(v) do keys[#keys+1]=k end;table.sort(keys,function(a,b) return tostring(a)<tostring(b) end);for _,k in ipairs(keys) do p[#p+1]='['..S.encode(k)..']='..S.encode(v[k])..',' end;p[#p+1]='}';return table.concat(p) end;return 'nil'
end
function S.rebind(a)
 if a.version~=3 then a.generator='legacy-fallback' end
 local lists={Bone='bones',Muscle='muscles',Fat='fat',Skin='skin',Sensor='sensors',Gill='gills',Airway='airways',Membrane='surfaces',Fin='surfaces',Projection='projections',Mouth='mouths'};a.bones={};a.structures={};a.muscles={};a.fat={};a.skin={};a.organs={};a.sensors={};a.gills={};a.airways={};a.surfaces={};a.projections={};a.mouths={}
 for _,c in ipairs(a.components) do local key=lists[c.type];if key then a[key][#a[key]+1]=c end;if c.type=='Bone' or c.type=='Support' or c.type=='Carapace' then a.structures[#a.structures+1]=c elseif c.type=='Heart' or c.type=='Lung' or c.type=='Brain' or c.type=='Stomach' then a.organs[#a.organs+1]=c end end;return a
end
local function upgradeAll(value,seen)
 if type(value)~='table' then return end;seen=seen or {};if seen[value] then return end;seen[value]=true
 if value.chromosomes then G.upgrade(value);return end
 for _,v in pairs(value) do upgradeAll(v,seen) end
end
function S.migrate(old,B)
 if old.version==2 or old.version==3 or old.version==4 or old.version==5 then
  upgradeAll(old)
  for _,h in ipairs(old.gametes or {}) do
   local source=h.genomeSource;if source then local rand=G.rng(G.hash(source)+(h.id or 1));for i=1,24 do for site=2,3 do if not h.alleles[i][site] then local l=source.chromosomes[i].loci[site];h.alleles[i][site]=rand()<.5 and l.a or l.b end end end end
  end
  old.version=5;require('lab_engineering').ensure(old);require('habitat').ensure(old)
  for _,c in ipairs(old.cells) do assert(G.valid(c.genome),'Invalid cell genome') end
  for _,c in ipairs(old.frozen) do assert(G.valid(c.genome),'Invalid frozen genome') end
  for _,o in ipairs(old.organisms) do assert(G.valid(o.genome),'Invalid organism genome');S.rebind(o.anatomy);o.traits=G.express(o.genome);o.caps=A.capabilities(o.anatomy,o.genome);o.altitude=o.altitude or 0;o.oxygen=o.oxygen or 1;require('cognition').ensure(o);require('living_stats').updateVitals(o,0) end
  for _,e in ipairs(old.eggs) do assert(G.valid(e.genome),'Invalid embryo genome');if e.anatomy then S.rebind(e.anatomy) end end;return old
 end
 assert(not old.version,'Unsupported future save version')
 local s=B.new(old.seed);s.nextId=old.nextId or 1;s.time=old.time or 0;s.history=G.copy(old.history or {});s.food=G.copy(old.food or {});s.collected=old.collected or 0
 local mapping={1,2,3,5,4,4,6}
 local function cell(c,frozen)
  local n=K.cell(c.id,mapping[c.type],G.legacy(c.g),c.parent,0,c.id);n.subtype=c.type==6 and 'Digestive' or nil;n.preservation=frozen and 'frozen' or 'living';return n
 end
 for _,c in ipairs(old.cells or {}) do s.cells[#s.cells+1]=cell(c) end
 for _,c in ipairs(old.frozen or {}) do s.frozen[#s.frozen+1]=cell(c,true) end
 for _,d in ipairs(old.dishes or {}) do local n=K.dish(cell(d.cell),d.medium);n.progress=d.progress;n.viable=math.floor(d.progress*4);s.dishes[#s.dishes+1]=n end
 for _,o in ipairs(old.organisms or {}) do local g=G.legacy(o.g);local n=P.new(o.id,g,o.parents,o.generation,o.x,o.y,o.angle);n.age=o.age;n.health=o.health;n.energy=o.energy;n.alive=o.alive;n.behavior=o.behavior;n.maturity=math.min(1,o.age*n.caps.growthRate);s.organisms[#s.organisms+1]=n;s.generation=math.max(s.generation,n.generation);s.lineages[n.id]={parents=n.parents,parentIds={},children={},generation=n.generation} end
 for _,e in ipairs(old.eggs or {}) do local n=D.new(e.id,G.legacy(e.g),e.parents,0);n.progress=e.progress;if n.progress>.35 then n.anatomy=A.generate(n.genome) end;s.eggs[#s.eggs+1]=n end
 B.log(s,'Migrated v1: canonical chromosomes, cell categories and anatomy reconstructed.');return s
end
function S.decode(str,B)
 local f,err=loadstring(str);if not f then return nil,err end;setfenv(f,{});local ok,result=pcall(f);if not ok or type(result)~='table' or not result.cells then return nil,'Invalid save data' end
 local success,data=pcall(S.migrate,result,B);if not success then return nil,data end;return data
end
function S.save(s)
 local payload='return '..S.encode(s);local ok,why=love.filesystem.write('experiment-next.lua',payload);if not ok then return false,why end
 local check=S.decode(payload,require('biology'));if not check then return false,'Save validation failed' end
 local previous=love.filesystem.read('experiment.lua');if previous then love.filesystem.write('experiment-backup.lua',previous) end
 return love.filesystem.write('experiment.lua',payload)
end
return S
