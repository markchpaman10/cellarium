local G=require('genome')
local K=require('cultivation')
local V={}
V.types={
 {name='Petri dish',capacity=8,growth=1,price=12},
 {name='Culture flask',capacity=32,growth=1.35,price=28},
 {name='Culture plate',capacity=16,growth=1.12,price=22},
 {name='Storage vial',capacity=12,growth=0,price=8},
 {name='Cryovial',capacity=24,growth=0,price=16},
}
local function id(s) local n=s.nextId;s.nextId=n+1;return n end
function V.ensure(s)
 s.vessels=s.vessels or {};s.credits=s.credits or 100
 for _,v in ipairs(s.vessels) do v.temperature=v.temperature or 37;v.waste=v.waste or 0;v.cultureAge=v.cultureAge or 0;v.health=v.health or 1 end
 if not s.vesselsInitialized then
  for _,t in ipairs({1,1,2,3,4,5}) do V.add(s,t,true) end
  s.vesselsInitialized=true
 end
end
function V.add(s,kind,free)
 local def=V.types[kind];if not def then return false,'Invalid vessel.' end
 if not free and (s.credits or 0)<def.price then return false,'Not enough credits.' end
 if not free then s.credits=s.credits-def.price end
 local v={id=id(s),kind=kind,contents={},frozen=false,medium=1,progress=0,nutrients=1,contamination=0,sterility=1,temperature=37,waste=0,cultureAge=0,health=1,closed=false}
 s.vessels[#s.vessels+1]=v;return true,'Empty '..def.name..' acquired.'
end
local function count(v) local n=0;for _,b in ipairs(v.contents) do n=n+b.count end;return n end
V.count=count
local function compatible(a,b) return a.type==b.type and a.sampleKind==b.sampleKind and a.gameteId==b.gameteId and require('persistence').encode(a.genome)==require('persistence').encode(b.genome) end
function V.transfer(s,source,destination,amount)
 local v=s.vessels[destination];if not v or v.frozen then return false,'Select an unfrozen vessel.' end
 local cell=type(source)=='number' and s.cells[source] or source
 if not cell then return false,'Select a cell.' end
 local capacity=V.types[v.kind].capacity-count(v)
 if type(source)~='number' then return false,'Transfers require a counted source. Use the pipette for vessel samples.' end
 if amount and amount~=1 then return false,'One loose cell supplies one cell equivalent.' end
 amount=math.min(1,capacity)
 if amount<1 then return false,'Vessel is full.' end
 if #v.contents>0 and not compatible(v.contents[1].cell,cell) then return false,'Different strains require separate vessels.' end
 local bucket=v.contents[1]
 if bucket then bucket.count=bucket.count+amount else v.contents[1]={cell=G.copy(cell),count=amount} end
 if type(source)=='number' then table.remove(s.cells,source) end
 return true,'Transferred into '..V.types[v.kind].name..'.'
end
function V.withdraw(s,index)
 if s.desktop and s.desktop.physicalStockVersion then return false,'Use the dropper to move cells between physical containers.' end
 local v=s.vessels[index];if not v or v.frozen or #v.contents==0 then return false,'No accessible cells.' end
 local b=v.contents[1];local c=G.copy(b.cell);c.id=id(s);s.cells[#s.cells+1]=c;b.count=b.count-1
 if b.count==0 then v.contents={};v.progress=0 end
 return true,'One cell moved to the library.'
end
function V.freeze(s,index)
 local v=s.vessels[index];if not v or v.kind~=5 or count(v)==0 then return false,'Freeze a filled cryovial.' end
 if v.frozen then return false,'Already frozen.' end
 v.frozen=true;for _,b in ipairs(v.contents) do if b.cell.gameteId then local h=require('physical_cells').gamete(s,b.cell.gameteId);if h then h.frozen=true end end end;return true,'Whole cryovial frozen.'
end
function V.thaw(s,index)
 local v=s.vessels[index];if not v or not v.frozen then return false,'Select a frozen cryovial.' end
 v.frozen=false
 for _,b in ipairs(v.contents) do if b.cell.gameteId then local h=require('physical_cells').gamete(s,b.cell.gameteId);if h then h.frozen=false end end end
 for _,b in ipairs(v.contents) do b.cell.viability=math.max(0,b.cell.viability*.96) end
 return true,'Cryovial thawed; viability assessed.'
end
function V.cultivate(s,index,medium)
 local v=s.vessels[index];if not v or v.frozen or V.types[v.kind].growth==0 then return false,'This vessel cannot cultivate cells.' end
 if count(v)==0 then return false,'Transfer cells into the vessel first.' end
 if count(v)>=V.types[v.kind].capacity then return false,'Vessel is full.' end
 v.medium=medium or v.medium;v.cultivating=true;return true,'Fed cultures grow automatically in real time.'
end
function V.growthInfo(v)
 local def=V.types[v.kind];local n=count(v);local b=v.contents[1]
 if v.frozen then return {status='Frozen'} end
 if not b or n<=0 then return {status='Empty'} end
 if b.cell.sampleKind=='blank' then return {status='Blank cell / awaiting DNA installation'} end
 if b.cell.sampleKind=='gamete' then return {status=(b.cell.gameteKind or 'Gamete')..((b.cell.gameteProgress or 0)>=1 and ' / mature' or ' / maturing')} end
 if def.growth==0 then return {status='Stored sample'} end
 if n>=def.capacity then return {status='Full'} end
 if (v.nutrients or 0)<.025 then return {status='Needs food'} end
 if (v.health or 1)<=.05 or (b.cell.viability or 1)<=.05 then return {status='Culture not viable'} end
 local suitability=math.max(0,1-math.abs((v.temperature or 37)-37)/20)
 if suitability<=0 then return {status='Unsuitable temperature'} end
 local e=G.express(b.cell.genome)
 local doublingMinutes=12/(K.rates[b.cell.type]*def.growth*(.65+e[6]*.3+e[1]*.05))
 local rate=math.log(2)/doublingMinutes*suitability*math.max(0,v.nutrients)*(v.health or 1)*(1-(v.contamination or 0))*(v.medium==2 and 1.4 or 1)
 if rate<=0 then return {status='Culture stressed'} end
 local fraction=math.max(0,math.min(.999999,v.progress or 0));local seconds=math.log((n+1)/(n+fraction))/rate*60
 return {status='Growing',rate=rate,nextCellSeconds=seconds,doublingSeconds=math.log(2)/rate*60}
end
function V.timerText(v)
 local info=V.growthInfo(v);return info.nextCellSeconds and ('Next cell ~'..require('realtime').duration(info.nextCellSeconds)) or info.status
end
function V.feed(s,index)
 local v=s.vessels[index];if not v then return false,'Container unavailable.' end
 if v.frozen then return false,'Thaw this container before adding food.' end
 if V.types[v.kind].growth==0 then return false,'This is a storage container, not a cultivation dish.' end
 v.nutrients=1;return true,'Food replenished. Growth resumes automatically when conditions allow.'
end
function V.update(s,dt)
 for _,v in ipairs(s.vessels or {}) do
  if not v.frozen then
   local remaining=dt
   while remaining>1e-10 do
    local step=math.min(.25,remaining);remaining=remaining-step
    v.cultureAge=(v.cultureAge or 0)+step;v.temperature=v.temperature or 37;v.waste=v.waste or 0;v.health=v.health or 1;v.progress=v.progress or 0
    local population=count(v);local cultivation=V.types[v.kind].growth>0
    if cultivation and population>0 then v.nutrients=math.max(0,v.nutrients-step*population*.0005) end
    v.contamination=math.min(1,(v.contamination or 0)+step*(1-(v.sterility or 1))*.003*(1+v.waste))
    local stress=math.abs(v.temperature-37)/35*.02+v.contamination*.01+(cultivation and v.nutrients<=0 and .003 or 0)
    v.health=math.max(0,v.health-step*stress)
    for _,b in ipairs(v.contents) do b.cell.viability=math.min(b.cell.viability,v.health);b.cell.age=b.cell.age+step end
    local info=V.growthInfo(v);v.cultivating=info.status=='Growing'
    if v.cultivating then
     local b=v.contents[1];local room=V.types[v.kind].capacity-population
     local growth=(population+v.progress)*math.exp(info.rate*step)-population
     local births=math.min(room,math.floor(growth+1e-10),math.floor(v.nutrients/.025))
     b.count=b.count+births;v.totalBirths=(v.totalBirths or 0)+births;v.nutrients=math.max(0,v.nutrients-births*.025);v.waste=math.min(1,v.waste+births*.02)
     v.progress=births>=room and 0 or math.min(.999999,math.max(0,growth-births))
    end
   end
   v.cultivating=V.growthInfo(v).status=='Growing'
  end
 end
end
function V.sellCell(s,index)
 local c=s.cells[index];if not c then return false,'Select a cell.' end
 if (c.viability or 0)<.1 then return false,'Nonviable cells must be discarded.' end
 table.remove(s.cells,index);s.credits=(s.credits or 0)+3;return true,'Cell sold for 3 credits.'
end
function V.sellVessel(s,index)
 local v=s.vessels[index];if not v then return false,'Select a vessel.' end
 if v.contamination>.2 then return false,'Contaminated cultures require disposal.' end
 local n=count(v);local price=math.floor(V.types[v.kind].price*.4)+n*2;if v.suppliedCellPurchase then price=math.min(price,1) end
 table.remove(s.vessels,index);s.credits=(s.credits or 0)+price
 return true,'Vessel and contents sold for '..price..' credits.'
end
function V.discard(s,index)
 local v=s.vessels[index];if not v then return false,'Select a vessel.' end
 v.contents={};v.cultivating=false;v.progress=0;v.contamination=0;v.nutrients=1;v.sterility=1;v.frozen=false
 return true,'Contents disposed and vessel cleaned for reuse.'
end
return V

