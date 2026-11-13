local G=require('genome');local B=require('biology');local V=require('vessels');local D=require('workshop_docking');local W={}
function W.log(s,id,message)
 local o=D.station(s,id);if o then o.config.terminal=o.config.terminal or {};table.insert(o.config.terminal,1,tostring(message));while #o.config.terminal>6 do table.remove(o.config.terminal) end end
 return message
end
local function source(s,id)
 local v=D.container(s,id,'input');if not v or V.count(v)<1 then return nil,'Attach an input container containing a cell.' end
 if v.closed or v.frozen then return nil,'Open and thaw the input container first.' end
 return v,v.contents[1].cell
end
local function finish(s,id,ok,message) W.log(s,id,message);return ok,message end
local function consume(v) local b=v.contents[1];b.count=b.count-1;if b.count==0 then v.contents={};v.cultivating=false;v.progress=0 end end
function W.extract(s,id)
 local v,c=source(s,id);if not v then return finish(s,id,false,c) end
 if c.sampleKind then return finish(s,id,false,'DNA extraction requires an ordinary cell, not a blank or haploid precursor.') end
 local record={id=B.id(s),source='Cell '..c.id..' / container '..v.id,genome=G.copy(c.genome),strain=c.strain,generation=c.generation,name='Extracted DNA '..c.id}
 s.materials[#s.materials+1]=record;D.station(s,id).config.genomeId=record.id
 return finish(s,id,true,'DNA #'..record.id..' archived. Source cell retained.')
end
function W.install(s,id)
 local input,output,why=D.validatePair(s,id);if not input then return finish(s,id,false,why) end
 local cell=input.contents[1].cell;if cell.sampleKind~='blank' then return finish(s,id,false,'DNA installation requires a purchased blank developmental cell in the input container.') end
 local genomeId=D.station(s,id).config.genomeId;local dna;for _,record in ipairs(s.materials) do if record.id==genomeId then dna=record;break end end
 if not dna or not G.valid(dna.genome) then return finish(s,id,false,'Select a valid archived genome on the workshop.') end
 local result=B.cell(s,1,G.copy(dna.genome),'Workshop DNA '..dna.id,0);result.developmentalCell=true;output.contents={{cell=result,count=1}};consume(input)
 return finish(s,id,true,'One blank cell consumed. Installed cell delivered to container #'..output.id..'.')
end
function W.precursor(s,id,kind)
 if kind~='Egg' and kind~='Sperm' then return finish(s,id,false,'Unknown precursor type.') end
 local input,output,why=D.validatePair(s,id);if not input then return finish(s,id,false,why) end
 local cell=input.contents[1].cell;if cell.type~=1 or cell.sampleKind then return finish(s,id,false,'A living stem cell is required in the input container.') end
 if cell.viability<.5 then return finish(s,id,false,'Stem cell viability must exceed 50%.') end
 local h=G.gamete(cell.genome,function() return B.rand(s) end,'Cell '..cell.id,true);h.id=B.id(s);h.kind=kind;h.progress=0;h.stage='Gamete precursor';h.generation=cell.generation;h.genomeSource=G.copy(cell.genome);h.containerId=output.id;h.location='container';h.physical=true;s.gametes[#s.gametes+1]=h
 local result=G.copy(cell);result.id=B.id(s);result.sampleKind='gamete';result.gameteKind=kind;result.gameteId=h.id;result.gameteProgress=0;result.name=kind..' precursor';result.replicationCapacity=0
 output.contents={{cell=result,count=1}};consume(input)
 return finish(s,id,true,'One stem cell consumed. '..kind..' precursor in container #'..output.id..'; maturation 08:00.')
end
return W
