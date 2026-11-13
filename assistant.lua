local M=require('desktop_model');local A={history={},pending=nil,serial=0,ready=false,status='Not loaded',idle=0,animationTime=0,clarifications={}}
function A.settings(s)
 local d=M.ensure(s);d.assistant=d.assistant or {enabled=false,sarcasm=1,appearance='office_clean',outfit='office',wander=true};local a=d.assistant;a.sarcasm=math.floor(math.max(0,math.min(2,tonumber(a.sarcasm) or 1)));a.view=math.floor(math.max(1,math.min(5,tonumber(a.view) or 1)));a.outfit=a.outfit=='casual' and 'casual' or 'office';if not ({office_clean=true,office=true,office_relax=true,stool=true,standing=true})[a.appearance] then a.appearance='office_clean' end;if a.wander==nil then a.wander=true end;a.enabled=a.enabled==true;d.groups.assistant=a.enabled;return a
end
function A.object(s) for _,o in ipairs(M.ensure(s).objects) do if o.kind=='assistant' then return o end end end
function A.setOutfit(s,outfit)
 local settings=A.settings(s);settings.outfit=outfit=='casual' and 'casual' or 'office';A.idle=0;local o=A.object(s);if o then o.config.walking=false;o.config.target=nil end
end
function A.pose(s,o,portrait)
 local settings=A.settings(s);local view=settings.view or 1;local chat=require('desktop_host').panelVisible and require('desktop_app').page=='Assistant'
 if settings.outfit=='casual' then
  if portrait or chat then return 'casual_stand',1,false end
  local cycle=math.floor(math.max(0,A.idle)/24);local phase=math.max(0,A.idle)%24
  if phase>=6 and phase<18 then
   local sequence=({'casual_pickup','casual_stretch','casual_rest','casual_pickup_back','casual_stretch_back','casual_rest_alt'})[cycle%6+1]
   if view>=4 then sequence=cycle%2==0 and 'casual_pickup_back' or 'casual_stretch_back' end
   local count=require('assistant_sprites')[sequence].count;return sequence,math.min(count,math.floor((phase-6)/2)+1),false
  end
  return 'casual_stand',view,false
 end
 local style=settings.appearance;local isChair=style=='office' or style=='office_clean' or style=='office_relax'
 if o and o.config.walking and not portrait and not chat then return 'walk',math.floor(A.animationTime*7)%5+1,o.config.facing==-1 end
 if (A.explaining or 0)>0 or chat then if isChair then return 'office_idle',4,false else return 'explain',1,false end end
 local phase=math.max(0,A.idle)%24
 if view==1 and phase>=4 and phase<10 then
  if isChair then return math.floor(math.max(0,A.idle)/24)%2==0 and 'office_idle' or 'office_idle_alt',math.min(6,math.floor(phase-4)+1),false
  elseif style=='standing' then return math.floor(math.max(0,A.idle)/24)%2==0 and 'classic_stretch' or 'classic_dance',math.min(6,math.floor(phase-4)+1),false end
 end
 if style=='standing' then return 'turns',({1,5,9,14,23})[view],false end
 return style,view,false
end
function A.geometry(s,o,mon)
 local style=A.pose(s,o,false);local info=require('assistant_sprites')[style];local factor=o.scale*mon.dpi/96;local width=math.min(math.max(210,math.ceil((o.h-34)*info.w/(info.referenceHeight or info.h))+20),math.floor(mon.w/factor)-16)
 if width~=o.w then local center=o.x+o.w*factor*.5;o.w=width;o.x=math.max(mon.x,math.min(mon.x+mon.w-width*factor,center-width*factor*.5));o.config.target=nil end
end
function A.reset(s,monitors)
 local o=A.object(s);if not o then return end;local mon=M.monitorAt(monitors,o.x,o.y) or monitors[1];local w,h=M.dimensions(o,mon);o.x=mon.x+mon.w-w-24;o.y=mon.y+mon.h-h;M.remember(o,monitors);A.idle=0;o.config.target=nil
end
function A.ensure(s,monitors)
 local settings=A.settings(s);local o=A.object(s)
 if settings.enabled and not o then o=M.add(s,'assistant','jenny','assistant');A.reset(s,monitors) end
 if o then o.visible=settings.enabled;o.stored=not settings.enabled end
 return o
end
function A.assetRoot() return (love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or love.filesystem.getSource())..'/assistant_assets' end
function A.start()
 if A.thread and A.thread:isRunning() and not A.stopping then return end
 A.stopping=false
 A.ready=false;A.status='Loading offline English model';A.serial=A.serial+1;A.inputName='cellarium-assistant-input-'..A.serial;A.outputName='cellarium-assistant-output-'..A.serial
 A.input=love.thread.getChannel(A.inputName);A.output=love.thread.getChannel(A.outputName);A.thread=love.thread.newThread('assistant_worker.lua');A.thread:start(A.inputName,A.outputName,A.assetRoot())
end
function A.enable(s,enabled,monitors)
 A.settings(s).enabled=enabled;A.ensure(s,monitors);if enabled then A.start() else A.stop() end
end
function A.stop()
 if A.input and A.thread and A.thread:isRunning() then A.input:push({type='stop'}) end
 A.stopping=true;A.ready=false;A.status='Disabled';A.pending=nil
end
function A.open(s)
 if not A.settings(s).enabled then A.enable(s,true,require('desktop_host').monitors) end
 A.idle=0;A.context=require('assistant_knowledge').context(s);require('desktop_host').open('assistant');if #A.history==0 then A.history[1]={role='Jenny',text='I can explain Cellarium and inspect the selected lab item. If I do not have enough evidence, I will ask. What do you need?',scope='Offline laboratory assistant'} end
end
local function append(entry) A.history[#A.history+1]=entry;while #A.history>60 do table.remove(A.history,1) end end
function A.deliver(s,question,classification,context)
 local K=require('assistant_knowledge');local ok,answer=pcall(K.answer,s,classification.intent,question,context);if not ok then A.error=tostring(answer);answer={intent='unknown',text='I could not verify that reading from the current record. Please select the specimen again or ask about its procedure.',scope='No supported conclusion'} end;A.clarifications={}
 if not classification.intent and classification.reason=='ambiguous' then
  answer.text='That could refer to more than one procedure. Which topic did you mean?';answer.scope='Clarification needed'
  for _,c in ipairs(classification.candidates or {}) do if c.id~='unknown' then A.clarifications[#A.clarifications+1]={id=c.id,title=c.title} end end
 end
 local spoken=require('assistant_personality').decorate(answer,A.settings(s).sarcasm);append({role='Jenny',text=spoken,scope=answer.scope});A.idle=0;A.explaining=4;A.lastClassification=classification
end
function A.ask(s,text,preset)
 text=(text or ''):gsub('^%s+',''):gsub('%s+$','');if text=='' or A.pending then return false end
 if #text>1024 then append({role='Jenny',text='Please shorten that to one question of at most 1,024 characters so I can interpret the whole request.'});return false end
 local context=require('assistant_knowledge').context(s);A.context=context;A.idle=0;append({role='You',text=text});A.lastQuestion=text
 if preset then A.deliver(s,text,{intent=preset,reason='chosen'},context);return true end
 if not A.ready then append({role='Jenny',text='The offline English model is not ready. You can still choose one of the verified help topics below.'});return false end
 A.serial=A.serial+1;A.pending={id=A.serial,text=text,context=context};A.input:push({type='question',id=A.serial,text=text});return true
end
function A.choose(s,id,title)
 local K=require('assistant_knowledge');local valid=K.procedures[id]~=nil or id=='status';if not valid then return false end
 return A.ask(s,title or 'Explain '..id,id)
end
function A.update(s,dt,monitors)
 local settings=A.settings(s);A.animationTime=A.animationTime+dt;A.explaining=math.max(0,(A.explaining or 0)-dt)
 if A.output then while true do local message=A.output:pop();if not message then break end
  if message.type=='ready' and settings.enabled then A.ready=true;A.status='Offline MiniLM / CPU';A.runtime=message.runtime
  elseif message.type=='error' then A.ready=false;A.status='English model unavailable';A.error=message.message;append({role='Jenny',text='The local English model could not complete the request. I have not guessed an answer. The verified topic buttons remain available.'});A.pending=nil
  elseif message.type=='answer' and A.pending and message.id==A.pending.id then local question=A.pending;A.pending=nil;A.deliver(s,question.text,message.classification,question.context) end
 end end
 if A.thread and not A.thread:isRunning() and A.pending then A.pending=nil;A.ready=false;A.status='English model unavailable' end
 if not settings.enabled then return end
 local o=A.object(s);if not o or not monitors or #monitors==0 then return end
 local Host=require('desktop_host');local interacting=Host.panelVisible and require('desktop_app').page=='Assistant'
 if interacting or o.drag or A.pending then A.idle=0;o.config.walking=false;if not o.drag then local mon=M.monitorAt(monitors,o.x,o.y) or monitors[1];A.geometry(s,o,mon) end;return end
 A.idle=A.idle+dt;local mon=M.monitorAt(monitors,o.x+o.w*o.scale*.5,o.y) or monitors[1];A.geometry(s,o,mon);local w,h=M.dimensions(o,mon)
 o.y=mon.y+mon.h-h
 if settings.outfit=='casual' or not settings.wander or o.locked or A.idle<12 then o.config.walking=false;return end
 local lo,hi=mon.x+8,math.max(mon.x+8,mon.x+mon.w-w-8)
 if not o.config.target then o.config.target=math.abs(o.x-lo)>math.abs(o.x-hi) and lo or hi end
 local direction=o.config.target>o.x and 1 or -1;local step=42*o.scale*mon.dpi/96*dt
 o.config.walking=true;o.config.facing=direction
 if math.abs(o.config.target-o.x)<=step then o.x=o.config.target;o.config.target=nil;A.idle=-8;o.config.walking=false;M.remember(o,monitors) else o.x=o.x+direction*step end
end
function A.finishDrag(s,o,monitors)
 local mon=M.monitorAt(monitors,o.x+o.w*o.scale*.5,o.y+o.h*o.scale*.5) or monitors[1];local w,h=M.dimensions(o,mon);o.x=math.max(mon.x,math.min(mon.x+mon.w-w,o.x));o.y=mon.y+mon.h-h;o.config.target=nil;o.config.walking=false;A.idle=0;M.remember(o,monitors)
end
function A.menu(s,o)
 local settings=A.settings(s);local Host=require('desktop_host');local levels={'Off','Dry','Sharp'}
 local items={{label='Ask Jenny...',action=function() A.open(s) end},{label='Walk while idle (office outfit)',checked=settings.wander,action=function() settings.wander=not settings.wander;A.idle=0;o.config.walking=false end},
 {label='Sarcasm: '..levels[settings.sarcasm+1],action=function() settings.sarcasm=(settings.sarcasm+1)%3 end},
 {label='Outfit: '..(settings.outfit=='casual' and 'Casual' or 'Office'),action=function() A.setOutfit(s,settings.outfit=='casual' and 'office' or 'casual') end},
 {label='Idle pose: '..(({office_clean='Office chair',office='Original chair',office_relax='Reclined chair',stool='Stool',standing='Standing'})[settings.appearance] or 'Office chair'),action=function() settings.appearance=({office_clean='office',office='office_relax',office_relax='stool',stool='standing',standing='office_clean'})[settings.appearance] or 'office_clean';A.idle=0 end},
 {label='Facing: '..tostring(settings.view or 1)..' / 5',action=function() settings.view=(settings.view or 1)%5+1 end},
 {label='Return above taskbar',action=function() A.reset(s,Host.monitors) end},{label='Disable assistant',action=function() A.enable(s,false,Host.monitors) end}}
 for _,entry in ipairs(require('desktop_depth').menu(s,o)) do items[#items+1]=entry end;local action=require('native_windows').menu(items);if action then action();Host.render(true) end
end
return A
