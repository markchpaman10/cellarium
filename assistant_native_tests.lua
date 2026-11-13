local T={}
function T.run()
 local B=require('biology');local M=require('desktop_model');local N=require('native_windows');local Host=require('desktop_host');local A=require('assistant');local s=B.new(17);require('vessels').ensure(s);M.ensure(s)
 local root=love.filesystem.isFused() and love.filesystem.getSourceBaseDirectory() or love.filesystem.getSource();local lines,failed={},0;local function test(name,fn) local ok,why=xpcall(fn,debug.traceback);lines[#lines+1]=(ok and 'PASS ' or 'FAIL ')..name;if not ok then failed=failed+1;lines[#lines+1]=tostring(why) end end
 local initialized=false
 test('Native assistant windows and tray initialize independently of the running game',function() Host.monitors=N.init({test=true});initialized=true;Host.testing=true;Host.context={B=B,getState=function() return s end,msg=function() end,open=function() end};Host.sync();assert(N.tray and N.control) end)
 if initialized then
  test('Tray Enable Assistant creates exactly one visible native character above the taskbar',function()
   local menu=N.menu;N.menu=function(items) for _,item in ipairs(items) do if item.label=='Enable Assistant' then return item.action end end end;Host.tray();N.menu=menu;Host.render(true);local o=A.object(s);local win=Host.windows[o.id];local rect=N.bounds(win);local mon=M.monitorAt(Host.monitors,o.x,o.y);assert(win.visible and rect.y+rect.h==mon.y+mon.h and #s.desktop.objects>1)
  end)
  test('Native idle walking moves the character and transparent corners pass input through',function()
   local o=A.object(s);s.desktop.settings.alwaysOnTop=true;A.idle=13;local x=o.x;Host.panelVisible=false;A.update(s,.2,Host.monitors);Host.render(true);local win=Host.windows[o.id];local rect=N.bounds(win);assert(o.x~=x and rect.x==math.floor(o.x));assert(N.windowAt(rect.x+2,rect.y+2)~=win.hwnd)
  end)
  test('Native alternate-outfit resting pose resizes without clipping or crossing the taskbar',function()
   local o=A.object(s);A.setOutfit(s,'casual');A.idle=60;Host.panelVisible=false;A.update(s,0,Host.monitors);Host.render(true);local r=N.bounds(Host.windows[o.id]);local mon=M.monitorAt(Host.monitors,o.x,o.y);assert(r.w>210 and r.y+r.h==mon.y+mon.h and not o.config.walking);A.setOutfit(s,'office');A.update(s,0,Host.monitors);Host.render(true)
  end)
  test('Native character click opens help without replacing the selected vial context',function()
   local o=A.object(s);local vial;for _,object in ipairs(s.desktop.objects) do if object.kind=='vial' then vial=object;break end end;s.desktop.selectedObject=vial.id;local old=Host.open;local opened;Host.open=function(mode) opened=mode;Host.panelVisible=true;require('desktop_app').page='Assistant' end
   local win=Host.windows[o.id];N.testMessage(win,0x201,0,100+180*65536);N.testMessage(win,0x202,0,100+180*65536);for _,e in ipairs(N.pump()) do Host.event(e) end;Host.open=old;assert(opened=='assistant' and s.desktop.selectedObject==vial.id)
  end)
  test('Native assistant drag works across available monitors and disables cleanly',function()
   local o=A.object(s);local mon=Host.monitors[math.min(2,#Host.monitors)];o.x=mon.x+50;o.y=mon.y+50;A.finishDrag(s,o,Host.monitors);Host.render(true);local rect=N.bounds(Host.windows[o.id]);assert(rect.y+rect.h==mon.y+mon.h);A.enable(s,false,Host.monitors);Host.render(true);assert(not Host.windows[o.id].visible);lines[#lines+1]=#Host.monitors>1 and 'INFO Actual second-monitor baseline checked.' or 'SKIP Actual second monitor: only one connected; synthetic mixed-DPI test covers layout.'
  end)
  A.stop();if A.thread then A.thread:wait() end;N.shutdown();Host.context=nil;Host.windows={}
 end
 local summary=table.concat(lines,'\n')..'\n'..failed..' failures.\n';local f=assert(io.open(root..'/assistant-native-test-results.txt','wb'));f:write(summary);f:close();assert(failed==0,summary);return summary
end
return T
