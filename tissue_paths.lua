-- Visual connective pathways derived from the existing anatomical graph.
-- This module never changes nerve/vessel simulation or growth.
local T={}
local function point(c,top)
 return c.cx or 0,top and (c.cy or 0) or -(c.cz or 0)
end
local function center(r,top)
 return r.cx or 0,top and (r.cy or 0) or -(r.cz or 0)
end
local function line(ax,ay,bx,by,c,w)
 love.graphics.setColor(c)
 love.graphics.setLineWidth(w)
 love.graphics.line(ax,ay,bx,by)
end
function T.draw(a,connections,top,kind)
 local nerve=kind=='nerve'
 local base=nerve and {.70,.55,.91,.83} or {.79,.22,.31,.64}
 local highlight=nerve and {.91,.79,1,.60} or {1,.52,.49,.43}
 for _,edge in ipairs(connections or {}) do
  local p=a.components[edge.from]
  local q=a.components[edge.to]
  if p and q and (p.growth or 1)>.02 and (q.growth or 1)>.02 then
   local ax,ay=point(p,top)
   local bx,by=point(q,top)
   local rp=a.regions[p.regionId]
   local rq=a.regions[q.regionId]
   local vertices={{ax,ay}}
   -- Parent/child region centers act as stable trunk junctions.
   -- Same-region links stay local instead of looping through the body.
   if rp and rq and rp.id~=rq.id then
    local x,y=center(rp,top)
    vertices[#vertices+1]={x,y}
    local x2,y2=center(rq,top)
    vertices[#vertices+1]={x2,y2}
   elseif rq then
    local x,y=center(rq,top)
    vertices[#vertices+1]={x,y}
   end
   vertices[#vertices+1]={bx,by}
   local strength=nerve and (edge.efficiency or .5) or (edge.capacity or 1)
   local w=nerve and math.max(.14,math.min(.40,.17+strength*.18))
    or math.max(.16,math.min(.55,.23+math.sqrt(math.max(0,strength))*.045))
   for i=2,#vertices do
    local v1,v2=vertices[i-1],vertices[i]
    local dx,dy=v2[1]-v1[1],v2[2]-v1[2]
    if dx*dx+dy*dy>.04 then
     line(v1[1],v1[2],v2[1],v2[2],base,w)
     line(v1[1],v1[2],v2[1],v2[2],highlight,w*.35)
    end
   end
  end
 end
end
return T
