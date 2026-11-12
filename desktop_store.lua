local S=require('persistence');local G=require('genome');local M=require('desktop_model');local Store={version=1}
function Store.payload(s,now)
 local snapshot=G.copy(s);local d=M.ensure(snapshot);d.animation=nil;for _,o in ipairs(d.objects) do o.drag=nil end
 local E=require('genome_editor');d.editor={draft=G.copy(E.draft),origin=E.origin,selected=E.selected,site=E.site,history=G.copy(E.history)}
 local app=require('desktop_app');d.app={draftName=app.name,page=app.page,sourceType=app.sourceType,source=app.source}
 return 'return '..S.encode({desktopSchema=1,savedAt=now or os.time(),simulation=snapshot})
end
function Store.decode(raw,B)
 local fn,why=loadstring(raw);if not fn then return nil,why end;setfenv(fn,{})
 local ok,data=pcall(fn);if not ok or type(data)~='table' then return nil,'Invalid desktop save.' end
 local stamp
 if data.desktopSchema then if data.desktopSchema~=1 then return nil,'Unsupported desktop schema '..tostring(data.desktopSchema) end;stamp=data.savedAt;data=data.simulation end
 local success,state=pcall(S.migrate,data,B);if not success then return nil,state end
 M.ensure(state);require('vessels').ensure(state);require('desktop_worlds').ensure(state)
 return state,nil,stamp
end
function Store.save(s,name,now)
 name=name or 'desktop-laboratory.lua';local ok,payload=pcall(Store.payload,s,now);if not ok then return false,payload end
 local valid,why=Store.decode(payload,require('biology'));if not valid then return false,why end
 local written,err=love.filesystem.write(name..'.next',payload);if not written then return false,err end
 local previous=love.filesystem.read(name);if previous then love.filesystem.write(name..'.backup',previous) end
 local root=love.filesystem.getSaveDirectory()..'/'
 local native=require('native_windows')
 if native.available then if not native.atomicReplace(root..name..'.next',root..name) then return false,'Atomic save replacement failed; staged save retained.' end
 else local renamed,reason=os.rename(root..name..'.next',root..name);if not renamed then return false,reason end end
 return true
end
function Store.load(B,name)
 name=name or 'desktop-laboratory.lua';local raw=love.filesystem.read(name);if not raw then return nil,'No saved desktop laboratory.' end
 local state,why,stamp=Store.decode(raw,B)
 if not state then local backup=love.filesystem.read(name..'.backup');if backup then state,why,stamp=Store.decode(backup,B);if state then state.desktop.recovery='Recovered the previous valid backup.' end end end
 if not state then return nil,why end
 local E=require('genome_editor');local editor=state.desktop.editor;if editor then E.draft=editor.draft;E.origin=editor.origin;E.selected=editor.selected or 1;E.site=editor.site or 2;E.history=editor.history or {};E.forecast=nil end
 local app=require('desktop_app');local savedApp=state.desktop.app;if savedApp then app.name=savedApp.draftName or 'Untitled genome';app.page=savedApp.page or 'Lab';app.sourceType=savedApp.sourceType or 'materials';app.source=savedApp.source or 1 end
 local elapsed=math.max(0,os.time()-(stamp or os.time()));local cap=state.desktop.settings.offlineCap or 300
 -- 5 minutes maximum, at 0.01 simulation hours per real second, not the old 1h/s.
 local advance=math.min(elapsed,cap)*.01
 if advance>0 then B.update(state,advance);state.desktop.offlineApplied={elapsed=elapsed,advanced=advance,cap=cap} end
 return state
end
return Store
