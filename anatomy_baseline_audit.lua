local G=require('genome');local A=require('anatomy');local S=require('persistence');local Audit={}
function Audit.run()
 local result={seed=20261112,count=100,viable=0,failures=0,errors=0,symmetry={},appendages={},heads=0,configurations={},mass={min=math.huge,max=0},samples={}}
 for i=1,100 do local seed=(20261112+i*104729)%2147483647;local g=G.new(G.rng(seed));local ok,a=pcall(A.procedural,g,{nutrition=1,minerals=1,oxygen=1,temperature=37})
  if not ok then result.errors=result.errors+1;result.samples[#result.samples+1]={seed=seed,error=tostring(a)}
  else
   result.viable=result.viable+(a.viable and 1 or 0);result.failures=result.failures+(a.viable and 0 or 1)
   result.symmetry[a.symmetry]=(result.symmetry[a.symmetry] or 0)+1;local count=a.appendageCount or 0;result.appendages[count]=(result.appendages[count] or 0)+1
   local signature=a.symmetry..'/'..#a.regions..'/'..count..'/'..a.caps.locomotion;result.configurations[signature]=true
   result.mass.min=math.min(result.mass.min,a.caps.mass);result.mass.max=math.max(result.mass.max,a.caps.mass)
   result.samples[#result.samples+1]={seed=seed,viable=a.viable,symmetry=a.symmetry,regions=#a.regions,appendages=count,locomotion=a.caps.locomotion,mass=a.caps.mass,failures=a.failures}
  end
 end
 local lines={'# Before-change anatomy audit','','100 unfiltered G.new genomes. Seeds: (20261112 + i * 104729) mod 2147483647, i=1..100. Existing default generator, standard conditions.','',string.format('Viable: %d; biological failures: %d; technical errors: %d.',result.viable,result.failures,result.errors),'','Symmetry: '..S.encode(result.symmetry),'Appendage counts: '..S.encode(result.appendages),'Mass range: '..result.mass.min..'–'..result.mass.max,'','Explicit head-bearing structures: 0. The generator has no head/jaw/neck part taxonomy. Sensors alone are not counted as heads.'}
 local root=love.filesystem.getSource();local f=assert(io.open(root..'/docs/ANATOMY_BASELINE.md','w'));f:write(table.concat(lines,'\n'));f:close();f=assert(io.open(root..'/anatomy-baseline-data.lua','w'));f:write('return '..S.encode(result));f:close();return table.concat(lines,'\n')
end
return Audit
