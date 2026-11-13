local H={width=56,height=32,kinds={'land','freshwater','saltwater'}}
local function rand(seed) return function() seed=seed*48271%2147483647;return seed/2147483647 end end
function H.new(seed)
 local random=rand(seed or 76123);local h={version=1,seed=seed or 76123,cells={},temperature=22,oxygen=1,foodRate=1,environment=1,water=1,shelter=1,plants={},obstacles={}}
 local fx,fy=.25+random()*.08,.55+random()*.1;local sx,sy=.76+random()*.05,.35+random()*.13
 for y=1,H.height do for x=1,H.width do local px,py=(x-.5)/H.width,(y-.5)/H.height;local fresh=((px-fx)/.22)^2+((py-fy)/.29)^2;local salt=((px-sx)/.2)^2+((py-sy)/.32)^2;local edge=.06*math.sin(x*.7+y*.4)
  local kind,depth='land',0;if fresh<1+edge then kind='freshwater';depth=math.min(1,1-fresh) elseif salt<1+edge then kind='saltwater';depth=math.min(1,1-salt) end
  local elevation=kind=='land' and (.08+.5*(.5+.5*math.sin(px*8+py*4))) or 0;local cell={kind=kind,depth=depth,elevation=elevation,salinity=kind=='saltwater' and 1 or 0,oxygen=kind=='land' and 1 or .85-depth*.1,shelter=0,obstacle=false}
  if kind=='land' and random()<.12 then cell.shelter=.6;h.plants[#h.plants+1]={x=px,y=py,height=2+math.floor(random()*4)} end
  if kind=='land' and random()<.012 and px>.1 and px<.9 then cell.obstacle=true;h.obstacles[#h.obstacles+1]={x=px,y=py} end
  h.cells[(y-1)*H.width+x]=cell
 end end;return h
end
function H.ensure(s) if not s.habitat or not s.habitat.cells then local previous=s.habitat;s.habitat=H.new((previous and previous.seed) or 76123);if previous then s.habitat.temperature=previous.temperature or 22;s.habitat.foodRate=previous.foodRate or 1 end end;return s.habitat end
function H.sample(h,x,y,z)
 if (z or 0)>.08 then return {kind='air',depth=0,salinity=0,oxygen=.95,temperature=h.temperature-.5*(z or 0),elevation=z,shelter=0,obstacle=false} end
 local ix=math.max(1,math.min(H.width,math.floor(x*H.width)+1));local iy=math.max(1,math.min(H.height,math.floor(y*H.height)+1));return h.cells[(iy-1)*H.width+ix]
end
function H.oxygenRatio(c,cell) local wet=cell.kind=='freshwater' or cell.kind=='saltwater';return (wet and c.aquaticRespiration*(cell.oxygen or .85) or c.airRespiration*(cell.oxygen or 1))/math.max(.1,c.oxygenDemand) end
function H.compatibility(c,cell)
 if cell.kind=='air' then return c.compatibility.land end
 return c.compatibility[cell.kind] or 0
end
function H.location(h,c,target,anchor)
 anchor=anchor or {x=.5,y=.5}
 local best,bestScore,backup,backupRatio
 local function consider(x,y,cell)
  if cell.obstacle then return end
  local ratio=H.oxygenRatio(c,cell)
  local point={x=(x-.5)/H.width,y=(y-.5)/H.height}
  -- Prefer breathable locations regardless of an incompatible release preference.
  if not backupRatio or ratio>backupRatio then backupRatio=ratio;backup=point end
  if ratio<1 then return end
  local matches=not target or target=='auto' or target=='shore' and cell.kind~='land' and cell.depth<.3 or target=='ridge' and cell.kind=='land' and cell.elevation>.4 or cell.kind==target
  local distance=(point.x-anchor.x)^2+(point.y-anchor.y)^2
  local score=H.compatibility(c,cell)*2+math.min(2,ratio)*.3-distance*.45+(cell.shelter or 0)*.02+(matches and .15 or 0)
  if not bestScore or score>bestScore then bestScore=score;best=point end
 end
 for y=4,H.height-3 do for x=4,H.width-3 do consider(x,y,h.cells[(y-1)*H.width+x]) end end
 return best or backup, best~=nil
end

function H.resource(s,random,kind)
 local x,y=.05+random()*.9,.08+random()*.84;local env=H.sample(s.habitat,x,y);return {x=x,y=y,kind=kind or (env.kind=='land' and (random()<.65 and 'plant' or 'debris') or (random()<.7 and 'dissolved' or 'debris')),amount=1}
end
return H

