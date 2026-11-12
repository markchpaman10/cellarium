-- Original procedural equipment artwork. No retailer images or external assets.
local A={fonts={}};local V=require('vessels');local T=require('desktop_samples');local R=require('rendering');local H=require('habitat');local Units=require('units')
local function color(r,g,b,a) love.graphics.setColor(r,g,b,a or 1) end
local function label(t,x,y,size,c) if not A.fonts[size] then A.fonts[size]=love.graphics.newFont(size) end;love.graphics.setFont(A.fonts[size]);love.graphics.setColor(c or {.79,.91,.91,1});love.graphics.print(t,x,y) end
local function rect(mode,x,y,w,h,r) love.graphics.rectangle(mode,x,y,w,h,r or 0) end
local function steel(x,y,w,h,r)
 color(.04,.065,.075,.97);rect('fill',x+2,y+5,w,h,r);color(.23,.31,.33);rect('fill',x,y,w,h,r)
 for i=1,16 do local v=.14+i*.004;color(v,v+.055,v+.065);rect('fill',x+3,y+3+(i-1)*(h-6)/16,w-6,(h-6)/16+1,r and math.min(r,4) or 0) end
 color(.60,.73,.74,.7);love.graphics.setLineWidth(1);rect('line',x+.5,y+.5,w-1,h-1,r)
end
local function glass(x,y,w,h,r)
 color(.3,.55,.62,.14);rect('fill',x,y,w,h,r);color(.67,.86,.9,.72);love.graphics.setLineWidth(1.5);rect('line',x,y,w,h,r)
 color(1,1,1,.33);rect('fill',x+5,y+7,3,h-18,2);color(.8,.96,1,.15);rect('fill',x+w-9,y+11,2,h-22,1)
end
local function tag(o,title,subtitle,x,y,w)
 color(.025,.055,.065,.94);rect('fill',x,y,w,35,4);color(.48,.82,.75);rect('fill',x,y,3,35,1)
 label(title,x+9,y+4,11);label(subtitle or o.id,x+9,y+19,9,{.5,.68,.70,1})
 if o.locked then label('L',x+w-12,y+4,10,{1,.72,.35,1}) end
end
local function dish(s,o)
 local v=T.vessel(s,o.entityId);if not v then return end
 local cx,cy,r=118,112,105;local pop=V.count(v);local dirty=v.contamination or 0
 color(.015,.025,.03,.20);love.graphics.ellipse('fill',cx+2,cy+7,r+3,r+2)
 for i=100,1,-1 do local q=i/100;color(.32+q*.10,.56+q*.08,.62+q*.04,.16);love.graphics.circle('fill',cx,cy,r*q) end
 color(.82,.94,.96,.75);love.graphics.setLineWidth(2);love.graphics.circle('line',cx,cy,r)
 color(.7,.85,.9,.35);love.graphics.setLineWidth(5);love.graphics.circle('line',cx,cy,r-6)
 color(.055+dirty*.15,.19-dirty*.08,.17-dirty*.06,.78);love.graphics.circle('fill',cx,cy,r-11)
 for i=80,1,-1 do local q=i/80;color(.25+dirty*.17,.57-dirty*.25,.36-dirty*.14,.003);love.graphics.circle('fill',cx-6,cy-7,(r-13)*q) end
 if pop>0 then for i=1,math.min(42,pop*5) do local angle=i*2.39996;local rr=math.sqrt((i*17%43)/43)*74;local x,y=cx+math.cos(angle)*rr,cy+math.sin(angle)*rr;local radius=2+(i*7%4)+pop*.22
  color(.76,.83,.54,.08);love.graphics.circle('fill',x,y,radius+4);color(.80,.83,.59,.35);love.graphics.circle('fill',x,y,radius);color(.94,.92,.77,.35);love.graphics.circle('fill',x-1,y-1,radius*.4)
 end end
 if dirty>.01 then for i=1,math.ceil(dirty*12) do color(.62,.40,.21,.45);love.graphics.circle('fill',48+(i*43%130),48+(i*29%100),5+i%5) end end
 color(1,1,1,.7);love.graphics.setLineWidth(2);love.graphics.arc('line','open',cx-1,cy-1,r-2,3.55,4.75)
 if v.closed then color(.67,.9,1,.08);love.graphics.circle('fill',cx,cy,r-3);color(1,1,1,.22);love.graphics.line(64,44,157,158) end
 tag(o,v.label or ('CULTURE '..v.id),pop..' cell eq. / '..(v.closed and 'lid closed' or 'open'),40,175,156)
end
local function tube(s,o)
 local v=T.vessel(s,o.entityId);local dna
 if o.kind=='dna' then for _,m in ipairs(s.materials) do if m.id==o.entityId then dna=m end end end
 local fill=dna and .55 or (v and V.count(v)/V.types[v.kind].capacity or 0);local tint=dna and {.65,.46,.90} or o.kind=='cryovial' and {.34,.65,.94} or {.42,.81,.63}
 color(.01,.025,.04,.22);love.graphics.ellipse('fill',49,167,26,7)
 glass(25,33,44,132,21)
 if fill>0 then local height=math.max(13,fill*102);color(tint[1],tint[2],tint[3],.52);rect('fill',29,159-height,36,height,16);color(tint[1]+.1,tint[2],tint[3],.7);love.graphics.ellipse('fill',47,159-height,18,3) end
 color(.11,.15,.18);rect('fill',21,19,52,23,5);color(tint[1]*.8,tint[2]*.7,tint[3]*.8);rect('fill',22,16,50,20,4)
 for x=25,68,5 do color(.75,.84,.88,.28);love.graphics.line(x,19,x,32) end
 for i=1,5 do color(.9,.96,1,.6);love.graphics.line(55,61+i*14,64,61+i*14) end
 color(.87,.89,.84,.92);rect('fill',24,78,46,39,2);label(dna and 'DNA' or 'CELLS',29,81,10,{.16,.22,.24,1});label('#'..o.entityId,29,96,11,{.15,.25,.25,1})
 if v and v.frozen then label('FROZEN',23,145,9,{.7,.92,1,1}) end
 tag(o,(dna and 'ARCHIVE' or (v and V.count(v)..' eq.' or 'EMPTY')),dna and 'genome' or 'suspension',9,157,78)
end
local function flask(s,o)
 local v=T.vessel(s,o.entityId);local pts={59,33,91,33,94,76,137,177,132,197,18,197,13,177,56,76}
 color(.27,.53,.61,.24);love.graphics.polygon('fill',pts);color(.7,.88,.94,.8);love.graphics.setLineWidth(2);love.graphics.polygon('line',pts)
 local pop=v and V.count(v) or 0;color(.27,.65,.46,.6);love.graphics.polygon('fill',27,153,121,153,135,178,129,192,21,192,17,178)
 for i=1,pop do color(.8,.91,.57,.35);love.graphics.circle('fill',31+i*19%88,163+i*13%23,2) end
 steel(52,18,45,24,5);color(1,1,1,.5);love.graphics.line(54,82,25,176)
 tag(o,'CULTURE '..o.entityId,pop..' / 32 cell eq.',14,121,122)
end
local function plate(s,o)
 local v=T.vessel(s,o.entityId);glass(12,17,216,126,13)
 for row=0,1 do for column=0,3 do local x,y=43+column*51,49+row*51;color(.22,.5,.44,.3);love.graphics.circle('fill',x,y,21);color(.8,.92,.9,.5);love.graphics.circle('line',x,y,21) end end
 tag(o,'CULTURE PLATE '..o.entityId,(v and V.count(v) or 0)..' cell eq. / shared culture',24,110,192)
end
local function dropper(s,o)
 local p=s.desktop.pipette;color(.01,.02,.025,.25);love.graphics.ellipse('fill',47,218,14,5)
 for i=16,1,-1 do local q=i/16;color(.10+(.9-q)*.10,.25+(.9-q)*.12,.26+(.9-q)*.13);love.graphics.ellipse('fill',44,45,24*q,33*q) end
 color(.45,.65,.66,.55);love.graphics.ellipse('line',44,43,23,32);steel(29,70,30,16,3)
 glass(34,86,20,101,7);color(.7,.9,.94,.6);love.graphics.polygon('line',34,176,54,176,46,215,42,215)
 if p.sample then color(.43,.91,.65,.85);rect('fill',38,115,12,66,4);love.graphics.polygon('fill',38,176,50,176,45,205,43,205) end
 for y=100,170,12 do color(.9,.96,1,.55);love.graphics.line(46,y,51,y) end
 label(p.sample and 'LOADED' or (p.clean and 'STERILE' or 'USED'),18,222,9,p.sample and {.55,1,.7,1} or {.6,.76,.77,1})
end
local function rack(o)
 steel(8,44,302,55,9);for i=1,8 do color(.025,.04,.045);love.graphics.ellipse('fill',20+i*32,54,12,7);color(.52,.67,.69);love.graphics.ellipse('line',20+i*32,54,12,7) end
 color(.13,.22,.24);rect('fill',23,86,13,23,3);rect('fill',280,86,13,23,3);label('CELLARIUM / SAMPLE RACK',32,71,11)
end
local function instrument(s,o)
 local forge=o.kind=='forge';steel(13,44,o.w-26,o.h-59,13);steel(22,22,o.w-44,42,9)
 color(.025,.065,.068);rect('fill',34,79,116,61,7);color(.38,.87,.74);love.graphics.setLineWidth(1)
 if forge then for i=0,21 do local x=43+i*4.5;local y=109+math.sin(i*.45)*16;love.graphics.circle('fill',x,y,2);love.graphics.circle('fill',x,218-y,2);if i%2==0 then color(.35,.65,.65,.5);love.graphics.line(x,y,x,218-y);color(.38,.87,.74) end end
 else for i=1,4 do color(.37,.73,.64,.55);love.graphics.circle('fill',48+i*19,110,7);color(.65,.91,.82);love.graphics.circle('line',48+i*19,110,10) end end
 color(.045,.08,.095);love.graphics.circle('fill',195,106,26);color(.62,.76,.77);love.graphics.circle('line',195,106,24);color(.36,.84,.72);love.graphics.line(195,106,208,92)
 for i=1,5 do color(.05,.09,.11);rect('fill',171+i*10,144,4,17,1) end
 tag(o,forge and 'GENOME FORGE' or 'CELL WORKSTATION',forge and 'sequence / assemble / install' or 'culture / prepare / inspect',29,o.h-53,o.w-58)
 color(.32,.94,.63);love.graphics.circle('fill',o.w-35,43,3)
end
local envColors={land={.12,.21,.13},freshwater={.08,.28,.31},saltwater={.09,.22,.35}}
local function habitat(s,o)
 local world=require('desktop_worlds').find(s,o.entityId);if not world then return end
 local x,y,w,h=18,29,o.w-36,o.h-64;local wet=o.kind~='terrarium'
 color(.02,.035,.04,.3);rect('fill',13,27,o.w-25,o.h-36,16);steel(9,12,o.w-18,o.h-22,17)
 love.graphics.stencil(function() rect('fill',x,y,w,h,8) end,'replace',1);love.graphics.setStencilTest('greater',0)
 for row=1,H.height do for col=1,H.width do local c=world.habitat.cells[(row-1)*H.width+col];local base=envColors[c.kind] or envColors.land;local variation=.91+math.sin(col*3.3+row*4.4)*.06;color(base[1]*variation,base[2]*variation,base[3]*variation);rect('fill',x+(col-1)*w/H.width,y+(row-1)*h/H.height,w/H.width+1,h/H.height+1) end end
 for _,p in ipairs(world.habitat.plants or {}) do color(.25,.41,.21);love.graphics.ellipse('fill',x+p.x*w,y+p.y*h,5,3);love.graphics.ellipse('fill',x+p.x*w-2,y+p.y*h-2,2,5) end
 if wet then for i=1,14 do color(.55,.75,.54,.7);love.graphics.circle('fill',x+15+i*31%(w-30),y+h-12-i*7%25,2+i%3) end;for i=1,5 do color(.23,.56,.4,.65);love.graphics.line(x+20+i*11,y+h-6,x+18+i*12,y+h-42-i*4) end end
 for _,f in ipairs(world.food) do color(.71,.76,.37,.8);love.graphics.circle('fill',x+f.x*w,y+f.y*h,1.5) end
 for _,organism in ipairs(s.organisms) do if organism.worldId==world.id then local scale=R.fitScale(organism.anatomy,65,55,.8);R.drawTopDown(organism,x+organism.x*w,y+organism.y*h,scale,s.time);if organism.id==s.desktop.selectedOrganism then color(.65,1,.83,.8);love.graphics.circle('line',x+organism.x*w,y+organism.y*h,23) end end end
 if wet then color(.66,.88,.96,.10);for i=1,5 do love.graphics.arc('line','open',x+w*.5,y+h*.6,20+i*27,3.6,4.6) end end
 love.graphics.setStencilTest();glass(x-2,y-2,w+4,h+4,9)
 if o.kind=='terrarium' then for i=1,18 do color(.04,.09,.09);rect('fill',31+i*19,17,10,3,1) end end
 local title=o.kind=='terrarium' and 'TERRESTRIAL MESOCOSM' or o.kind=='freshwater' and 'FRESHWATER' or 'SALTWATER'
 label(title,23,o.h-27,11);label(Units.temperature(world.habitat.temperature)..' / '..require('desktop_worlds').population(s,world.id)..' living',o.w-152,o.h-27,10,{.6,.8,.8,1})
end
function A.draw(s,o)
 if require('desktop_controls').draw(s,o) then return end
 love.graphics.setLineWidth(1);if o.kind=='dish' then dish(s,o) elseif o.kind=='vial' or o.kind=='cryovial' or o.kind=='dna' then tube(s,o) elseif o.kind=='flask' then flask(s,o) elseif o.kind=='plate' then plate(s,o) elseif o.kind=='dropper' then dropper(s,o) elseif o.kind=='rack' then rack(o) elseif o.kind=='forge' or o.kind=='workstation' then instrument(s,o) elseif o.kind=='organism' then local organism;for _,v in ipairs(s.organisms) do if v.id==o.entityId then organism=v end end;if organism then R.drawTopDown(organism,o.w/2,o.h/2,R.fitScale(organism.anatomy,125,120,1),s.time) end else habitat(s,o) end
 if s.desktop.animation and s.desktop.animation.target==o.id then local p=s.desktop.animation.progress;local x,y=o.w/2,20+p*p*(o.h*.45-20);color(.49,.95,.73,.9);love.graphics.ellipse('fill',x,y,4,6);love.graphics.polygon('fill',x-3,y-3,x+3,y-3,x,y-11);color(.91,1,.94,.8);love.graphics.circle('fill',x-1,y-2,1.2) end
 if s.desktop.selectedObject==o.id then color(.52,1,.79,.7);love.graphics.setLineWidth(1);love.graphics.arc('line','open',o.w/2,o.h/2,math.min(o.w,o.h)*.46,4.3,5.1) end
end
function A.render(s,o,factor,canvas)
 local w,h=math.floor(o.w*factor+.5),math.floor(o.h*factor+.5)
 if not canvas or canvas:getWidth()~=w or canvas:getHeight()~=h then canvas=love.graphics.newCanvas(w,h,{format='rgba8',dpiscale=1}) end
 love.graphics.push('all');love.graphics.setCanvas({canvas,stencil=true});love.graphics.clear(0,0,0,0);love.graphics.origin();love.graphics.scale(factor);love.graphics.setBlendMode('alpha','alphamultiply');A.draw(s,o);love.graphics.setCanvas();love.graphics.pop();return canvas,canvas:newImageData()
end
return A
