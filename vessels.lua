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
 if not s.vesselsInitialized then
  for _,t in ipairs({1,1,2,3,4,5}) do V.add(s,t,true) end
  s.vesselsInitialized=true
 end
end
function V.add(s,kind,free)
 local def=V.types[kind];if not def then return false,'Invalid vessel.' end
 if not free and (s.credits or 0)<def.price then return false,'Not enough credits.' end
 if not free then s.credits=s.credits-def.price end
 local v={id=id(s),kind=kind,contents={},frozen=false,medium=1,progress=0,nutrients=1,contamination=0,sterility=1}
 s.vessels[#s.vessels+1]=v;return true,'Empty '..def.name..' acquired.'
end
local function count(v) local n=0;for _,b in ipairs(v.contents) do n=n+b.count end;return n end
V.count=count
local function compatible(a,b) return a.type==b.type and G.hash(a.genome)==G.hash(b.genome) end
function V.transfer(s,source,destination,amount)
 local v=s.vessels[destination];if not v or v.frozen then return false,'Select an unfrozen vessel.' end
 local cell=type(source)=='number' and s.cells[source] or source
 if not cell then return false,'Select a cell.' end
 local capacity=V.types[v.kind].capacity-count(v)
 amount=math.min(amount or 1,capacity)
 if amount<1 then return false,'Vessel is full.' end
 if #v.contents>0 and not compatible(v.contents[1].cell,cell) then return false,'Different strains require separate vessels.' end
 local bucket=v.contents[1]
 if bucket then bucket.count=bucket.count+amount else v.contents[1]={cell=G.copy(cell),count=amount} end
 if type(source)=='number' then table.remove(s.cells,source) end
 return true,'Transferred into '..V.types[v.kind].name..'.'
end
function V.withdraw(s,index)
 local v=s.vessels[index];if not v or v.frozen or #v.contents==0 then return false,'No accessible cells.' end
 local b=v.contents[1];local c=G.copy(b.cell);c.id=id(s);s.cells[#s.cells+1]=c;b.count=b.count-1
 if b.count==0 then v.contents={};v.progress=0 end
 return true,'One cell moved to the library.'
end
function V.freeze(s,index)
 local v=s.vessels[index];if not v or v.kind~=5 or count(v)==0 then return false,'Freeze a filled cryovial.' end
 if v.frozen then return false,'Already frozen.' end
 v.frozen=true;return true,'Whole cryovial frozen.'
end
function V.thaw(s,index)
 local v=s.vessels[index];if not v or not v.frozen then return false,'Select a frozen cryovial.' end
 v.frozen=false
 for _,b in ipairs(v.contents) do b.cell.viability=math.max(0,b.cell.viability*.96) end
 return true,'Cryovial thawed; viability assessed.'
end
function V.cultivate(s,index,medium)
 local v=s.vessels[index];if not v or v.frozen or V.types[v.kind].growth==0 then return false,'This vessel cannot cultivate cells.' end
 if count(v)==0 then return false,'Transfer cells into the vessel first.' end
 if count(v)>=V.types[v.kind].capacity then return false,'Vessel is full.' end
 v.medium=medium or v.medium;v.cultivating=true;return true,'Cultivation started.'
end
function V.update(s,dt)
 for _,v in ipairs(s.vessels or {}) do
  if v.cultivating and not v.frozen and #v.contents>0 then
   local b=v.contents[1];local def=V.types[v.kind]
   local room=def.capacity-count(v)
   if room<=0 then v.cultivating=false else
    local e=G.express(b.cell.genome)
    local rate=K.rates[b.cell.type]*def.growth*(.65+e[6]*.3+e[1]*.05)*(v.medium==2 and 1.4 or 1)*(1-v.contamination)*math.max(.1,v.nutrients)/15
    v.progress=v.progress+dt*rate
    local born=math.min(room,math.floor(v.progress))
    if born>0 then b.count=b.count+born;v.progress=v.progress-born;v.nutrients=math.max(0,v.nutrients-born*.025) end
    if count(v)>=def.capacity or v.nutrients<=.02 then v.cultivating=false end
   end
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
 local n=count(v);local price=math.floor(V.types[v.kind].price*.4)+n*2
 table.remove(s.vessels,index);s.credits=(s.credits or 0)+price
 return true,'Vessel and contents sold for '..price..' credits.'
end
function V.discard(s,index)
 local v=s.vessels[index];if not v then return false,'Select a vessel.' end
 v.contents={};v.cultivating=false;v.progress=0;v.contamination=0;v.nutrients=1;v.sterility=1;v.frozen=false
 return true,'Contents disposed and vessel cleaned for reuse.'
end
return V
