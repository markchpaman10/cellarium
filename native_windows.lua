-- All native handles stay here. Nothing in the simulation owns HWNDs.
local ffi=require('ffi');local bit=require('bit');local W={windows={},events={},closed=false}
if ffi.os~='Windows' then return {available=false} end
ffi.cdef[[
typedef void *HWND; typedef void *HANDLE; typedef void *HDC; typedef void *HBITMAP; typedef void *HICON; typedef void *HMENU;
typedef unsigned long DWORD; typedef unsigned int UINT; typedef int BOOL; typedef long LONG; typedef unsigned short WORD; typedef unsigned char BYTE;
typedef struct { LONG x,y; } POINT; typedef struct { LONG cx,cy; } SIZE; typedef struct { LONG left,top,right,bottom; } RECT;
typedef intptr_t (__stdcall *WNDPROC)(HWND,UINT,uintptr_t,intptr_t);
typedef struct { UINT style; WNDPROC lpfnWndProc; int cbClsExtra,cbWndExtra; HANDLE hInstance; HICON hIcon; HANDLE hCursor; HANDLE hbrBackground; const char *lpszMenuName;const char *lpszClassName; } WNDCLASSA;
typedef struct { HWND hwnd;UINT message;uintptr_t wParam;intptr_t lParam;DWORD time;POINT pt;DWORD lPrivate; } MSG;
typedef struct { DWORD cbSize;RECT rcMonitor,rcWork;DWORD dwFlags;char szDevice[32]; } MONITORINFOEXA;
typedef BOOL (__stdcall *MONITORENUMPROC)(HANDLE,HDC,RECT*,intptr_t);
typedef struct { DWORD biSize;LONG biWidth,biHeight;WORD biPlanes,biBitCount;DWORD biCompression,biSizeImage;LONG biXPelsPerMeter,biYPelsPerMeter;DWORD biClrUsed,biClrImportant; } BITMAPINFOHEADER;
typedef struct { BITMAPINFOHEADER bmiHeader;DWORD colors[3]; } BITMAPINFO;
typedef struct { BYTE BlendOp,BlendFlags,SourceConstantAlpha,AlphaFormat; } BLENDFUNCTION;
typedef struct { DWORD cbSize;HWND hWnd;UINT uID,uFlags,uCallbackMessage;HICON hIcon;char szTip[128];DWORD dwState,dwStateMask;char szInfo[256];UINT uTimeoutOrVersion;char szInfoTitle[64];DWORD dwInfoFlags;BYTE guidItem[16];HICON hBalloonIcon; } NOTIFYICONDATAA;
HANDLE __stdcall GetModuleHandleA(const char*); DWORD __stdcall GetLastError(void);
unsigned short __stdcall RegisterClassA(const WNDCLASSA*); BOOL __stdcall UnregisterClassA(const char*,HANDLE);
HWND __stdcall CreateWindowExA(DWORD,const char*,const char*,DWORD,int,int,int,int,HWND,HMENU,HANDLE,void*);
intptr_t __stdcall DefWindowProcA(HWND,UINT,uintptr_t,intptr_t);BOOL __stdcall DestroyWindow(HWND);BOOL __stdcall IsWindow(HWND);
BOOL __stdcall ShowWindow(HWND,int); BOOL __stdcall SetWindowPos(HWND,HWND,int,int,int,int,UINT);BOOL __stdcall GetWindowRect(HWND,RECT*);
HWND __stdcall WindowFromPoint(POINT);BOOL __stdcall IsWindowVisible(HWND);
HWND __stdcall FindWindowA(const char*,const char*);
BOOL __stdcall PeekMessageA(MSG*,HWND,UINT,UINT,UINT);BOOL __stdcall TranslateMessage(const MSG*);intptr_t __stdcall DispatchMessageA(const MSG*);
BOOL __stdcall GetCursorPos(POINT*); HWND __stdcall SetCapture(HWND);BOOL __stdcall ReleaseCapture(void);HWND __stdcall GetCapture(void);
BOOL __stdcall SetForegroundWindow(HWND);BOOL __stdcall PostMessageA(HWND,UINT,uintptr_t,intptr_t);intptr_t __stdcall SendMessageA(HWND,UINT,uintptr_t,intptr_t);
HDC __stdcall GetDC(HWND);int __stdcall ReleaseDC(HWND,HDC);HDC __stdcall CreateCompatibleDC(HDC);BOOL __stdcall DeleteDC(HDC);
HBITMAP __stdcall CreateDIBSection(HDC,const BITMAPINFO*,UINT,void**,HANDLE,DWORD);HANDLE __stdcall SelectObject(HDC,HANDLE);BOOL __stdcall DeleteObject(HANDLE);
BOOL __stdcall UpdateLayeredWindow(HWND,HDC,const POINT*,const SIZE*,HDC,const POINT*,DWORD,const BLENDFUNCTION*,DWORD);
BOOL __stdcall EnumDisplayMonitors(HDC,const RECT*,MONITORENUMPROC,intptr_t);BOOL __stdcall GetMonitorInfoA(HANDLE,MONITORINFOEXA*);
BOOL __stdcall SetProcessDpiAwarenessContext(HANDLE);HANDLE __stdcall SetThreadDpiAwarenessContext(HANDLE);
UINT __stdcall GetDpiForWindow(HWND);HICON __stdcall LoadIconA(HANDLE,const char*);HANDLE __stdcall LoadCursorA(HANDLE,const char*);
BOOL __stdcall Shell_NotifyIconA(DWORD,NOTIFYICONDATAA*);UINT __stdcall RegisterWindowMessageA(const char*);
HMENU __stdcall CreatePopupMenu(void);BOOL __stdcall AppendMenuA(HMENU,UINT,uintptr_t,const char*);BOOL __stdcall DestroyMenu(HMENU);
UINT __stdcall TrackPopupMenu(HMENU,UINT,int,int,int,HWND,const RECT*);int __stdcall MessageBoxA(HWND,const char*,const char*,UINT);
BOOL __stdcall RegisterHotKey(HWND,int,UINT,UINT);BOOL __stdcall UnregisterHotKey(HWND,int);
BOOL __stdcall MoveFileExA(const char*,const char*,DWORD);
void* SDL_GetWindowFromID(unsigned int);const char* SDL_GetWindowTitle(void*);void SDL_HideWindow(void*);void SDL_ShowWindow(void*);void SDL_RaiseWindow(void*);
]]
local user=ffi.load('user32');local gdi=ffi.load('gdi32');local shell=ffi.load('shell32');local kernel=ffi.load('kernel32');local shcore
pcall(function() shcore=ffi.load('shcore');ffi.cdef'int __stdcall GetDpiForMonitor(HANDLE,int,UINT*,UINT*);' end)
W.available=true
local function key(h) return tostring(ffi.cast('uintptr_t',h)) end
local function push(e) W.events[#W.events+1]=e end
local function cursor() local p=ffi.new('POINT[1]');user.GetCursorPos(p);return {x=tonumber(p[0].x),y=tonumber(p[0].y)} end
W.cursor=cursor
local function xy(lp) local n=tonumber(lp);local x=bit.band(n,65535);local y=bit.band(bit.rshift(n,16),65535);if x>=32768 then x=x-65536 end;if y>=32768 then y=y-65536 end;return x,y end
local callback
callback=ffi.cast('WNDPROC',function(hwnd,msg,wp,lp)
 local win=W.windows[key(hwnd)]
 if msg==W.taskbarCreated and W.tray then shell.Shell_NotifyIconA(0,W.tray);return 0 end
 if msg==0x8001 then local code=bit.band(tonumber(lp),65535);if code==0x205 or code==0x7b then push{type='trayMenu'} elseif code==0x203 then push{type='openPanel'} end;return 0 end
 if msg==0x312 then push{type='recovery'};return 0 end
 if msg==0x7e or msg==0x2e0 then push{type='displays'};return 0 end
 if msg==0x10 then if win then push{type='hide',id=win.id} else push{type='exit'} end;return 0 end
 if win then
  if msg==0x21 then return 3 end -- MA_NOACTIVATE: objects do not steal typing focus.
  if msg==0x201 then local x,y=xy(lp);user.SetCapture(hwnd);push{type='down',id=win.id,x=x,y=y,cursor=cursor()};return 0 end
  if msg==0x200 then if user.GetCapture()==hwnd then local x,y=xy(lp);push{type='move',id=win.id,x=x,y=y,cursor=cursor()} end;return 0 end
  if msg==0x202 then user.ReleaseCapture();local x,y=xy(lp);push{type='up',id=win.id,x=x,y=y,cursor=cursor()};return 0 end
  if msg==0x215 then push{type='cancelDrag',id=win.id};return 0 end
  if msg==0x205 then push{type='objectMenu',id=win.id};return 0 end
  if msg==0x20a then local delta=bit.arshift(tonumber(wp),16);push{type='wheel',id=win.id,delta=delta};return 0 end
  if msg==0xf then return user.DefWindowProcA(hwnd,msg,wp,lp) end
 end
 return user.DefWindowProcA(hwnd,msg,wp,lp)
end)
function W.init(options)
 -- SDL may have initialized first. Thread context covers all native HWNDs and cursor coordinates.
 pcall(function() user.SetProcessDpiAwarenessContext(ffi.cast('HANDLE',-4));user.SetThreadDpiAwarenessContext(ffi.cast('HANDLE',-4)) end)
 W.instance=kernel.GetModuleHandleA(nil);W.className=options and options.test and 'CellariumDesktopObjectsTestV1' or 'CellariumDesktopObjectsV1';W.callback=callback
 local controlTitle=options and options.test and 'Cellarium desktop test control' or 'Cellarium desktop laboratory'
 local existing=user.FindWindowA(W.className,controlTitle)
 if existing~=nil then user.MessageBoxA(nil,'A desktop laboratory is already running. Exit it from its tray menu before launching another build. This prevents conflicting saves.','Cellarium',0x40);return nil,'already running' end
 local wc=ffi.new('WNDCLASSA');wc.lpfnWndProc=callback;wc.hInstance=W.instance;wc.lpszClassName=W.className;wc.hCursor=user.LoadCursorA(nil,ffi.cast('const char*',32512))
 assert(user.RegisterClassA(wc)~=0,'RegisterClass failed: '..tonumber(kernel.GetLastError()))
 W.control=user.CreateWindowExA(0x80,W.className,controlTitle,0,0,0,0,0,nil,nil,W.instance,nil);assert(W.control~=nil,'Tray control window failed')
 W.taskbarCreated=user.RegisterWindowMessageA('TaskbarCreated')
 local tray=ffi.new('NOTIFYICONDATAA[1]');tray[0].cbSize=ffi.sizeof(tray[0]);tray[0].hWnd=W.control;tray[0].uID=1;tray[0].uFlags=7;tray[0].uCallbackMessage=0x8001;tray[0].hIcon=user.LoadIconA(nil,ffi.cast('const char*',32516));ffi.copy(tray[0].szTip,'Cellarium - desktop laboratory')
 local trayOk=shell.Shell_NotifyIconA(0,tray);assert(trayOk~=0,'Cannot create system tray icon: error '..tonumber(kernel.GetLastError())..', struct '..ffi.sizeof(tray[0])..', hwnd '..tostring(W.control)..', icon '..tostring(tray[0].hIcon));W.tray=tray
 W.hotkey=user.RegisterHotKey(W.control,1,bit.bor(2,4,0x4000),0x4c)~=0 -- Ctrl+Shift+L recovery
 return W.monitors()
end
function W.monitors()
 local result={};local cb=ffi.cast('MONITORENUMPROC',function(handle)
  local info=ffi.new('MONITORINFOEXA[1]');info[0].cbSize=ffi.sizeof(info[0]);if user.GetMonitorInfoA(handle,info)~=0 then
   local r=info[0].rcWork;local x,y=ffi.new('UINT[1]',96),ffi.new('UINT[1]',96);if shcore then pcall(function() shcore.GetDpiForMonitor(handle,0,x,y) end) end
   result[#result+1]={id=ffi.string(info[0].szDevice),x=tonumber(r.left),y=tonumber(r.top),w=tonumber(r.right-r.left),h=tonumber(r.bottom-r.top),dpi=tonumber(x[0]),primary=bit.band(info[0].dwFlags,1)~=0}
  end;return 1
 end);user.EnumDisplayMonitors(nil,nil,cb,0);cb:free();table.sort(result,function(a,b) if a.primary~=b.primary then return a.primary end;return a.id<b.id end);return result
end
function W.create(o)
 local hwnd=user.CreateWindowExA(bit.bor(0x80000,0x80,0x08000000),W.className,'Cellarium / '..o.kind..' / '..o.id,0x80000000,o.x,o.y,1,1,nil,nil,W.instance,nil)
 assert(hwnd~=nil,'Desktop object window failed');local win={id=o.id,hwnd=hwnd,w=0,h=0,visible=false};W.windows[key(hwnd)]=win;return win
end
local function releaseBitmap(win)
 if win.dc then gdi.SelectObject(win.dc,win.oldBitmap);gdi.DeleteObject(win.bitmap);gdi.DeleteDC(win.dc);win.dc=nil;win.data=nil end
end
local function copyBGRA(src,dst,pixels)
 for i=0,pixels-1 do local j=i*4;dst[j]=src[j+2];dst[j+1]=src[j+1];dst[j+2]=src[j];dst[j+3]=src[j+3] end
end
function W.present(win,data,x,y,topmost,layer)
 local width,height=data:getDimensions()
 if win.w~=width or win.h~=height then
  releaseBitmap(win);local dc=gdi.CreateCompatibleDC(nil);local info=ffi.new('BITMAPINFO');info.bmiHeader.biSize=ffi.sizeof('BITMAPINFOHEADER');info.bmiHeader.biWidth=width;info.bmiHeader.biHeight=-height;info.bmiHeader.biPlanes=1;info.bmiHeader.biBitCount=32
  local bits=ffi.new('void*[1]');local bmp=gdi.CreateDIBSection(dc,info,0,bits,nil,0);assert(bmp~=nil,'DIB allocation failed');win.dc=dc;win.bitmap=bmp;win.data=ffi.cast('uint8_t*',bits[0]);win.oldBitmap=gdi.SelectObject(dc,bmp);win.w=width;win.h=height
 end
 local src=ffi.cast('uint8_t*',data:getFFIPointer());local dst=win.data
 -- LÖVE canvases already contain premultiplied RGB. Win32 expects BGRA premultiplied.
 copyBGRA(src,dst,width*height)
 local point=ffi.new('POINT[1]',{{math.floor(x),math.floor(y)}});local size=ffi.new('SIZE[1]',{{width,height}});local origin=ffi.new('POINT[1]');local blend=ffi.new('BLENDFUNCTION[1]',{{0,0,255,1}})
 assert(user.UpdateLayeredWindow(win.hwnd,nil,point,size,win.dc,origin,0,blend,2)~=0,'UpdateLayeredWindow failed: '..tonumber(kernel.GetLastError()))
 local mode=topmost and -1 or -2
 if win.topmost~=topmost or win.layer~=layer then user.SetWindowPos(win.hwnd,ffi.cast('HWND',layer<0 and 1 or mode),0,0,0,0,bit.bor(1,2,0x10));win.topmost=topmost;win.layer=layer end
 if not win.visible then user.ShowWindow(win.hwnd,4);win.visible=true end
end
function W.move(win,x,y) user.SetWindowPos(win.hwnd,nil,math.floor(x),math.floor(y),0,0,bit.bor(1,4,0x10)) end
function W.hide(win) if win.visible then user.ShowWindow(win.hwnd,0);win.visible=false end end
function W.destroy(win) releaseBitmap(win);W.windows[key(win.hwnd)]=nil;user.DestroyWindow(win.hwnd) end
function W.pump()
 local msg=ffi.new('MSG[1]');local count=0
 -- Filter to our HWNDs. Never consume SDL's messages.
 local handles={W.control};for _,v in pairs(W.windows) do handles[#handles+1]=v.hwnd end
 for _,hwnd in ipairs(handles) do while count<500 and user.PeekMessageA(msg,hwnd,0,0,1)~=0 do user.TranslateMessage(msg);user.DispatchMessageA(msg);count=count+1 end end
 local events=W.events;W.events={};return events
end
function W.menu(items)
 local menu=user.CreatePopupMenu();local map={};local index=100
 for _,item in ipairs(items) do if item.separator then user.AppendMenuA(menu,0x800,0,nil) else index=index+1;map[index]=item.action;user.AppendMenuA(menu,item.checked and 8 or 0,index,item.label) end end
 local p=cursor();user.SetForegroundWindow(W.control);local selected=user.TrackPopupMenu(menu,bit.bor(0x100,2),p.x,p.y,0,W.control,nil);user.PostMessageA(W.control,0,0,0);user.DestroyMenu(menu);return map[tonumber(selected)]
end
function W.confirm(message) return user.MessageBoxA(W.control,message,'Cellarium',bit.bor(4,0x20))==6 end
function W.alert(message) user.MessageBoxA(W.control,message,'Cellarium',0x40) end
function W.notify(message)
 if not W.tray then return end
 local note=ffi.new('NOTIFYICONDATAA[1]');ffi.copy(note,W.tray,ffi.sizeof(note[0]));note[0].uFlags=16;ffi.fill(note[0].szInfo,256);ffi.copy(note[0].szInfo,tostring(message):sub(1,254));ffi.fill(note[0].szInfoTitle,64);ffi.copy(note[0].szInfoTitle,'Cellarium');note[0].dwInfoFlags=0x11;shell.Shell_NotifyIconA(1,note)
end
function W.panel(visible)
 local sdl=ffi.load('SDL2')
 if not W.sdlWindow then for id=1,32 do local win=sdl.SDL_GetWindowFromID(id);if win~=nil then local title=sdl.SDL_GetWindowTitle(win);if title~=nil and ffi.string(title):find('CELLARIUM',1,true) then W.sdlWindow=win;break end end end end
 if W.sdlWindow then if visible then sdl.SDL_ShowWindow(W.sdlWindow);sdl.SDL_RaiseWindow(W.sdlWindow) else sdl.SDL_HideWindow(W.sdlWindow) end end
end
function W.atomicReplace(source,target) return kernel.MoveFileExA(source,target,bit.bor(1,8))~=0 end
function W.testMessage(win,msg,wp,lp) return user.SendMessageA(win.hwnd,msg,wp or 0,lp or 0) end
function W.bounds(win) local r=ffi.new('RECT[1]');user.GetWindowRect(win.hwnd,r);return {x=tonumber(r[0].left),y=tonumber(r[0].top),w=tonumber(r[0].right-r[0].left),h=tonumber(r[0].bottom-r[0].top)} end
function W.windowAt(x,y) local p=ffi.new('POINT');p.x=x;p.y=y;return user.WindowFromPoint(p) end
function W.isVisible(win) return user.IsWindowVisible(win.hwnd)~=0 end
function W.shutdown()
 if W.closed then return end;W.closed=true
 if W.tray then shell.Shell_NotifyIconA(2,W.tray);W.tray=nil end
 if W.control then user.UnregisterHotKey(W.control,1) end
 local list={};for _,w in pairs(W.windows) do list[#list+1]=w end;for _,w in ipairs(list) do W.destroy(w) end
 if W.control then user.DestroyWindow(W.control);W.control=nil end;user.UnregisterClassA(W.className,W.instance)
end
-- Win32 may synchronously re-enter a window procedure. Keep the caller off JIT traces.
for _,fn in pairs(W) do if type(fn)=='function' then jit.off(fn,true) end end
return W
