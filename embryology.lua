-- Deterministic early embryology. Individual cells are tracked through cleavage;
-- later development uses aggregated tissue populations to bound simulation cost.
local E={}
local tau=math.pi*2
local function clamp(x) return math.max(0,math.min(1,x)) end
local function smooth(x) x=clamp(x);return x*x*(3-2*x) end
local function noise(seed,id,k)
 local n=math.sin(seed*.000013+id*12.9898+k*78.233)*43758.5453
 return n-math.floor(n)
end
function E.evaluate(seed,t)
 t=clamp(t)
 local result={stage='Single cell',cells={},populations={},cellCount=1,individual=true,progress=t}
 local cleavageEnd=.16
 local divisions=math.min(9,math.floor(t/cleavageEnd*9))
 local phase=(t/cleavageEnd*9)-divisions
 if t<cleavageEnd then
  local n=2^divisions
  result.cellCount=n
  result.stage=n==1 and 'Zygote' or n<16 and 'Cleavage' or 'Morula'
  -- Each generation inherits a deterministic parent position and separates
  -- continuously. This is a simple spatial cleavage model, not a molecular solver.
  local spread=2.2+math.log(n+1)*2.6
  for i=1,n do
   local angle=tau*(i*.61803398875+noise(seed,i,1)*.10)
   local radius=math.sqrt((i-.5)/n)*spread
   local x=math.cos(angle)*radius
   local y=math.sin(angle)*radius
   local d=smooth(phase)
   local delta=(d-.5)*1.7
   local a=angle+math.pi/2
   local size=math.max(.75,2.4/math.sqrt(1+math.log(n)))
   result.cells[#result.cells+1]={id=i,x=x+math.cos(a)*delta,y=y+math.sin(a)*delta,r=size,
      lineage=(i%4)+1,dividing=d>.08 and d<.92}
  end
  return result
 end
 result.individual=false
 local u=clamp((t-cleavageEnd)/(.40-cleavageEnd))
 local populationCount=math.floor(512*2^(math.min(19,(t-cleavageEnd)*21)))
 result.cellCount=populationCount
 if t<.25 then result.stage='Gastrulation'
 elseif t<.40 then result.stage='Tissue differentiation'
 elseif t<.68 then result.stage='Organogenesis and appendage growth'
 elseif t<.85 then result.stage='Juvenile maturation'
 else result.stage='Adult maturation' end
 local names={'ectoderm','mesoderm','endoderm','neural','skeletal','muscular','adipose'}
 local shares={.22,.28,.20,.09,.09,.09,.03}
 for i,name in ipairs(names) do
  local weight=shares[i]
  local activity=i<=3 and 1 or smooth((u-(i-3)*.09)*4)
  result.populations[#result.populations+1]={name=name,count=math.floor(populationCount*weight*activity),fraction=weight*activity}
 end
 return result
end
function E.draw(state,x,y,zoom)
 if not state then return end
 love.graphics.push('all');love.graphics.translate(x,y);love.graphics.scale(zoom)
 if state.individual then
  local colors={{.48,.83,.78},{.67,.77,.94},{.81,.63,.79},{.78,.87,.62}}
  for _,c in ipairs(state.cells) do
   local col=colors[c.lineage]
   love.graphics.setColor(col[1]*.4,col[2]*.4,col[3]*.4,.95)
   love.graphics.circle('fill',c.x,c.y,c.r*1.2)
   love.graphics.setColor(col[1],col[2],col[3],.95)
   love.graphics.circle('fill',c.x,c.y,c.r)
   love.graphics.setColor(.23,.32,.45,.8)
   love.graphics.circle('fill',c.x,c.y,c.r*.31)
   if c.dividing then
    love.graphics.setColor(.95,.94,.91,.55)
    love.graphics.line(c.x-c.r*.45,c.y,c.x+c.r*.45,c.y)
   end
  end
 else
  -- An early tissue mass, before the anatomical scaffold becomes visible.
  local u=smooth((state.progress-.16)/.10)
  if u<1 then
   love.graphics.setColor(.46,.74,.71,(1-u)*.85)
   love.graphics.ellipse('fill',0,0,7+u*7,6+u*3)
   love.graphics.setColor(.75,.86,.83,(1-u)*.7)
   love.graphics.ellipse('line',0,0,7+u*7,6+u*3)
  end
 end
 love.graphics.pop()
end
return E
