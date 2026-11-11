local G=require('genome');local A={}
function A.generate(genome,conditions)
 local e=G.express(genome);local n=4+math.floor((e[11]+e[12])+ .1);local halfWidth=e[13]>.6 and 2 or 1;local a={version=2,components={},bones={},joints={},muscles={},organs={},skin={},fat={},nerves={},vessels={},symmetry='bilateral',segments=n,width=halfWidth*2+1,limbPairs=1+math.floor(e[14]*2+.1),pigment=e[23],development=conditions or {temperature=37,nutrition=1}}
 local quality=math.min(1,(a.development.nutrition or 1))*math.max(.3,1-math.abs((a.development.temperature or 37)-37)/30)
 local function add(kind,x,y,parent,props)
  local c={id=#a.components+1,type=kind,x=x,y=y,size=16,orientation=0,parent=parent,condition=1,mass=.1};for k,v in pairs(props or {}) do c[k]=v end;a.components[#a.components+1]=c;return c
 end
 local previous
 for i=1,n do
  local b=add('Bone',(i-(n+1)/2)*16,0,previous,{length=16*(.8+e[12]*.4),thickness=2+e[15]*3,density=.5+e[15],strength=(1+e[15]*3)*quality,mass=.35+e[15]*.6,jointPoints={-8,8},region='torso'})
  a.bones[#a.bones+1]=b;previous=b.id
  local m=add('Muscle',b.x,0,b.id,{origin=b.id,insertion=math.max(1,b.id-1),mass=(.35+e[16]*.7)*quality,force=(.5+e[2]*2)*(.7+e[1]*.3)*quality,efficiency=.5+e[3]*.5,energyCost=.1+e[1]*.2,fatigue=0,region='torso'});a.muscles[#a.muscles+1]=m
  for side=-1,1,2 do
   local fat=add('Fat',b.x,side*12,b.id,{mass=.08+e[17]*.35,capacity=3+e[17]*7,insulation=.2+e[17]*.8,region='torso'});a.fat[#a.fat+1]=fat
  end
  for row=-halfWidth,halfWidth do if not (math.abs(row)==halfWidth and (i==1 or i==n)) then local c=add('Skin',b.x,row*16,b.id,{mass=.08+e[18]*.15,thickness=1+e[18]*3,toughness=.2+e[18]*.8,flexibility=1-e[18]*.3,regeneration=.02+e[6]*.05,region=row==0 and 'torso' or 'covering'});a.skin[#a.skin+1]=c end end
 end
 local positions={};for pair=1,a.limbPairs do positions[#positions+1]=math.floor(1+pair*(n-1)/(a.limbPairs+1)) end
 for _,index in ipairs(positions) do local root=a.bones[index];for side=-1,1,2 do
  local last=root.id
  for segment=1,2 do local b=add('Bone',root.x+(index<=n/2 and -1 or 1)*segment*5,side*(halfWidth*16+segment*12),last,{length=12+e[12]*6,thickness=2+e[15]*2,density=.5+e[15],strength=(.6+e[15]*2)*quality,mass=.2+e[15]*.3,region='limb',side=side,segment=segment});a.bones[#a.bones+1]=b
   a.joints[#a.joints+1]={id=#a.joints+1,parent=last,child=b.id,type='hinge',range=.5+e[3],stability=.4+e[15]*.5,strength=b.strength,mobility=.4+e[3]*.6,condition=1}
   local m=add('Muscle',b.x,b.y,b.id,{origin=last,insertion=b.id,mass=(.15+e[16]*.4)*quality,force=(.3+e[2])*(.7+e[1]*.3)*quality,efficiency=.4+e[3]*.6,energyCost=.1+e[1]*.2,fatigue=0,region='limb',side=side,segment=segment});a.muscles[#a.muscles+1]=m
   local sk=add('Skin',b.x,b.y,b.id,{mass=.06,thickness=1+e[18]*2,toughness=.2+e[18]*.8,region='limb',side=side,segment=segment});a.skin[#a.skin+1]=sk;last=b.id
  end
 end end
 local organData={{'Brain',n,0,22},{'Heart',2,0,19},{'Lung',2,-1,20},{'Lung',2,1,20},{'Stomach',3,0,21}}
 for _,d in ipairs(organData) do local bone=a.bones[d[2]];local o=add(d[1],bone.x,d[3]*16,bone.id,{mass=d[1]=='Stomach' and .7 or .4,capacity=(.25+e[d[4]])*(d[1]=='Lung' and 2.6 or 5)*quality,efficiency=.45+e[d[4]]*.55,region=d[1]=='Brain' and 'head' or 'torso',tissue=d[1]=='Stomach' and 'Epithelial/digestive' or d[1]=='Brain' and 'Nerve' or d[1]=='Heart' and 'Muscle/Blood' or 'Epithelial/Blood'});a.organs[#a.organs+1]=o end
 local brain,heart;for _,o in ipairs(a.organs) do if o.type=='Brain' then brain=o elseif o.type=='Heart' then heart=o end end
 for _,c in ipairs(a.bones) do a.nerves[#a.nerves+1]={from=brain.id,to=c.id,efficiency=.25+e[22]*.75,condition=1};a.vessels[#a.vessels+1]={from=heart.id,to=c.id,capacity=heart.capacity/#a.bones,condition=1} end
 a.tissues={Stem=.1*(1+e[6]),Muscle=#a.muscles,Blood=#a.vessels,Nerve=#a.nerves,Epithelial=#a.skin,Structural=#a.bones,Adipose=#a.fat}
 a.caps=A.capabilities(a,genome);a.viable,a.failures=A.validate(a);return a
end
function A.capabilities(a,g)
 local e=G.express(g);local mass,force,bones,skin,fat=0,0,0,0,0;local heart,lungs,digest,neural=0,0,0,0
 for _,c in ipairs(a.components) do mass=mass+c.mass;if c.type=='Bone' then bones=bones+c.strength*c.condition elseif c.type=='Muscle' then force=force+c.mass*c.force*c.condition*c.efficiency elseif c.type=='Skin' then skin=skin+c.toughness*c.condition elseif c.type=='Fat' then fat=fat+c.capacity*c.condition elseif c.type=='Heart' then heart=heart+c.capacity*c.condition elseif c.type=='Lung' then lungs=lungs+c.capacity*c.condition elseif c.type=='Stomach' then digest=digest+c.capacity*c.efficiency*c.condition elseif c.type=='Brain' then neural=c.efficiency*c.condition end end
 local joints=0;for _,j in ipairs(a.joints) do joints=joints+j.mobility*j.condition end;joints=joints/math.max(1,#a.joints)
 local connectivity=0;for _,n in ipairs(a.nerves) do connectivity=connectivity+n.efficiency*n.condition end;connectivity=connectivity/math.max(1,#a.nerves)
 local supply=math.min(1,heart/math.max(1,mass*.25),lungs/math.max(1,mass*.25));local support=math.min(1,bones/math.max(1,mass*1.1));local coordination=connectivity*neural
 local stride=0;for _,b in ipairs(a.bones) do if b.region=='limb' then stride=stride+b.length*b.condition end end;stride=stride/math.max(1,#a.joints)/16
 local c={mass=mass,force=force*support*coordination,support=support,circulation=heart,respiration=lungs,supply=supply,coordination=coordination,skin=skin/#a.skin,fatCapacity=fat,metabolicDemand=.18+mass*.018+force*.012+e[1]*.12,digestion=digest,perception=.08+e.perception*.32*neural,immunity=e.immunity,lifespan=230+e[6]*240,fitness=e.fitness,stride=stride}
 c.speed=(.012+math.sqrt(force/math.max(1,mass))*.065)*stride*joints*coordination*support*(.6+e[9]*.4)
 c.maxHealth=65+mass*2+e[5]*45;c.endurance=(.25+e[7])*(.3+supply)*50;c.energyCapacity=100+fat;c.tolerance=(e[10]+e[18]+e[6])/3;c.growthRate=.012+e[6]*.01;c.mentalCondition=coordination*(.5+e[4]*.5);return c
end
function A.validate(a)
 local failures={};local c=a.caps
 if c.circulation<.2 then failures[#failures+1]='Essential circulation failed' end
 if c.respiration<.2 then failures[#failures+1]='Insufficient respiratory exchange' end
 if c.supply<.22 then failures[#failures+1]='Heart/lung supply cannot sustain developed tissue mass' end
 if c.digestion<.1 then failures[#failures+1]='No functional nutrient acquisition' end
 if c.support<.17 then failures[#failures+1]='Skeleton cannot support body mass' end
 if c.coordination<.035 then failures[#failures+1]='Neural network cannot coordinate tissues' end
 local seen={};for _,o in ipairs(a.organs) do local key=o.x..':'..o.y;if seen[key] then failures[#failures+1]='Organ cavities overlap' end;seen[key]=true;if math.abs(o.x)>a.segments*8 or math.abs(o.y)>16 then failures[#failures+1]='Organ lies outside protected cavity' end end
 return #failures==0,failures
end
function A.damage(a,region,amount)
 for _,c in ipairs(a.components) do if c.region==region or c.type==region then c.condition=math.max(0,c.condition-amount) end end
 for _,j in ipairs(a.joints) do if region=='limb' then j.condition=math.max(0,j.condition-amount) end end
end
return A
