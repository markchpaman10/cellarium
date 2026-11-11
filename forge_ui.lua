local G=require('genome');local A=require('anatomy');local U=require('units');local R=require('rendering')
local F={settings={recombination='majority',exposure=0,nutrition=1,minerals=1,oxygen=1,temperature=37,release='auto'},cacheKey=nil}
function F.draw(s,c)
 for i=#c.donors,1,-1 do local found=false;for _,cell in ipairs(s.cells) do if cell.id==c.donors[i] then found=true;break end end;if not found then table.remove(c.donors,i) end end
 local text,button,panel,col,msg=c.text,c.button,c.panel,c.col,c.msg;local B,C=c.B,c.C;local settings=F.settings;panel(314,202,760,650);panel(1094,202,314,650)
 text('ORGANISM ENGINEERING',340,225,28)
 text('Combine 2-12 donor genomes. For an exact edited genome, use the DNA template workflow.',340,269,12,C.muted)
 text(#c.donors..' / 12 donors selected',340,304,14,C.mint)
 button('+ Add selected cell',775,301,273,33,function()
  local v=c.selected and s.cells[c.selected]
  if not v then msg('Select a cell from the collection first.');return end
  if #c.donors>=12 then msg('Maximum 12 donors.');return end
  for _,id in ipairs(c.donors) do if id==v.id then msg('Donor already selected.');return end end
  c.donors[#c.donors+1]=v.id;F.cacheKey=nil
 end,nil,#c.donors>=12)
 for i=1,12 do
  local x=340+(i-1)%6*119;local y=344+math.floor((i-1)/6)*54
  local donor
  for _,v in ipairs(s.cells) do if v.id==c.donors[i] then donor=v;break end end
  if donor then
   button(B.types[donor.type]..' '..donor.id,x,y,113,24,function() table.remove(c.donors,i);F.cacheKey=nil end,true)
   text('Remove donor',x+9,y+28,11,C.muted)
  else
   button('+ slot '..i,x,y,113,24,function()
    local v=c.selected and s.cells[c.selected]
    if not v then msg('Select a cell first.');return end
    if #c.donors>=12 then return end
    for _,id in ipairs(c.donors) do if id==v.id then msg('Donor already selected.');return end end
    c.donors[#c.donors+1]=v.id;F.cacheKey=nil
   end)
  end
 end
 local specs={{'Recombination','recombination',{'majority','mosaic'}},{'Mutation exposure','exposure',{0,.006,.025}},{'Nutrition','nutrition',{.55,.8,1}},{'Mineral supply','minerals',{.5,1,1.4}},{'Oxygen supply','oxygen',{.65,1,1.25}},{'Incubation','temperature',{33,37,40}},{'Release environment','release',{'auto','land','freshwater','saltwater','shore','ridge'}}}
 for i,spec in ipairs(specs) do local x=340+(i-1)%3*236;local y=486+math.floor((i-1)/3)*75;local key=spec[2];text(spec[1],x,y,12,C.muted)
  local value=key=='temperature' and U.temperature(settings[key]) or key=='exposure' and (settings[key]==0 and 'None' or settings[key]==.006 and 'Mild' or 'Strong / more risk') or type(settings[key])=='number' and string.format('%.0f%%',settings[key]*100) or settings[key]
  button(tostring(value)..' >',x,y+23,221,32,function() local index=1;for j,v in ipairs(spec[3]) do if v==settings[key] then index=j end end;settings[key]=spec[3][index%#spec[3]+1] end)
 end
 text('Nutrition changes tissue growth. Minerals change covering mass and hardness.\nOxygen and warmth affect development. Exposure alters heritable alleles.',340,723,12,C.muted)
 button('Assemble genome & incubate',340,780,708,48,function() local ok,why=B.combine(s,c.donors,settings);if ok then c.finished();F.cacheKey=nil;msg('Zygote created with your recorded development conditions.') else msg(why) end end,#c.donors>=2,#c.donors<2)
 text('DEVELOPMENT FORECAST',1116,225,13,C.mint)
 local genomes={};for _,id in ipairs(c.donors) do for _,cell in ipairs(s.cells) do if id==cell.id then genomes[#genomes+1]=cell.genome end end end
 if #genomes>=2 then
  local g=G.fuse(genomes,settings);local key=G.hash(g)..'/'..settings.temperature..'/'..settings.nutrition..'/'..settings.minerals..'/'..settings.oxygen
  if F.cacheKey~=key then F.preview=A.generate(g,settings);F.genome=g;F.cacheKey=key end
  local a=F.preview;local caps=a.caps;R.draw({anatomy=a,caps=caps,angle=0,alive=true,maturity=1,behavior='Resting'},1250,365,R.fitScale(a,255,180,3),0,'External')
  text(a.viable and 'Viable developmental forecast' or 'Development may fail',1116,477,14,a.viable and C.mint or {1,.5,.4})
  for i,kind in ipairs({'land','freshwater','saltwater','flight'}) do text(kind,1116,516+(i-1)*32,12,C.muted);col(C.line);love.graphics.rectangle('fill',1214,521+(i-1)*32,116,5);col(C.mint);love.graphics.rectangle('fill',1214,521+(i-1)*32,116*caps.compatibility[kind],5);text(math.floor(caps.compatibility[kind]*100)..'%',1337,515+(i-1)*32,11,C.muted) end
  text(string.format('Mass %.1f / upkeep %.2f\n%d inherited mutation records\nAir %.1f / aquatic %.1f exchange',caps.mass,caps.metabolicDemand,#g.mutations,caps.airRespiration,caps.aquaticRespiration),1116,657,12,C.muted)
  if not a.viable then text((a.failures[1] or ''):sub(1,39),1116,730,12,{1,.5,.4}) end
 else text('Select at least two donors to preview\nthe actual inherited genome,\nbody plan, respiratory potential\nand environmental compatibility.\n\nNo species or body part is selected.\nGenes construct the organism.',1116,306,14,C.muted) end
 if #s.eggs>0 then local egg=s.eggs[1];text('INCUBATING '..#s.eggs..' / '..egg.stage,1116,780,12,C.mint);col(C.line);love.graphics.rectangle('fill',1116,814,268,5);col(C.mint);love.graphics.rectangle('fill',1116,814,268*egg.progress,5) end
end
return F
