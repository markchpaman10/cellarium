-- Feeding ecology is derived from grown organs and genetic expression, never a species label.
local D={}
local function clamp(x) return math.max(0,math.min(1,x)) end
function D.capabilities(a,c,q,teeth,mouthCondition,water)
 local stomach=0;local mouth=0;local grinding=0
 for _,part in ipairs(a.components or {}) do
  if part.type=='Stomach' then stomach=stomach+(part.capacity or 0)*(part.efficiency or 1)*(part.condition or 1) end
  if part.type=='Mouth' then mouth=mouth+(part.condition or 1) end
 end
 for _,p in ipairs(a.projections or {}) do
  if p.role=='crushing mouthpart' then grinding=grinding+(p.condition or 1)*(p.hardness or 0) end
 end
 local gut=clamp(stomach/(1+stomach))
 local enzymatic=clamp((c.digestion or 0)/(1+(c.digestion or 0)))
 local cutting=clamp(teeth/(2+teeth))
 local crush=clamp(grinding/(2+grinding))
 local uptake=clamp((c.cutaneousExchange or 0)/(2+(c.cutaneousExchange or 0)))
 local herb=clamp((.12+gut*.6+crush*.35+enzymatic*.3)*mouthCondition)
 local carn=clamp((.06+cutting*.55+enzymatic*.4+clamp((c.biteForce or c.force or 0)/15)*.3)*mouthCondition)
 local scav=clamp((.16+enzymatic*.5+gut*.2)*mouthCondition)
 local dissolved=clamp(uptake*(water>0 and 1 or .25))
 local diet={plant=herb,tissue=carn,debris=scav,dissolved=dissolved}
 local best=math.max(herb,carn,dissolved)
 local label
 if dissolved>herb and dissolved>carn then label='Absorptive'
 elseif herb>.3 and carn>.3 and math.min(herb,carn)/math.max(herb,carn)>.55 then label='Omnivorous'
 elseif carn>herb then label='Carnivorous'
 else label='Herbivorous' end
 return diet,label
end
return D
