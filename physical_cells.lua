local G=require('genome');local B=require('biology');local V=require('vessels');local M=require('desktop_model');local F={price=1}
function F.label(c)
 if not c then return 'Empty' end
 if c.sampleKind=='blank' then return 'Blank developmental cell' end
 if c.sampleKind=='gamete' then return (c.gameteKind or 'Gamete')..' '..((c.gameteProgress or 0)>=1 and 'cell' or 'precursor') end
 return B.types[c.type]..' cell'
end
function F.vial(s,cell,label)
 V.ensure(s);V.add(s,4,true);local v=s.vessels[#s.vessels];v.label=label or F.label(cell);if cell then v.contents={{cell=cell,count=1}} end;return v
end
function F.buy(s,category)
 if category~='blank' and (type(category)~='number' or not B.types[category]) then return false,'Unknown cell category.' end
 V.ensure(s);if s.credits<F.price then return false,'A cell with its vial costs 1 credit.' end
 local cell=B.cell(s,category=='blank' and 1 or category,nil,'Purchased starter stock',0)
 if category=='blank' then cell.sampleKind='blank';cell.name='Blank developmental cell' end
 local vial=F.vial(s,cell);vial.suppliedCellPurchase=true;s.credits=s.credits-F.price;return true,'Purchased one '..F.label(cell)..' in vial #'..vial.id..'.',vial
end
function F.ensure(s)
 local d=M.ensure(s);V.ensure(s)
 -- Preserve existing loose specimens by housing them, never discarding them.
 while #s.cells>0 do F.vial(s,table.remove(s.cells,1),'Recovered cell stock') end
 if not d.physicalStockVersion then
  for i=1,math.max(0,d.blankCells or 0) do local c=B.cell(s,1,nil,'Existing blank-cell stock',0);c.sampleKind='blank';c.name='Blank developmental cell';F.vial(s,c) end
  d.blankCells=0;d.physicalStockVersion=1
 end
 for _,h in ipairs(s.gametes) do if not h.physical and h.genomeSource and G.valid(h.genomeSource) then local c=B.cell(s,1,h.genomeSource,'Existing '..h.kind..' stock',h.generation);c.sampleKind='gamete';c.gameteKind=h.kind;c.gameteId=h.id;c.gameteProgress=h.progress;c.name=h.kind..' precursor';c.replicationCapacity=0;local v=F.vial(s,c);h.physical=true;h.containerId=v.id;h.location='container' end end
 local gametes={};for _,h in ipairs(s.gametes) do gametes[h.id]=h end
 for _,v in ipairs(s.vessels) do local b=v.contents[1];if b and b.cell.sampleKind=='gamete' then local h=gametes[b.cell.gameteId];if not h then v.contents={};v.cultivating=false else b.cell.gameteProgress=h.progress;h.containerId=v.id;h.location='container';h.frozen=v.frozen end end end
 local present={};for _,v in ipairs(s.vessels) do for _,b in ipairs(v.contents) do if b.cell.gameteId then present[b.cell.gameteId]=true end end end;local held=d.pipette.sample;if held and held.cell.gameteId then present[held.cell.gameteId]=true end;for _,c in ipairs(s.frozen) do if c.gameteId then present[c.gameteId]=true end end;for i=#s.gametes,1,-1 do local h=s.gametes[i];if h.physical and not present[h.id] then table.remove(s.gametes,i) end end
end
function F.beginDevelopment(s,containerId)
 local v=require('desktop_samples').vessel(s,containerId);local b=v and v.contents[1];if not b or not b.cell.developmentalCell or v.closed or v.frozen then return false,'An open container holding an installed developmental cell is required.' end
 local record={kind='physical genome installation',genome=G.copy(b.cell.genome),conditions={nutrition=1,oxygen=1,temperature=v.temperature or 37},outcome='Developing',time=s.time};local embryo,why=B.queue(s,b.cell.genome,'Installed cell '..b.cell.id,b.cell.generation,record.conditions,#s.experiments+1);if not embryo then return false,why end
 s.experiments[#s.experiments+1]=record;b.count=b.count-1;if b.count==0 then v.contents={};v.cultivating=false end;return true,'Installed cell consumed; development started in incubation.'
end
function F.consumeGamete(s,id)
 for _,v in ipairs(s.vessels or {}) do for i=#v.contents,1,-1 do if v.contents[i].cell.gameteId==id then table.remove(v.contents,i);v.cultivating=false;v.progress=0 end end end
 local pip=s.desktop and s.desktop.pipette;if pip and pip.sample and pip.sample.cell.gameteId==id then pip.sample=nil end
end
function F.gamete(s,id) for _,h in ipairs(s.gametes) do if h.id==id then return h end end end
return F
