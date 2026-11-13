local G=require('genome');local A=require('anatomy');local R=require('rendering');local S=require('persistence');local P=require('body_parts');local U={seed='20365841',frame=1,playing=false,speed=1,layers={External=true},selected=1,accumulator=0}
function U.generate(seed)
 U.seed=tostring(math.floor(tonumber(seed) or 20365841));U.genome=G.new(G.rng(tonumber(U.seed)));U.anatomy=A.generate(U.genome,{seed=tonumber(U.seed),nutrition=1,temperature=37,minerals=1,oxygen=1});if U.anatomy.anatomicalVersion==2 then U.anatomy.snapshots=require('anatomical_development').record(U.anatomy,120);U.preview=G.copy(U.anatomy) end;U.frame=#U.anatomy.snapshots;U.playhead=1;U.playing=false;U.selected=1;U.component=nil;U.lastProgress=nil;U.animation=nil;U.animationTime=0;U.animationPaused=false
end
function U.update(dt) if U.animation and not U.animationPaused then U.animationTime=(U.animationTime or 0)+math.max(0,dt) end;if U.playing and U.anatomy then U.playhead=math.min(1,(U.playhead or 0)+math.max(0,dt)*U.speed/18);U.frame=math.min(#U.anatomy.snapshots,math.floor(U.playhead*(#U.anatomy.snapshots-1))+1);if U.playhead>=1 then U.playing=false end end end
function U.textinput(t) if U.editing then U.seed=(U.seed..t:gsub('%D','')):sub(1,10);return true end end
function U.keypressed(k) if not U.editing then return false end;if k=='backspace' then U.seed=U.seed:sub(1,-2) elseif k=='return' then U.generate(U.seed);U.editing=false elseif k=='escape' then U.editing=false end;return true end
function U.frameAnatomy()
 local a=U.anatomy;if a.anatomicalVersion==2 then local progress=U.playing and U.playhead or (U.frame-1)/(#a.snapshots-1);if U.lastProgress~=progress then require('anatomical_development').setProgress(U.preview,progress,{fatFraction=.7});U.preview.caps=A.capabilities(U.preview,U.genome);U.lastProgress=progress end;return U.preview end;local f=a.snapshots[U.frame];return setmetatable({regions=f.regions,parts=f.regions,components=f.components,joints=f.joints,nerves=f.nerves,vessels=f.vessels},{__index=a})
end
function U.export(path)
 local a=U.anatomy;local current=U.frameAnatomy();local value={currentProgress=current.growth,currentAnatomy=current,recordedTrajectory=a.snapshots,seed=U.seed,genomeReference=G.hash(U.genome),genome=U.genome,anatomy=a,stats=require('living_stats').calculate({anatomy=a,caps=a.caps,energy=100,stamina=100,maturity=1,oxygen=1})}
 local name='anatomy-test-'..U.seed..'.lua';local payload='return '..S.encode(value);if path then local file,why=io.open(path,'wb');if not file then return nil,why end;file:write(payload);file:close();return path end;local ok,why=love.filesystem.write(name,payload);if not ok then return nil,why end;return love.filesystem.getSaveDirectory()..'/'..name
end
function U.draw(s,ui)
 if not U.anatomy then U.generate(U.seed) end
 local text,button,card=ui.text,ui.button,ui.card;local a=U.anatomy;local f=U.frameAnatomy();local c=f.caps
 text('Anatomy Generator / experimental',250,88,27);text('Continuous biological development playback. Living laboratory time remains linked to your PC.',250,132,13)
 card(250,174,1140,655)
 button('Generate Random Organism',265,190,240,36,function() U.generate(math.random(1,2147483646)) end)
 button('Regenerate',515,190,120,36,function() U.generate(math.random(1,2147483646)) end)
 button('Seed: '..U.seed..(U.editing and '_' or ''),645,190,225,36,function() U.editing=true;U.seed='' end)
 button('Use seed',880,190,95,36,function() U.generate(U.seed);U.editing=false end)
 button('Save Genome',985,190,165,36,function() local E=require('genome_editor');E.begin({id=0,name='Anatomy '..U.seed,genome=U.genome});local ok,why=E.commit(s,require('biology'));require('desktop_host').message(why) end)
 button('Export',1160,190,210,36,function() local path,why=U.export();require('desktop_host').message(path or 'Export failed: '..tostring(why)) end)
 local names={'External','Skeleton','Muscle','Fat','Organs','Nervous'}
 for i,name in ipairs(names) do button(name,265+(i-1)*118,238,110,30,function() U.layers[name]=not U.layers[name] end,U.layers[name]) end
 button('External',990,238,88,30,function() U.layers={External=true} end)
 button('Combined',1180,238,90,30,function() U.layers={Skeleton=true,Muscle=true,Organs=true,Nervous=true} end)
 button('Motion',1084,238,86,30,function() U.showMotion=not U.showMotion end,U.showMotion)
 button(U.top and 'Top' or 'Side',1280,238,90,30,function() U.top=not U.top end,U.top)
 love.graphics.setColor(.065,.11,.14);love.graphics.rectangle('fill',265,282,770,350,8)
 local scale=R.fitScale(a,710,295,4);local cx,cy=(a.bounds.minx+a.bounds.maxx)/2,(a.bounds.miny+a.bounds.maxy)/2;local x,y=650-cx*scale,450-cy*scale
 local animationTime=U.animationTime or 0;if U.animation=='Walking' then local p=c.locomotionProfile;animationTime=animationTime*p.speed*require('locomotion').worldInches/math.max(.0001,p.stride/p.duty) end
 R.draw({anatomy=f,genome=U.genome,caps=c,maturity=1,alive=true,behavior='Resting',animation=U.animation,condition={energy=1,oxygen=1,fatigue=0}},x,y,scale,animationTime,U.layers,U.selected,U.top)
 ui.register(265,282,770,350,function() local mx,my=love.mouse.getPosition();mx=mx/love.graphics.getWidth()*1440;my=my/love.graphics.getHeight()*900;local px,py=(mx-x)/scale,(my-y)/scale;local best,dist
  for _,r in ipairs(f.regions) do local d=(px-r.x)^2+(py-(U.top and r.cy or r.y))^2;if not dist or d<dist then best=r.id;dist=d end end;U.selected=best;U.component=nil;local nearest;for _,c in ipairs(f.components) do local d=(px-c.x)^2+(py-(U.top and c.cy or c.y))^2;if not nearest or d<nearest then nearest=d;U.component=c.id;U.selected=c.regionId end end
 end,'Inspect anatomical structure')
 love.graphics.setColor(.22,.35,.38);love.graphics.rectangle('fill',280,624,740,3);love.graphics.setColor(.3,.85,.67);love.graphics.rectangle('fill',280,624,740*(f.growth or 1),3)
 ui.register(280,618,740,14,function() local mx=love.mouse.getX()/love.graphics.getWidth()*1440;U.playhead=math.max(0,math.min(1,(mx-280)/740));U.frame=math.floor(U.playhead*(#a.snapshots-1))+1;U.playing=false end,'Seek biological timeline')
 text(U.frame..' / '..#a.snapshots..'   '..a.snapshots[U.frame].stage,280,605,13,{.75,.88,.84})
 button(U.playing and 'Pause playback' or 'Play playback',265,647,175,33,function() if U.frame==#a.snapshots then U.frame=1;U.playhead=0 end;U.playhead=(U.frame-1)/(#a.snapshots-1);U.playing=not U.playing end)
 button('Step',450,647,100,33,function() U.playing=false;U.frame=math.min(#a.snapshots,U.frame+1);U.playhead=(U.frame-1)/(#a.snapshots-1) end)
 button('Restart',560,647,110,33,function() U.frame=1;U.playhead=0;U.playing=false end)
 button('Playback '..U.speed..'x',680,647,160,33,function() U.speed=U.speed==4 and .5 or U.speed*2 end)
 text('BIOLOGY / '..(f.growth and f.growth<1 and 'GROWING / ' or '')..(a.viable and 'VIABLE' or 'DEVELOPMENTAL FAILURE'),1050,290,13)
 text(string.format('%s / %d limbs / %d heads\nMass %.3f oz / muscle %.3f oz\nSupport %.3f oz / fat %.3f oz\nSkin %.3f oz\nForce %.3f / support %.2f\nCoordination %.2f / supply %.2f\n%s / stride %.2f in\nMetabolic demand %.3f\nHeart %.3f / lung %.3f\nDigestion %.3f',a.symmetry,a.appendageCount,a.headCount,c.mass,c.physicalMass.Muscle or 0,(c.physicalMass.Bone or 0)+(c.physicalMass.Support or 0)+(c.physicalMass.Carapace or 0),c.physicalMass.Fat or 0,c.physicalMass.Skin or 0,c.force,c.support,c.coordination,c.supply,c.locomotion,c.stride,c.metabolicDemand,c.organCapacity.heart,c.organCapacity.lung,c.digestion),1050,322,12)
 local detail=f.components[U.component or (f.regions[U.selected or 1] or f.regions[1]).structure];if detail then text(('#'..detail.id..' '..(detail.anatomicalName or detail.type)):sub(1,45),1050,538,12);text(string.format('Mass %.4f oz / density %.3f oz/in^3',detail.mass,detail.density),1050,558,11);text(string.format('Growth %.1f%% / capacity %.4f',detail.growth*100,detail.capacity or 0),1050,577,11);button('< Structure',1050,595,145,27,function() U.component=math.max(1,(U.component or detail.id)-1);U.selected=f.components[U.component].regionId end);button('Structure >',1205,595,165,27,function() U.component=math.min(#f.components,(U.component or detail.id)+1);U.selected=f.components[U.component].regionId end) end
 local stats=require('living_stats').calculate({anatomy=f,caps=c,energy=100,stamina=100,maturity=1,oxygen=1});text(string.format('Physical: STR %.2f / DEF %.2f / DEX %.2f / INT %.2f / VIT %.2f / END %.2f',stats.STR,stats.DEF,stats.DEX,stats.INT,stats.VIT,stats.END),855,661,11)
 local traits=G.express(U.genome);text(string.format('Genetic potential: STR %.2f / DEX %.2f / VIT %.2f / END %.2f',traits[2],traits[3],traits[5],traits[7]),275,698,12)
 local r=f.regions[U.selected or 1];if r then text(string.format('#%d %s / parent %s / %.2f x %.2f x %.2f in / %s',r.id,r.partType,tostring(r.parent or 'root'),r.length/32,r.width/32,r.thickness/32,r.role),275,723,12)
  local names={};local mass,force=0,0;for _,c in ipairs(f.components) do if c.regionId==r.id then mass=mass+c.mass;if c.type=='Muscle' then force=force+c.mass*c.force*c.efficiency*c.leverage*c.condition end end end;for k,v in pairs(r.tissues) do names[#names+1]=string.format('%s %.3f',k,v) end;table.sort(names);text('Genes: '..table.concat(r.geneticInfluences,', ')..' / tissue volumes (in^3): '..table.concat(names,'; '):sub(1,92),275,746,11)
  text(string.format('DEF dorsal %.3f / ventral %.3f / attachment (%.1f, %.1f, %.1f)',P.defense(f,r.id,'dorsal'),P.defense(f,r.id,'ventral'),r.attachment.x,r.attachment.y,r.attachment.z)..string.format(' / mass %.3f oz / raw force %.3f',mass,force),275,768,12)
 end
 local r=f.regions[U.selected or 1];if r then local st=f.components[r.structure];text(string.format('Growth %.1f%% / support density %.3f oz/in^3 / bone %.3f in / motor branches %d',r.growth*100,st.density,st.length,#f.nerves),275,790,11) end
 text(table.concat(a.failures,'; '):sub(1,49),1050,505,11,{.68,.25,.2})
 if U.showMotion then
  card(1045,282,330,350);text('ANATOMICAL MOTION / PREVIEW',1056,293,13)
  local available=require('motion').available(f)
  for i,name in ipairs(require('motion').names) do button(name,1055+((i-1)%2)*157,323+math.floor((i-1)/2)*39,150,33,function() U.animation=name;U.animationTime=0;U.animationPaused=false end,U.animation==name,not available[name]) end
  button(U.animationPaused and 'Resume' or 'Pause',1055,486,150,30,function() U.animationPaused=not U.animationPaused end)
  button('Stop',1212,486,150,30,function() U.animation=nil;U.animationTime=0 end)
  local p=c.locomotionProfile
  text(string.format('%s / %d ground limbs / %.3f in/sec',p.mode,#p.legs,p.speed*require('locomotion').worldInches),1055,529,11)
  text(string.format('Balance %.2f / control %.2f / support %.2f',p.balance,p.control,p.support),1055,551,11)
  text(p.canMove and 'Gait follows generated joints and contacts.' or 'This anatomy cannot propel itself on land.',1055,574,11)
  text('Preview controls do not change living PC time.',1055,599,11)
 end
end
return U
