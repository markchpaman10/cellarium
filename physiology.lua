-- Cellarium physiology estimates and non-destructive locomotion prototype.
-- All values are dimensionless relative indices, not calibrated SI units.
local M={}
local function clamp(x,a,b) return math.max(a,math.min(b,x)) end
local function ratio(a,b) return clamp(a/math.max(.001,b),0,1) end
function M.evaluate(a,progress,condition)
 local out={potential={},current={},vitals={},sources={}}
 if not a then return out end
 local muscle,force,leverage,brain,nerve,heart,lung,stomach,kidney=0,0,0,0,0,0,0,0,0
 local support,armor,fat,volume=0,0,0,0
 for _,c in ipairs(a.components or {}) do
  local v=math.max(0,c.volume or 0)
  volume=volume+v
  if c.type=='Muscle' then muscle=muscle+v;force=force+(c.force or 0)*v;leverage=leverage+(c.leverage or 0)*v end
  if c.type=='Bone' or c.type=='Support' then support=support+v end
  if c.type=='Carapace' then armor=armor+v end
  if c.type=='Fat' then fat=fat+v end
  if c.type=='Brain' then brain=brain+v end
  if c.type=='Nerve' then nerve=nerve+v end
  if c.type=='Heart' then heart=heart+v end
  if c.type=='Lung' then lung=lung+v end
  if c.type=='Stomach' then stomach=stomach+v end
  if c.type=='Kidney' then kidney=kidney+v end
 end
 local mobility,stability,joints=0,0,0
 for _,j in ipairs(a.joints or {}) do
  joints=joints+1;mobility=mobility+(j.mobility or 0);stability=stability+(j.stability or 0)
 end
 local maturity=clamp(progress or 0,0,1)
 local tissue=maturity*(condition.tissue or 1)
 local energy=condition.energy or 1
 local hydration=condition.hydration or 1
 local oxygen=condition.oxygen or 1
 local fatigue=condition.fatigue or 0
 local health=clamp(tissue*.5+hydration*.2+oxygen*.3,0,1)
 local function put(name,base,modifier,source)
  out.potential[name]=clamp(base,0,100)
  out.current[name]=clamp(base*modifier,0,100)
  out.sources[name]=source
 end
 local mass=math.max(.01,volume)
 local strength=100*force/(force+mass*.6+.01)
 local defense=100*(armor+support*.6)/(armor+support*.6+mass*.14+.01)
 local dexterity=100*(mobility+leverage*8)/(mobility+leverage*8+joints*.45+1)
 local intelligence=100*(brain*4+nerve)/(brain*4+nerve+mass*.08+.01)
 local vitality=100*(heart+lung+kidney+support*.15)/(heart+lung+kidney+support*.15+mass*.12+.01)
 local endurance=100*(heart+lung+fat*.25)/(heart+lung+fat*.25+mass*.09+.01)
 local locomotion=100*(force+mobility*.3)/(force+mobility*.3+mass*.7+1)
 local physical=health*(1-fatigue*.7)*energy
 put('Strength',strength,physical,'Muscle force / body volume')
 put('Defense',defense,tissue,'Armor + skeletal support / body volume')
 put('Dexterity',dexterity,physical,'Joint mobility + muscle leverage')
 put('Intelligence',intelligence,oxygen*tissue,'Brain + nerve tissue')
 put('Vitality',vitality,health,'Heart + lung + kidney + support')
 put('Endurance',endurance,energy*oxygen*(1-fatigue),'Circulation + respiration + fat reserves')
 put('Speed',locomotion,physical,'Muscle force + mobile joints / body volume')
 out.vitals={Energy=energy,Hydration=hydration,Oxygen=oxygen,
  Temperature=condition.temperature or 37,Tissue=tissue,Fatigue=fatigue,
  Health=health}
 out.massIndex=mass
 out.maturity=maturity
 out.movementCapacity=out.current.Speed/100
 out.sources.Energy='Stored fuel / exertion'
 out.sources.Hydration='Water reserve / activity'
 out.sources.Oxygen='Respiratory supply / exertion'
 out.sources.Temperature='Environmental heat balance'
 out.sources.Tissue='Development + tissue condition'
 out.sources.Fatigue='Accumulated exertion'
 return out
end
function M.advance(c,dt,activity)
 local a=clamp(activity or 0,0,1)
 c.energy=clamp((c.energy or 1)-dt*(.00018+a*.003),0,1)
 c.hydration=clamp((c.hydration or 1)-dt*(.00012+a*.0015),0,1)
 c.oxygen=clamp((c.oxygen or 1)+dt*(.15*(1-a)-a*.035),0,1)
 c.fatigue=clamp((c.fatigue or 0)+dt*(a*.018-(1-a)*.012),0,1)
 c.tissue=clamp((c.tissue or 1)-dt*(a*.00008),0,1)
end
return M
