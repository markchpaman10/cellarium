local G=require('genome');local A=require('anatomy');local R=require('rendering');local S=require('persistence');local P=require('body_parts');local U={seed='20365841',frame=1,playing=false,speed=1,layers={External=true},selected=1,accumulator=0}
function U.generate(seed)
 U.seed=tostring(math.floor(tonumber(seed) or 20365841));U.genome=G.new(G.rng(tonumber(U.seed)));U.anatomy=A.generate(U.genome,{seed=tonumber(U.seed),nutrition=1,temperature=37,minerals=1,oxygen=1});U.frame=#U.anatomy.snapshots;U.playing=false;U.selected=1
end
function U.update(dt) if U.playing and U.anatomy then U.accumulator=U.accumulator+dt*U.speed;if U.accumulator>=.6 then U.accumulator=0;U.frame=math.min(#U.anatomy.snapshots,U.frame+1);if U.frame==#U.anatomy.snapshots then U.playing=false end end end end
function U.textinput(t) if U.editing then U.seed=(U.seed..t:gsub('%D','')):sub(1,10);return true end end
function U.keypressed(k) if not U.editing then return false end;if k=='backspace' then U.seed=U.seed:sub(1,-2) elseif k=='return' then U.generate(U.seed);U.editing=false elseif k=='escape' then U.editing=false end;return true end
function U.frameAnatomy()
 local a=U.anatomy;local f=a.snapshots[U.frame];return setmetatable({regions=f.regions,parts=f.regions,components=f.components,joints=f.joints,nerves=f.nerves,vessels=f.vessels},{__index=a})
end
function U.export(path)
 local a=U.anatomy;local value={seed=U.seed,genomeReference=G.hash(U.genome),genome=U.genome,anatomy=a,stats=require('living_stats').calculate({anatomy=a,caps=a.caps,energy=100,stamina=100,maturity=1,oxygen=1})}
 local name='anatomy-test-'..U.seed..'.lua';local payload='return '..S.encode(value);if path then local file,why=io.open(path,'wb');if not file then return nil,why end;file:write(payload);file:close();return path end;local ok,why=love.filesystem.write(name,payload);if not ok then return nil,why end;return love.filesystem.getSaveDirectory()..'/'..name
end
function U.draw(s,ui)
 if not U.anatomy then U.generate(U.seed) end
 local text,button,card=ui.text,ui.button,ui.card;local a=U.anatomy;local c=a.caps
 text('Anatomy Generator / experimental',250,88,27);text('Recorded construction playback only. Living laboratory time remains linked to your PC.',250,132,13)
 card(250,174,1140,655)
 button('Generate Random Organism',265,190,240,36,function() U.generate(math.random(1,2147483646)) end)
 button('Regenerate',515,190,120,36,function() U.generate(math.random(1,2147483646)) end)
 button('Seed: '..U.seed..(U.editing and '_' or ''),645,190,225,36,function() U.editing=true;U.seed='' end)
 button('Use seed',880,190,95,36,function() U.generate(U.seed);U.editing=false end)
 button('Save Genome',985,190,165,36,function() local E=require('genome_editor');E.begin({id=0,name='Anatomy '..U.seed,genome=U.genome});local ok,why=E.commit(s,require('biology'));require('desktop_host').message(why) end)
 button('Export',1160,190,210,36,function() local path,why=U.export();require('desktop_host').message(path or 'Export failed: '..tostring(why)) end)
 local names={'External','Skeleton','Muscle','Fat','Organs','Nervous'}
 for i,name in ipairs(names) do button(name,265+(i-1)*118,238,110,30,function() U.layers[name]=not U.layers[name] end,U.layers[name]) end
 button('Solo external',990,238,180,30,function() U.layers={External=true} end)
 button('Combined',1180,238,190,30,function() U.layers={Skeleton=true,Muscle=true,Organs=true,Nervous=true} end)
 love.graphics.setColor(.065,.11,.14);love.graphics.rectangle('fill',265,282,770,350,8)
 local scale=R.fitScale(a,710,295,4);local cx,cy=(a.bounds.minx+a.bounds.maxx)/2,(a.bounds.miny+a.bounds.maxy)/2;local x,y=650-cx*scale,450-cy*scale
 local f=U.frameAnatomy();R.draw({anatomy=f,genome=U.genome,caps=c,maturity=1,alive=true,behavior='Resting'},x,y,scale,0,U.layers,U.selected)
 ui.register(265,282,770,350,function() local mx,my=love.mouse.getPosition();mx=mx/love.graphics.getWidth()*1440;my=my/love.graphics.getHeight()*900;local px,py=(mx-x)/scale,(my-y)/scale;local best,dist
  for _,r in ipairs(f.regions) do local d=(px-r.x)^2+(py-r.y)^2;if not dist or d<dist then best=r.id;dist=d end end;U.selected=best
 end,'Inspect anatomical structure')
 text(U.frame..' / '..#a.snapshots..'   '..a.snapshots[U.frame].stage,280,605,13,{.75,.88,.84})
 button(U.playing and 'Pause playback' or 'Play playback',265,647,175,33,function() if U.frame==#a.snapshots then U.frame=1 end;U.playing=not U.playing end)
 button('Step',450,647,100,33,function() U.playing=false;U.frame=math.min(#a.snapshots,U.frame+1) end)
 button('Restart',560,647,110,33,function() U.frame=1;U.playing=false end)
 button('Playback '..U.speed..'x',680,647,160,33,function() U.speed=U.speed==4 and .5 or U.speed*2 end)
 text('BIOLOGY / '..(a.viable and 'VIABLE' or 'DEVELOPMENTAL FAILURE'),1050,290,13)
 text(string.format('%s / %d limbs / %d heads\nMass %.3f oz / muscle %.3f oz\nSupport %.3f oz / fat %.3f oz\nSkin %.3f oz\nForce %.3f / support %.2f\nCoordination %.2f / supply %.2f\n%s / stride %.2f in\nMetabolic demand %.3f\nHeart %.3f / lung %.3f\nDigestion %.3f',a.symmetry,a.appendageCount,a.headCount,c.mass,c.physicalMass.Muscle or 0,(c.physicalMass.Bone or 0)+(c.physicalMass.Support or 0)+(c.physicalMass.Carapace or 0),c.physicalMass.Fat or 0,c.physicalMass.Skin or 0,c.force,c.support,c.coordination,c.supply,c.locomotion,c.stride,c.metabolicDemand,c.organCapacity.heart,c.organCapacity.lung,c.digestion),1050,322,12)
 local stats=require('living_stats').calculate({anatomy=a,caps=c,energy=100,stamina=100,maturity=1,oxygen=1});text(string.format('Physical: STR %.2f / DEF %.2f / DEX %.2f / INT %.2f / VIT %.2f / END %.2f',stats.STR,stats.DEF,stats.DEX,stats.INT,stats.VIT,stats.END),855,661,11)
 local traits=G.express(U.genome);text(string.format('Genetic potential: STR %.2f / DEX %.2f / VIT %.2f / END %.2f',traits[2],traits[3],traits[5],traits[7]),275,698,12)
 local r=f.regions[U.selected or 1];if r then text(string.format('#%d %s / parent %s / %.2f x %.2f x %.2f in / %s',r.id,r.partType,tostring(r.parent or 'root'),r.length/32,r.width/32,r.thickness/32,r.role),275,723,12)
  local names={};local mass,force=0,0;for _,c in ipairs(a.components) do if c.regionId==r.id then mass=mass+c.mass;if c.type=='Muscle' then force=force+c.mass*c.force*c.efficiency*c.leverage*c.condition end end end;for k,v in pairs(r.tissues) do names[#names+1]=string.format('%s %.3f',k,v) end;table.sort(names);text('Genes: '..table.concat(r.geneticInfluences,', ')..' / tissue volumes (in^3): '..table.concat(names,'; '):sub(1,92),275,746,11)
  text(string.format('DEF dorsal %.3f / ventral %.3f / attachment (%.1f, %.1f, %.1f)',P.defense(a,r.id,'dorsal'),P.defense(a,r.id,'ventral'),r.attachment.x,r.attachment.y,r.attachment.z)..string.format(' / mass %.3f oz / raw force %.3f',mass,force),275,768,12)
 end
 text(table.concat(a.failures,'; '):sub(1,155),275,796,12,{.68,.25,.2})
end
return U
