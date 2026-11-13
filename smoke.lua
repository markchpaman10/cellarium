package.path='./?.lua;'..package.path
local G=require('genome')
local R=require('reconstruction')
local D=require('anatomical_development')
local function check(seed)
  local g=G.new(G.rng(seed))
  local a=R.generate(g,{seed=seed,nutrition=1,temperature=37,minerals=1,oxygen=1})
  assert(a.anatomicalVersion==2,'Wrong anatomy model')
  assert(#a.regions>0 and #a.components>0,'Empty organism')
  local p=G.copy(a)
  for i=0,40 do
    local t=i/40
    D.setProgress(p,t,{fatFraction=.7})
    assert(p.growth==t,'Incorrect growth progress')
    for j,r in ipairs(p.regions) do
      assert(r.length==r.length and r.width==r.width and r.thickness==r.thickness,'NaN anatomy')
      assert(r.length>=0 and r.width>=0 and r.thickness>=0,'Negative anatomy')
      assert(not r.parent or (r.parent>=1 and r.parent<j),'Disconnected region graph')
    end
  end
  return a
end
for _,seed in ipairs({20365841,1,1001,20001,700123}) do
  local a=check(seed)
  local b=check(seed)
  assert(#a.regions==#b.regions and #a.components==#b.components,'Seed is not reproducible')
  print(string.format('PASS %d: %d regions / %d components',seed,#a.regions,#a.components))
end
print('Organism growth baseline checks passed.')
