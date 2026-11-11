local H=require('habitat');local N={}
function N.heading(s,o,tx,ty)
 if (o.altitude or 0)>.08 then return math.atan2(ty-o.y,tx-o.x) end
 local w,h=H.width,H.height
 local function index(x,y) return math.max(1,math.min(h,math.floor(y*h)+1))*w+math.max(1,math.min(w,math.floor(x*w)+1))-w end
 local start,goal=index(o.x,o.y),index(tx,ty);local cache=o.navigation
 if not cache or cache.goal~=goal or s.time>(cache.expires or 0) then
  local queue={start};local visited={[start]=true};local parents={};local head=1;local found=false
  while head<=#queue do local current=queue[head];head=head+1;if current==goal then found=true;break end
   local x=(current-1)%w+1;local y=math.floor((current-1)/w)+1
   for _,step in ipairs({{1,0},{-1,0},{0,1},{0,-1}}) do local xx,yy=x+step[1],y+step[2];if xx>=4 and xx<=w-3 and yy>=4 and yy<=h-3 then local nextIndex=(yy-1)*w+xx;local cell=s.habitat.cells[nextIndex]
    local safe=(o.oxygen or 1)<.7 or o.traits.perception<=.25 or (H.oxygenRatio(o.caps,cell)>.85 and (cell.salinity or 0)<o.caps.salinityTolerance+.4)
    if not visited[nextIndex] and not cell.obstacle and safe then visited[nextIndex]=true;parents[nextIndex]=current;queue[#queue+1]=nextIndex end
   end end
  end
  if not found then o.navigation=nil;return nil end
  local reversed={};local at=goal;while at~=start do reversed[#reversed+1]=at;at=parents[at] end
  local path={};for i=#reversed,1,-1 do path[#path+1]=reversed[i] end;path[#path+1]={x=tx,y=ty};cache={goal=goal,path=path,step=1,expires=s.time+3};o.navigation=cache
 end
 local point=cache.path[cache.step];if not point then return math.atan2(ty-o.y,tx-o.x) end
 local px,py;if type(point)=='table' then px,py=point.x,point.y else px=((point-1)%w+.5)/w;py=(math.floor((point-1)/w)+.5)/h end
 if (px-o.x)^2+(py-o.y)^2<.000025 then cache.step=cache.step+1 end
 return math.atan2(py-o.y,px-o.x)
end
return N
