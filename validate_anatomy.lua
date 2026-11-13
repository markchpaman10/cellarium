-- Run from repository root: lua validate_anatomy.lua
-- Read-only validation; does not alter the developmental model.
package.path='./?.lua;'..package.path
local G=require('genome')
local R=require('reconstruction')
local D=require('anatomical_development')
local stages={0,.25,.5,.75,1}
local samples={427617155,139300861,151974243,1240970924,20365841}
for i=1,100 do samples[#samples+1]=i*19739+101 end
local strategies={}
local failures={}
local function finite(x) return type(x)=='number' and x==x and x~=math.huge and x~=-math.huge end
local function validate(seed)
 local function make()
  return R.generate(G.new(G.rng(seed)),{seed=seed,nutrition=1,temperature=37,minerals=1,oxygen=1})
 end
 local a=make()
 local b=make()
 assert(a.supportStrategy==b.supportStrategy and #a.regions==#b.regions and #a.components==#b.components,'non-deterministic anatomy')
 strategies[a.supportStrategy]=(strategies[a.supportStrategy] or 0)+1
 local expected={['articulated endoskeleton']='Bone',['segmented exoskeleton']='Carapace',['hydrostatic axial framework']='Support'}
 local support=expected[a.supportStrategy]
 assert(support,'unknown support strategy')
 local count=0
 for _,c in ipairs(a.components) do
  assert(c.id and a.components[c.id]==c,'invalid component id')
  assert(c.regionId and a.regions[c.regionId],'component missing host region')
  assert(finite(c.volume) and c.volume>=0,'invalid component volume')
  if c.parent then assert(a.components[c.parent],'missing parent component') end
  if c.type==support then
   count=count+1
   assert(c.path and #c.path>=2,'support missing drawable path')
   for _,p in ipairs(c.path) do
    assert(finite(p.x) and finite(p.y) and finite(p.z),'invalid support geometry')
   end
  end
 end
 assert(count>0,'organism has no genetic support structures')
 for _,r in ipairs(a.regions) do
  assert(finite(r.cx) and finite(r.cy) and finite(r.cz),'invalid region position')
  if r.parent then assert(a.regions[r.parent],'invalid region parent') end
 end
 for _,j in ipairs(a.joints) do
  assert(a.components[j.parent] and a.components[j.child],'orphaned joint')
 end
 for _,n in ipairs(a.nerves) do
  assert(a.components[n.from] and a.components[n.to],'orphaned nerve')
 end
 local p=G.copy(a)
 for _,t in ipairs(stages) do
  D.setProgress(p,t,{fatFraction=.7})
  assert(p.growth==t,'growth stage mismatch')
  for _,r in ipairs(p.regions) do
   assert(finite(r.length) and finite(r.width) and finite(r.thickness),'nonfinite growing region')
   assert(r.length>=0 and r.width>=0 and r.thickness>=0,'negative growing region')
  end
  for _,c in ipairs(p.components) do
   assert(finite(c.volume) and c.volume>=0,'invalid growing component volume')
   if c.type==support then
    for _,pt in ipairs(c.path or {}) do
     assert(finite(pt.x) and finite(pt.y) and finite(pt.z),'invalid growing support path')
    end
   end
  end
 end
end
for _,seed in ipairs(samples) do
 local ok,err=pcall(validate,seed)
 if not ok then failures[#failures+1]={seed=seed,error=tostring(err)} end
end
print('Validated '..#samples..' seeds across '..#stages..' stages each')
for strategy,count in pairs(strategies) do print(strategy..': '..count) end
for _,f in ipairs(failures) do print('FAIL seed '..f.seed..': '..f.error) end
assert(#failures==0,#failures..' anatomy validation failures')
print('PASS: anatomy integrity checks')
