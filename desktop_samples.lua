-- One sample is one counted cell equivalent, never a free copy of a live cell.
local G=require('genome');local V=require('vessels');local M=require('desktop_model');local T={}
function T.vessel(s,id) for i,v in ipairs(s.vessels or {}) do if v.id==id then return v,i end end end
function T.action(s,id,operation,...)
 local vessel,index=T.vessel(s,id);if not vessel then return false,'This container is no longer available.' end
 local fn=V[operation];if not fn then return false,'Unknown container action.' end
 return fn(s,index,...)
end
function T.equal(a,b) return a.type==b.type and require('persistence').encode(a.genome)==require('persistence').encode(b.genome) end
function T.collect(s,id,quantity)
 local pip=M.ensure(s).pipette;if pip.sample then return false,'Dispense or discard the loaded sample first.' end
 local v=T.vessel(s,id);quantity=quantity or 1
 if not v or v.frozen or v.closed then return false,'Source is closed, frozen, or unavailable.' end
 local b=v.contents[1];if not b or b.count<quantity or quantity<1 or quantity%1~=0 or quantity>pip.capacity then return false,'Insufficient accessible sample or pipette capacity.' end
 local contamination=math.max(v.contamination or 0,pip.residueContamination or 0)
 if not pip.clean and pip.residueGenome and pip.residueGenome~=G.hash(b.cell.genome) then contamination=math.min(1,contamination+.15) end
 pip.sample={sourceContainerId=id,kind='living cells',cell=G.copy(b.cell),genome=G.copy(b.cell.genome),quantity=quantity,volume=quantity*.000034,viability=b.cell.viability,contamination=contamination,temperature=v.temperature or 37,medium=v.medium}
 b.count=b.count-quantity;if b.count==0 then v.contents={};v.cultivating=false end
 pip.clean=false;pip.residueGenome=G.hash(b.cell.genome);pip.residueContamination=contamination
 return true,'Collected '..quantity..' cell equivalent. Choose a destination and dispense.'
end
function T.canDispense(s,id)
 local pip=M.ensure(s).pipette;local sample=pip.sample;if not sample then return false,'The dropper is empty.' end
 local v=T.vessel(s,id);if not v or v.frozen or v.closed then return false,'Target is closed, frozen, or unavailable.' end
 if V.count(v)+sample.quantity>V.types[v.kind].capacity then return false,'Target has insufficient capacity.' end
 if #v.contents>0 and not T.equal(v.contents[1].cell,sample.cell) then return false,'Incompatible cell categories or genomes; use a separate vessel.' end
 if v.nutrients<=.02 or (v.temperature or 37)<15 or (v.temperature or 37)>45 then return false,'Target culture conditions are unsuitable.' end
 return true
end
function T.dispense(s,id)
 local ok,why=T.canDispense(s,id);if not ok then return false,why end
 local pip=M.ensure(s).pipette;local sample=pip.sample;local v=T.vessel(s,id)
 if #v.contents==0 then v.contents={{cell=G.copy(sample.cell),count=sample.quantity}} else v.contents[1].count=v.contents[1].count+sample.quantity end
 v.contamination=math.max(v.contamination or 0,sample.contamination);v.cultureAge=v.cultureAge or 0;v.cultivating=V.types[v.kind].growth>0;pip.sample=nil
 return true,'Sample delivered. The real culture is now '..V.count(v)..' cell equivalents.'
end
function T.clean(s) local p=M.ensure(s).pipette;if p.sample then return false,'Dispense or discard the sample before sterilizing.' end;p.clean=true;p.residueGenome=nil;p.residueContamination=0;return true,'Dropper sterilized.' end
function T.seed(s,id,index)
 local v,vi=T.vessel(s,id);local c=s.cells[index or 1];if not v or not c then return false,'Select a loose cell first.' end
 if v.closed or v.frozen then return false,'Open and thaw the destination first.' end
 if #v.contents>0 and not T.equal(v.contents[1].cell,c) then return false,'Different genomes require separate vessels.' end
 return V.transfer(s,index or 1,vi,1)
end
return T
