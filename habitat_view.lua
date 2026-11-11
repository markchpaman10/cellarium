local H=require('habitat');local U=require('units');local V={}
local colors={land={.10,.16,.13},freshwater={.08,.25,.29},saltwater={.09,.18,.32}}
function V.draw(s,c)
 local text,button,panel,col=c.text,c.button,c.panel,c.col;local C,B=c.C,c.B;local habitat=H.ensure(s);panel(32,202,1015,650)
 text('ECOLOGICAL MESOCOSM / '..U.temperature(habitat.temperature),54,224,13,C.mint)
 button('Renewal '..habitat.foodRate..'x',623,217,142,30,function() habitat.foodRate=habitat.foodRate%4+1;c.msg('Resource renewal: '..habitat.foodRate..'x baseline.') end)
 button('+ Resources',777,217,116,30,function() for i=1,24 do s.food[#s.food+1]=H.resource(s,function() return B.rand(s) end) end;c.msg('Plant matter, debris and dissolved nutrients distributed by habitat.') end)
 button('Climate >',902,217,126,30,function() habitat.temperature=habitat.temperature==22 and 12 or habitat.temperature==12 and 35 or 22;c.msg('Ambient temperature: '..U.temperature(habitat.temperature)) end)
 local x,y,w,h=49,256,981,576;local tw,th=w/H.width,h/H.height
 for row=1,H.height do for column=1,H.width do local cell=habitat.cells[(row-1)*H.width+column];local color=colors[cell.kind];local shade=cell.kind=='land' and (.88+cell.elevation*.3) or 1-cell.depth*.32;col({color[1]*shade,color[2]*shade,color[3]*shade});love.graphics.rectangle('fill',x+(column-1)*tw,y+(row-1)*th,tw+1,th+1)
  if cell.kind~='land' and cell.depth<.18 then col({.32,.37,.25},.65);love.graphics.rectangle('fill',x+(column-1)*tw,y+(row-1)*th,tw+1,th+1) end
 end end
 for _,p in ipairs(habitat.plants) do local px,py=x+p.x*w,y+p.y*h;col({.22,.39,.24});love.graphics.rectangle('fill',px,py-p.height*2,2,p.height*2);love.graphics.rectangle('fill',px-3,py-4,7,2);col({.30,.48,.28});love.graphics.rectangle('fill',px-2,py-p.height*2,6,3) end
 for _,o in ipairs(habitat.obstacles) do col({.23,.26,.24});love.graphics.rectangle('fill',x+o.x*w-4,y+o.y*h-3,9,6) end
 local foodColors={plant={.58,.75,.29},debris={.68,.55,.33},dissolved={.35,.78,.7},tissue={.82,.4,.42}}
 for _,f in ipairs(s.food) do col(foodColors[f.kind or 'debris']);love.graphics.rectangle('fill',x+f.x*w-1,y+f.y*h-1,3,3) end
 for i,o in ipairs(s.organisms) do local px,py=x+o.x*w,y+o.y*h;local z=o.altitude or 0
  if z>.08 then col({.01,.02,.03},.4);love.graphics.ellipse('fill',px,py,12,4);py=py-z*65 end
  c.organism(o,px,py,1,s.time)
  if o.environment=='freshwater' or o.environment=='saltwater' then col({.4,.7,.82},.25);love.graphics.ellipse('line',px,py,23,10) end
  if c.selected==i then col(C.mint);love.graphics.circle('line',px,py,33);text('#'..o.id,px-10,py+37,11,C.mint) end
 end
 text('LAND / SHELTER',60,805,11,{.55,.72,.48});text('FRESHWATER',277,805,11,{.4,.8,.78});text('SALTWATER',475,805,11,{.44,.66,.91});text('AIRSPACE: SHADOWS MARK ALTITUDE',680,805,11,C.muted)
end
return V
