local A=require('assistant');local UI={draft='',focus=true,offset=0,selectAll=false};local K=require('assistant_knowledge')
local function backspace(s) return require('container_labels').backspace(s) end
function UI.textinput(t) if UI.focus then UI.draft=((UI.selectAll and '' or UI.draft)..t:gsub('[%z\1-\8\11\12\14-\31]','')):sub(1,1024);UI.selectAll=false;return true end end
function UI.send(s) if UI.draft:match('%S') and not A.pending then if A.ask(s,UI.draft) then UI.draft='';UI.offset=0 end end end
function UI.keypressed(key,s)
 if key=='escape' then return false end
 if key=='return' or key=='kpenter' then UI.send(s);return true end
 if key=='backspace' then UI.draft=UI.selectAll and '' or backspace(UI.draft);UI.selectAll=false
 elseif key=='a' and love.keyboard.isDown('lctrl','rctrl') then UI.selectAll=true
 elseif key=='v' and love.keyboard.isDown('lctrl','rctrl') then UI.textinput(love.system.getClipboardText())
 elseif key=='up' and UI.draft=='' then UI.draft=A.lastQuestion or '' end
 return true
end
function UI.scroll(y) UI.offset=math.max(0,UI.offset+y*60) end
function UI.draw(s,ui)
 local text,button,card=ui.text,ui.button,ui.card;local settings=A.settings(s)
 text('Jenny / laboratory assistant',250,88,28);text('Offline English help. Answers come from verified game rules and current laboratory data.',250,132,13)
 card(250,174,850,490);card(1120,174,270,490)
 if not settings.enabled then button('Enable Assistant',1140,194,230,35,function() A.enable(s,true,require('desktop_host').monitors) end) else text(A.ready and 'Offline / CPU / ready' or A.status,1140,197,13) end
 local portrait,frame=A.pose(s,A.object(s),true);local info=require('assistant_sprites')[portrait];require('assistant_art').drawSprite(portrait,frame,1255,646,math.min(330*(info.referenceHeight or info.h)/info.h,250*(info.referenceHeight or info.h)/info.w),false)
 button('Sarcasm: '..({'Off','Dry','Sharp'})[settings.sarcasm+1],1140,236,230,31,function() settings.sarcasm=(settings.sarcasm+1)%3 end)
 UI.font=UI.font or love.graphics.newFont(15);button('Outfit: '..(settings.outfit=='casual' and 'Casual' or 'Office'),1140,273,230,31,function() A.setOutfit(s,settings.outfit=='casual' and 'office' or 'casual') end)
 local font=UI.font;local rendered={};local total=0
 for _,message in ipairs(A.history) do
  local _,wrapped=font:getWrap(message.text,796);local height=26+#wrapped*20+(message.scope and 23 or 0)+18;rendered[#rendered+1]={message=message,lines=wrapped,height=height};total=total+height
 end
 if #rendered==0 then rendered={{message={role='Jenny',text='Select a lab item for context, then ask me a Cellarium question. If the evidence is unclear, I will ask you to narrow it down.'},lines={'Select a lab item for context, then ask me a Cellarium question.','If the evidence is unclear, I will ask you to narrow it down.'},height=104}};total=104 end
 UI.offset=math.min(UI.offset,math.max(0,total-440));local y=194-math.max(0,total-440)+UI.offset
 local sx,sy,sw,sh=love.graphics.getScissor();local scaleX,scaleY=love.graphics.getWidth()/1440,love.graphics.getHeight()/900;love.graphics.setScissor(265*scaleX,184*scaleY,820*scaleX,466*scaleY)
 for _,row in ipairs(rendered) do
  if y+row.height>184 and y<650 then
   text(row.message.role,272,y,13,row.message.role=='Jenny' and {.05,.41,.37} or {.37,.42,.48});local yy=y+25
   for _,line in ipairs(row.lines) do text(line,272,yy,15);yy=yy+20 end
   if row.message.scope then text(row.message.scope,272,yy+4,11,{.38,.47,.5}) end
  end;y=y+row.height
 end
 if sx then love.graphics.setScissor(sx,sy,sw,sh) else love.graphics.setScissor() end
 local topics=A.clarifications;local choices=#topics>0 and topics or {{id='install',title='Install DNA'},{id='movement',title='Organism not moving'},{id='cultivate',title='Culture not growing'},{id='status',title='Current lab status'}}
 for i,item in ipairs(choices) do if i<=4 then button(item.title,250+(i-1)*285,681,270,34,function() A.choose(s,item.id,item.title);UI.offset=0 end) end end
 card(250,738,1140,81);local context=K.context(s);local object=context.object and require('desktop_model').find(s,context.object)
 local caption=object and ('Context: '..object.kind..' / #'..tostring(object.entityId)) or context.organism and ('Context: organism #'..context.organism) or 'Select a lab item or include its #ID for a specific reading.'
 text(caption,268,716,11,{.38,.47,.5})
 love.graphics.setColor(.93,.96,.96);love.graphics.rectangle('fill',266,752,924,49,5)
 local draft=UI.draft=='' and 'Ask one question about Cellarium...' or UI.draft;local show=draft;love.graphics.setFont(font);while font:getWidth(show)>900 do show=show:sub(2) end
 text(show..(UI.focus and math.floor(love.timer.getTime()*2)%2==0 and '|' or ''),280,766,15,UI.draft=='' and {.45,.53,.55} or {.11,.18,.21})
 ui.register(266,752,924,49,function() UI.focus=true end,'Assistant question')
 button(A.pending and 'Checking...' or 'Ask Jenny',1210,752,162,49,A.pending and nil or function() UI.send(s) end)
 text('Enter to ask / Ctrl+A to replace / wheel to read earlier replies',268,829,11,{.38,.47,.5})
end
return UI
