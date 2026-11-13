-- Cellarium Organism Growth Lab
-- Standalone LÖVE application extracted from desktop-laboratory-dev.
-- Uses the original canonical genome, anatomical generator and growth model.
local Genome = require('genome')
local Build = require('reconstruction')
local Develop = require('anatomical_development')
local Render = require('reconstruction_rendering')
local Embryology = require('embryology')

local WIDTH, HEIGHT = 1360, 860
local seed, genome, adult, embryo = 20365841, nil, nil, nil
local progress, speed, playing = 0, 1, false
local layer, selected = 'External', nil
local changingSeed, seedText = false, ''
local status = 'Ready'
local dirty, images = true, {}
local viewZoom={side=1,top=1}
local cellState = nil
local buttons = {}
local palette = {
  background={.035,.055,.070}, panel={.070,.102,.123},
  border={.17,.26,.29}, ink={.85,.92,.92}, muted={.52,.66,.67},
  accent={.28,.89,.68}, highlight={.15,.28,.28}
}
local font, small, heading
local layerNames={'External','Skeleton','Muscle','Fat','Organs','Nervous'}
local formats={}

local function color(c,alpha)
  love.graphics.setColor(c[1],c[2],c[3],alpha or 1)
end
local function printText(value,x,y,fontSize,c)
  color(c or palette.ink)
  love.graphics.setFont(fontSize or font)
  love.graphics.print(tostring(value),x,y)
end
local function panel(x,y,w,h)
  color(palette.panel); love.graphics.rectangle('fill',x,y,w,h,8,8)
  color(palette.border); love.graphics.rectangle('line',x,y,w,h,8,8)
end
local function button(label,x,y,w,h,action,active)
  buttons[#buttons+1]={x=x,y=y,w=w,h=h,action=action}
  color(active and palette.accent or palette.highlight)
  love.graphics.rectangle('fill',x,y,w,h,6,6)
  color(palette.border); love.graphics.rectangle('line',x,y,w,h,6,6)
  color(active and palette.background or palette.ink)
  love.graphics.setFont(small)
  love.graphics.printf(label,x,y+(h-15)/2,w,'center')
end
local function setProgress(nextProgress)
  if not embryo then return end
  progress=math.max(0,math.min(1,nextProgress))
  Develop.setProgress(embryo,progress,{fatFraction=.7})
  cellState=Embryology.evaluate(seed,progress)
  dirty=true
end
local function generate(nextSeed)
  local newSeed=math.max(1,math.floor(tonumber(nextSeed) or seed))
  local ok, result=pcall(function()
    local g=Genome.new(Genome.rng(newSeed))
    local a=Build.generate(g,{seed=newSeed,nutrition=1,temperature=37,minerals=1,oxygen=1})
    local developmental=Genome.copy(a)
    Develop.setProgress(developmental,0,{fatFraction=.7})
    return {genome=g,adult=a,embryo=developmental}
  end)
  if not ok then status='Generation failed: '..tostring(result);return end
  seed=newSeed;genome=result.genome;adult=result.adult;embryo=result.embryo
  progress=0;playing=false;selected=nil;dirty=true
  cellState=Embryology.evaluate(seed,0)
  status='New cell generated from seed '..seed
end
local function bounds(top)
  local minx,maxx,miny,maxy=math.huge,-math.huge,math.huge,-math.huge
  for _,r in ipairs(adult.regions) do
    local x=r.cx or r.x or 0
    local y=top and (r.cy or 0) or -(r.cz or 0)
    local halfx=(r.length or 1)*.60
    local halfy=(top and r.width or r.thickness or 1)*.65
    minx=math.min(minx,x-halfx);maxx=math.max(maxx,x+halfx)
    miny=math.min(miny,y-halfy);maxy=math.max(maxy,y+halfy)
  end
  if minx==math.huge then return 0,0,100,100 end
  return minx,miny,maxx,maxy
end
local function viewTransform(top,w,h)
  local ax,ay,bx,by=bounds(top)
  local fit=math.min((w-65)/math.max(1,bx-ax),(h-65)/math.max(1,by-ay),5)
  local zoom=fit*(top and viewZoom.top or viewZoom.side)
  return w*.5-(ax+bx)*.5*zoom,h*.5-(ay+by)*.5*zoom,zoom
end
local function renderCanvas(top,w,h)
  local canvas=love.graphics.newCanvas(w,h)
  love.graphics.push('all')
  love.graphics.setCanvas(canvas)
  love.graphics.clear(.047,.074,.088,1)
  color({.09,.16,.18});love.graphics.setLineWidth(1)
  love.graphics.line(w/2,0,w/2,h)
  love.graphics.line(0,h/2,w,h/2)
  if embryo then
    local x,y,zoom=viewTransform(top,w,h)
    if cellState and (cellState.individual or progress<.23) then
      Embryology.draw(cellState,w*.5,h*.5,math.min(w,h)/38)
    else
    local ok,err=pcall(Render.draw,
      {anatomy=embryo,genome=genome,alive=true,behavior='Resting',angle=0},
      x,y,zoom,0,layer,selected,top)
    if not ok then
      status='Render error: '..tostring(err)
      color({.95,.45,.41}); love.graphics.print('Render error, see status below',15,15)
    end
    end
  end
  love.graphics.setCanvas()
  love.graphics.pop()
  return canvas
end
local function refreshViews()
  if not dirty then return end
  images.side=renderCanvas(false,850,510)
  images.top=renderCanvas(true,445,510)
  dirty=false
end
local function selectPart(mx,my,top,w,h)
  if not embryo then return end
  local x,y,z=viewTransform(top,w,h)
  local px,py=(mx-x)/z,(my-y)/z
  local best,nearest=nil,math.huge
  for _,r in ipairs(embryo.regions) do
    if (r.growth or 0)>.01 then
      local dx=px-(r.cx or 0)
      local dy=py-(top and (r.cy or 0) or -(r.cz or 0))
      local d=dx*dx+dy*dy
      if d<nearest then nearest=d;best=r end
    end
  end
  selected=best and best.id or nil;dirty=true
end

function love.load()
  love.graphics.setDefaultFilter('linear','linear')
  font=love.graphics.newFont(17);small=love.graphics.newFont(14);heading=love.graphics.newFont(26)
  math.randomseed(os.time())
  generate(seed)
end
function love.update(dt)
  if playing then
    setProgress(progress+dt*speed/24)
    if progress>=1 then playing=false end
  end
end
function love.draw()
  local dw,dh=love.graphics.getDimensions()
  love.graphics.push()
  love.graphics.scale(dw/WIDTH,dh/HEIGHT)
  color(palette.background);love.graphics.rectangle('fill',0,0,WIDTH,HEIGHT)
  buttons={}
  printText('CELLARIUM  /  ORGANISM GROWTH LAB',20,16,heading)
  printText('Isolated experiment: genome -> cell -> body formation',20,52,small,palette.muted)
  button('Random organism',20,78,165,35,function()generate(math.random(1,2147483646))end)
  button('Same seed',194,78,110,35,function()generate(seed)end)
  button(changingSeed and 'Seed: '..seedText..'_' or 'Seed: '..seed,314,78,206,35,
    function()changingSeed=true;seedText=''end,changingSeed)
  button(playing and 'Pause' or 'Play growth',530,78,135,35,
    function()playing=not playing;if progress>=1 then setProgress(0)end end,playing)
  button('Step back',674,78,112,35,function()playing=false;setProgress(progress-.025)end)
  button('Step forward',795,78,120,35,function()playing=false;setProgress(progress+.025)end)
  button('Speed '..speed..'x',924,78,115,35,function()speed=speed==4 and .5 or speed*2 end)
  button('Start: cell',1048,78,133,35,function()playing=false;setProgress(0)end)
  button('Adult',1190,78,150,35,function()playing=false;setProgress(1)end)
  panel(20,126,850,550); panel(885,126,455,550)
  printText('SIDE VIEW',33,136,small,palette.muted)
  printText('TOP VIEW',897,136,small,palette.muted)
  refreshViews()
  if images.side then love.graphics.setColor(1,1,1);love.graphics.draw(images.side,25,159) end
  if images.top then love.graphics.setColor(1,1,1);love.graphics.draw(images.top,890,159) end
  local active=0
  for _,r in ipairs(embryo and embryo.regions or {}) do
    if (r.growth or 0)>.01 then active=active+1 end
  end
  local stage=progress<.025 and 'Single cell / early precursor'
    or progress<.12 and 'Axis establishment'
    or progress<.30 and 'Initial buds and regional differentiation'
    or progress<.60 and 'Developing appendages and organs'
    or progress<.90 and 'Growth and tissue maturation'
    or 'Mature anatomy'
  printText('DEVELOPMENT  '..string.format('%5.1f%%',progress*100)..'     '..stage,20,689,font)
  printText('Genome seed '..seed..'   /   '..active..' active of '..(adult and #adult.regions or 0)..' anatomical regions',20,718,small,palette.muted)
  if layer=='Skeleton' and embryo then
    local strategy=embryo.supportStrategy or 'unknown support'
    local label=strategy=='articulated endoskeleton' and 'Endoskeleton: internal bones'
      or strategy=='segmented exoskeleton' and 'Exoskeleton: segmented armor'
      or strategy=='hydrostatic axial framework' and 'Hydrostatic: flexible support'
      or 'Support: '..tostring(strategy)
    printText(label,33,166,small,palette.accent)
  end
  if cellState then printText(cellState.stage..'  |  cells: '..cellState.cellCount..'  |  '..(cellState.individual and 'individual cells' or 'tissue populations'),640,689,small,palette.accent) end
  if selected and embryo and embryo.regions[selected] then
    local r=embryo.regions[selected]
    printText('Selected # '..r.id..'  '..r.partType..'  |  growth '..string.format('%.1f%%',(r.growth or 0)*100),760,718,small,palette.muted)
  end
  color(palette.border);love.graphics.rectangle('fill',20,755,1320,14,7,7)
  color(palette.accent);love.graphics.rectangle('fill',20,755,1320*progress,14,7,7)
  printText('Click timeline to examine every stage. Click body region to inspect.',20,778,small,palette.muted)
  local x=20
  for _,name in ipairs(layerNames) do
    button(name,x,807,160,35,function()layer=name;dirty=true end,layer==name)
    x=x+170
  end
  button('Play / pause: Space',1050,807,290,35,function()playing=not playing end)
  printText(status:sub(1,150),1060,689,small,palette.muted)
  love.graphics.pop()
end
-- Zoom the panel under the pointer. Each anatomical view retains its own
-- magnification, and selection uses the same viewTransform.
function love.wheelmoved(dx,dy)
  if dy==0 then return end
  local mx,my=love.mouse.getPosition()
  local w,h=love.graphics.getDimensions()
  if w<=0 or h<=0 then return end
  mx=mx/w*WIDTH;my=my/h*HEIGHT
  local key
  if mx>=25 and mx<=875 and my>=159 and my<=669 then key='side'
  elseif mx>=890 and mx<=1335 and my>=159 and my<=669 then key='top'
  else return end
  viewZoom[key]=math.max(.2,math.min(12,viewZoom[key]*1.15^dy))
  dirty=true
end
function love.mousepressed(x,y,mouseButton)
  if mouseButton~=1 then return end
  local w,h=love.graphics.getDimensions();x=x/w*WIDTH;y=y/h*HEIGHT
  for _,b in ipairs(buttons) do
    if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then b.action();return end
  end
  if y>=755 and y<=770 then playing=false;setProgress((x-20)/1320);return end
  if x>=25 and x<=875 and y>=159 and y<=669 then selectPart(x-25,y-159,false,850,510)
  elseif x>=890 and x<=1335 and y>=159 and y<=669 then selectPart(x-890,y-159,true,445,510) end
end
function love.textinput(t)
  if changingSeed then seedText=seedText..t:gsub('[^0-9]','');seedText=seedText:sub(1,10) end
end
function love.keypressed(key)
  if changingSeed then
    if key=='return' then changingSeed=false;generate(tonumber(seedText) or seed)
    elseif key=='escape' then changingSeed=false
    elseif key=='backspace' then seedText=seedText:sub(1,-2) end
    return
  end
  if key=='space' then playing=not playing
  elseif key=='right' then playing=false;setProgress(progress+.025)
  elseif key=='left' then playing=false;setProgress(progress-.025)
  elseif key=='home' then playing=false;setProgress(0)
  elseif key=='end' then playing=false;setProgress(1)
  elseif key=='n' then generate(math.random(1,2147483646))
  elseif key=='r' then generate(seed)
  elseif key=='s' then changingSeed=true;seedText=''
  elseif key>='1' and key<='6' then layer=layerNames[tonumber(key)];dirty=true
  end
end
