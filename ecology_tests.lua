local G=require('genome');local A=require('anatomy');local H=require('habitat');local P=require('physiology');local S=require('persistence');local D=require('defenses')
return function(B,test)
 local examples=require('ecology_examples')
 local function specimen(key) return G.copy(assert(examples[key]).genome) end
 local function allele(g,i,value) local l=g.chromosomes[i].loci[3];l.a=value;l.b=value end
 local function environment(kind) local s=B.new(123);for _,cell in ipairs(s.habitat.cells) do cell.kind=kind;cell.salinity=kind=='saltwater' and 1 or 0;cell.oxygen=1;cell.obstacle=false end;return s end
 test('Ecology loci preserve existing alleles and are inherited through all paths',function()
  local g=specimen('amphibious');local old=G.copy(g);for _,chr in ipairs(g.chromosomes) do chr.loci[3]=nil end;g.version=3;G.upgrade(g);for i=1,24 do for site=1,2 do assert(S.encode(g.chromosomes[i].loci[site])==S.encode(old.chromosomes[i].loci[site])) end end
  local child=G.fertilize(G.gamete(g,G.rng(14),'a',false),G.gamete(old,G.rng(15),'b',false));assert(child.version==4 and #child.chromosomes[1].loci==3);local fused=G.fuse({old,old,old});for i=1,24 do assert(fused.chromosomes[i].loci[3].a==old.chromosomes[i].loci[3].a) end
 end)
 test('Suitable air and aquatic respiration sustain organisms; mismatch causes stress',function()
  for _,medium in ipairs({'land','freshwater'}) do local g=specimen(medium);allele(g,1,medium=='land' and 3 or 0);allele(g,2,medium=='land' and 0 or 3);local a=A.procedural(g);local s=environment(medium);local o=P.new(1,g,'test',0,.5,.5,0,a);o.maturity=1
   for i=1,300 do P.update(o,s,.1,1) end;assert(o.alive and o.oxygen>.65,'Compatible respiration must sustain the organism')
  end
  local g=specimen('land');allele(g,1,3);allele(g,2,0);allele(g,18,3);allele(g,10,0);local a=A.procedural(g);for _,skin in ipairs(a.skin) do skin.exchange=0 end;for _,gill in ipairs(a.gills) do gill.capacity=0 end;local s=environment('freshwater');local o=P.new(1,g,'stress',0,.5,.5,0,a);o.maturity=1
  for i=1,200 do P.update(o,s,.1,1) end;assert(o.oxygen<.8,'Incompatible respiration should reduce oxygen reserve')
 end)
 test('Amphibious organisms cross habitat boundaries by continuous movement',function()
  local g=specimen('amphibious');allele(g,1,3);allele(g,2,3);local a=A.procedural(g);local s=environment('land')
  for row=1,H.height do for column=29,H.width do local cell=s.habitat.cells[(row-1)*H.width+column];cell.kind='freshwater';cell.oxygen=1 end end
  local o=P.new(1,g,'crossing',0,.499,.5,0,a);o.energy=50;o.maturity=1;s.food={{x=.53,y=.5,kind='debris'}};local previous=o.x;local crossed=false
  for i=1,200 do P.update(o,s,.1,1);assert(math.abs(o.x-previous)<.02,'No teleportation');previous=o.x;if o.x>.5 then crossed=true;break end end;assert(crossed)
 end)
 test('Flight requires generated surfaces, lift, coordination and force',function()
  local g=specimen('poweredFlight');local a=A.procedural(g);assert(a.caps.flight.powered and #a.surfaces>0)
  for _,surface in ipairs(a.surfaces) do surface.condition=0 end;local caps=A.capabilities(a,g);assert(not caps.flight.powered and not caps.flight.glide)
  local h=specimen('land');allele(h,10,0);local noWing=A.procedural(h);assert(not noWing.caps.flight.powered)
 end)
 test('Regional coverings cost mass, metabolism, flexibility and exchange',function()
  local g=specimen('land');allele(g,14,0);allele(g,15,0);allele(g,18,0);local light=A.procedural(g);allele(g,14,3);allele(g,15,3);allele(g,18,3);local heavy=A.procedural(g)
  assert(heavy.caps.mass>light.caps.mass and heavy.caps.metabolicDemand>light.caps.metabolicDemand);assert(heavy.skin[1].armor>light.skin[1].armor);assert(heavy.skin[1].exchange<light.skin[1].exchange)
  local variation=false;for _,cover in ipairs(heavy.skin) do if cover.flexibility~=heavy.skin[1].flexibility or cover.armor~=heavy.skin[1].armor then variation=true end end;assert(variation)
 end)
 test('Projections have valid attachments and mechanism-specific protection',function()
  local g=specimen('hornsSpines');local a=A.procedural(g);assert(#a.projections>0)
  for _,p in ipairs(a.projections) do assert(a.components[p.parent] and p.parent<p.id and p.mass>0 and p.attachmentStrength>=0 and p.effectiveness>=0) end
  local cover=a.skin[1];local piercing=D.response(cover,'pierce',10);local blunt=D.response(cover,'blunt',10);assert(piercing.capacity~=blunt.capacity);local before=cover.condition;D.impact(a,cover.id,'pierce',100);assert(cover.condition<before)
 end)
 test('Feeding structures determine access without making predators',function()
  local tooth=A.procedural(specimen('teeth'));assert(#tooth.mouths>0 and tooth.caps.biteForce>=0);assert(tooth.caps.diet.tissue>0 and tooth.caps.diet.debris>0)
  local g=specimen('land');allele(g,20,0);local plain=A.procedural(g);assert(#plain.projections==0);assert(plain.caps.diet.tissue<tooth.caps.diet.tissue or plain.caps.diet.plant~=tooth.caps.diet.plant)
 end)
 test('Habitat generation is seeded, mixed and reproduces resource placement',function()
  local a,b=H.new(35),H.new(35);assert(S.encode(a)==S.encode(b));local types={};for _,cell in ipairs(a.cells) do types[cell.kind]=true end;assert(types.land and types.freshwater and types.saltwater and #a.plants>0 and #a.obstacles>0)
 end)
 test('Forge settings change genetic outcomes and developmental phenotype',function()
  local parents={specimen('land'),specimen('freshwater'),specimen('scales')};local normal=G.fuse(parents);local mosaic=G.fuse(parents,{recombination='mosaic'});assert(G.hash(normal)~=G.hash(mosaic));local exposed=G.fuse(parents,{exposure=.15});assert(#exposed.mutations>0)
  local g=specimen('carapace');local lean=A.procedural(g,{nutrition=.7,temperature=37,minerals=.5,oxygen=.65});local rich=A.procedural(g,{nutrition=1.2,temperature=37,minerals=1.4,oxygen=1.25});assert(rich.caps.mass>lean.caps.mass);assert(rich.skin[1].hardness>lean.skin[1].hardness);assert(G.hash(g)==G.hash(specimen('carapace')),'Development conditions must not rewrite the genome')
 end)
 test('Save round trip preserves ecological anatomy, habitat and defenses',function()
  local s=B.new(24);B.collect(s);local g=specimen('hornsSpines');local o=assert(B.spawn(s,g,'save test',0));local r=assert(S.decode('return '..S.encode(s),B));assert(r.version==5 and S.encode(s.habitat)==S.encode(r.habitat));assert(S.encode(o.anatomy.components)==S.encode(r.organisms[1].anatomy.components));local p=r.organisms[1].anatomy.projections[1];assert(p==r.organisms[1].anatomy.components[p.id])
 end)
 test('Library filtering/sorting/favorites and Fahrenheit conversion work',function()
  local L=require('cell_library');local U=require('units');local s=B.new(55);B.collect(s);B.collect(s);L.filter=1;L.favoritesOnly=false;local list=L.indices(s);assert(#list==2);s.cells[list[2]].favorite=true;L.favoritesOnly=true;assert(#L.indices(s)==1);L.filter=0;L.favoritesOnly=false;L.sort=1;assert(math.abs(U.f(37)-98.6)<.00001 and math.abs(U.c(98.6)-37)<.00001)
 end)
 test('Navigation routes around physical obstacles and births retain local positions',function()
  local N=require('navigation');local g=specimen('amphibious');local a=A.procedural(g);local s=environment('land');local o=P.new(1,g,'navigation',0,.4,.5,0,a);o.maturity=1;o.oxygen=1;o.traits.perception=0
  local startX=math.floor(o.x*H.width)+1;local row=math.floor(o.y*H.height)+1;s.habitat.cells[(row-1)*H.width+startX+1].obstacle=true
  assert(N.heading(s,o,.5,.5));for _,node in ipairs(o.navigation.path) do if type(node)=='number' then assert(not s.habitat.cells[node].obstacle) end end
  local parentA=assert(B.spawn(s,g,'a',0,.4,.5));local parentB=assert(B.spawn(s,g,'b',0,.41,.5));parentA.maturity=1;parentB.maturity=1;assert(B.breed(s,parentA,parentB));assert(math.abs(s.eggs[1].birthLocation.x-.405)<.000001)
 end)

 test('Airway and mouth injuries affect actual respiration and feeding',function()
  local g=specimen('land');g.chromosomes[11].loci[2].a=3;g.chromosomes[11].loci[2].b=3;local a=A.procedural(g);assert(#a.airways>0 and #a.mouths>0);local healthy=A.capabilities(a,g);A.damage(a,'Airway',1);A.damage(a,'Mouth',1);local injured=A.capabilities(a,g);assert(injured.airRespiration<healthy.airRespiration and injured.diet.debris==0 and injured.biteForce==0)
 end)

end
