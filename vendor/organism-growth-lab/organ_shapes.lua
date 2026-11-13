-- Anatomical organ silhouettes use the existing component geometry.
-- No changes to organ placement, physiology, or embryonic growth.
local O={}
local palette={
 Heart={.80,.22,.31},Lung={.83,.52,.62},Stomach={.57,.73,.43},
 Brain={.74,.57,.83},Kidney={.62,.35,.35},Gonad={.83,.64,.41}
}
local function color(c,f,a)
 love.graphics.setColor(math.min(1,c[1]*f),math.min(1,c[2]*f),math.min(1,c[3]*f),a or 1)
end
local function oval(x,y,rx,ry,c)
 color(c,.68)
 love.graphics.ellipse('fill',x,y,rx,ry)
 color(c,1.06)
 love.graphics.ellipse('fill',x-rx*.09,y-ry*.12,rx*.84,ry*.81)
 color(c,1.3,.55)
 love.graphics.setLineWidth(math.max(.08,math.min(rx,ry)*.09))
 love.graphics.ellipse('line',x,y,rx*.9,ry*.9)
end
function O.draw(c,top)
 local pigment=palette[c.type]
 if not pigment or (c.growth or 0)<.02 or c.volume<=0 then return end
 local x=c.cx or 0
 local y=top and (c.cy or 0) or -(c.cz or 0)
 local rx=math.max(.12,c.rx or .12)
 local ry=math.max(.12,top and (c.ry or .12) or (c.rz or c.ry or .12))
 -- Cap only the projected silhouette, never the actual biological size.
 local t=c.type
 if t=='Heart' then
  oval(x-rx*.22,y-ry*.16,rx*.66,ry*.67,pigment)
  oval(x+rx*.25,y-ry*.12,rx*.58,ry*.62,pigment)
  color(pigment,.75)
  love.graphics.polygon('fill',x-rx*.77,y,x+rx*.76,y,x+rx*.07,y+ry*.96)
  color(pigment,1.35,.75)
  love.graphics.setLineWidth(math.max(.10,rx*.12))
  love.graphics.line(x-rx*.13,y-ry*.60,x-rx*.05,y-ry*1.04)
 elseif t=='Lung' then
  -- Paired lobes and central bronchial groove are part of one organ.
  oval(x-rx*.38,y,rx*.56,ry*.92,pigment)
  oval(x+rx*.38,y,rx*.56,ry*.92,pigment)
  color(pigment,.55,.75)
  love.graphics.setLineWidth(math.max(.09,rx*.12))
  love.graphics.line(x,y-ry*.78,x,y+ry*.50)
 elseif t=='Brain' then
  oval(x,y,rx,ry,pigment)
  color(pigment,.65,.85)
  love.graphics.setLineWidth(math.max(.08,ry*.10))
  love.graphics.line(x,y-ry*.8,x-rx*.07,y-ry*.3,x+rx*.05,y+ry*.18,x,y+ry*.8)
  for i=-1,1 do
   local yy=y+i*ry*.43
   love.graphics.arc('line','open',x-rx*.48,yy,rx*.20,-1.25,1.25)
   love.graphics.arc('line','open',x+rx*.48,yy,rx*.20,1.9,4.35)
  end
 elseif t=='Kidney' then
  oval(x,y,rx,ry,pigment)
  color(pigment,.62)
  love.graphics.ellipse('fill',x+rx*.79,y,rx*.33,ry*.43)
  color(pigment,1.25,.8)
  love.graphics.setLineWidth(math.max(.08,rx*.10))
  love.graphics.arc('line','open',x-rx*.05,y,ry*.55,-1.15,1.15)
 elseif t=='Stomach' then
  oval(x+rx*.10,y+ry*.13,rx*.83,ry*.78,pigment)
  oval(x-rx*.45,y-ry*.42,rx*.38,ry*.48,pigment)
  color(pigment,.65,.8)
  love.graphics.setLineWidth(math.max(.08,ry*.1))
  love.graphics.arc('line','open',x+rx*.12,y+ry*.05,ry*.44,.1,2.65)
 else
  oval(x,y,rx*.85,ry*.8,pigment)
 end
end
return O
