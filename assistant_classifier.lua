local N=require('assistant_nlu');local C={threshold=.44,margin=.045}
C.groups={stats='movement',culture_problem='cultivate',transfer_problem='transfer',freeze='preservation',thaw='preservation'}
function C.canonical(id) return C.groups[id] or id end
local domain={animal=true,animals=true,dish=true,dishes=true,nutrient=true,nutrients=true,cell=true,cells=true,creature=true,creatures=true,organism=true,organisms=true,genome=true,genomes=true,dna=true,genetic=true,genetics=true,gene=true,genes=true,lab=true,laboratory=true,workstation=true,workshop=true,forge=true,vial=true,vials=true,bottle=true,bottles=true,container=true,containers=true,tube=true,tubes=true,flask=true,flasks=true,petri=true,plate=true,culture=true,cultures=true,colony=true,colonies=true,dropper=true,pipette=true,sample=true,samples=true,rack=true,embryo=true,embryos=true,incubate=true,incubation=true,developmental=true,blank=true,donor=true,recipient=true,egg=true,sperm=true,gamete=true,gametes=true,breed=true,breeding=true,offspring=true,chromosome=true,chromosomes=true,allele=true,alleles=true,oxygen=true,locomotion=true,skeletal=true,skeleton=true,muscle=true,fatigue=true,credits=true,habitat=true,habitats=true,cellarium=true,jenny=true,assistant=true,freezer=true,freezing=true,cryobank=true,frozen=true,archive=true,archived=true,specimen=true,specimens=true,desktop=true,taskbar=true,tray=true,equipment=true,monitor=true,display=true,fahrenheit=true,celsius=true,sarcasm=true,sarcastic=true}
local function inScope(text)
 local lower=text:lower()
 if lower:find('cell phone',1,true) or lower:find('smartphone',1,true) or lower:find('cellphone',1,true) then return false end
 if lower:match('%f[%a]human%f[%A]') or lower:match('%f[%a]patient%f[%A]') or lower:match('%f[%a]cancer%f[%A]') or lower:match('%f[%a]steal%f[%A]') or lower:match('%f[%a]password%f[%A]') then return false end
 if lower:find('real life',1,true) or lower:find('real world',1,true) or lower:find('ignore the rules',1,true) or lower:find('ignore previous',1,true) or lower:find('execute this',1,true) then return false end
 if lower:match('^%s*hi[%s!,.]*$') or lower:match('^%s*hello') or lower:match('^%s*hey[%s!,.]*$') or lower:match('^%s*thanks') or lower:match('^%s*thank you') then return true end
 if lower:find('object',1,true) and (lower:find('front',1,true) or lower:find('behind',1,true) or lower:find('layer',1,true)) then return true end
 for word in lower:gmatch('[a-z]+') do if domain[word] then return true end end
 -- Direct questions about Jenny can omit her name. Topic confidence still applies.
 return lower:match('%f[%a]you%f[%A]')~=nil or lower:match('%f[%a]your%f[%A]')~=nil
end
function C.classify(engine,index,text)
 if not inScope(text) then return {reason='outside',score=0,margin=0,candidates={}} end
 local lower=text:lower()
 -- Explicit action/entity slots resolve simple, unambiguous requests before similarity.
 local acquisition=lower:match('%f[%a]buy%f[%A]') or lower:match('%f[%a]purchase%f[%A]') or lower:match('%f[%a]order%f[%A]')
 local equipment=lower:find('vial',1,true) or lower:find('flask',1,true) or lower:find('container',1,true) or lower:find('bottle',1,true) or lower:find('cell',1,true) or lower:find('equipment',1,true)
 local direct
 if acquisition and equipment then direct='buy'
 elseif (lower:find('turn you off',1,true) or lower:find('switch you off',1,true) or lower:find('disable jenny',1,true) or lower:find('disable the assistant',1,true)) then direct='disable'
 elseif lower:find('how many',1,true) and (lower:find('alive',1,true) or lower:find('living',1,true)) and (lower:find('specimen',1,true) or lower:find('organism',1,true) or lower:find('lab',1,true)) then direct='status'
 elseif (lower:find('another',1,true) or lower:find('different',1,true)) and (lower:find('placed',1,true) or lower:find('place ',1,true) or lower:find('move',1,true) or lower:find('transfer',1,true)) and equipment then direct='transfer' end
 if direct then return {intent=direct,reason='explicit action and entity',score=1,margin=1,candidates={}} end
 local query=engine.embed(text);local ranked={};local groups={}
 for _,topic in ipairs(index) do local score=-1;for _,vector in ipairs(topic.vectors) do score=math.max(score,N.cosine(query,vector)) end;local id=C.canonical(topic.id);if not groups[id] or score>groups[id].score then groups[id]={id=id,title=topic.title,score=score} end end
 for _,item in pairs(groups) do ranked[#ranked+1]=item end
 table.sort(ranked,function(a,b) return a.score>b.score end)
 local first,second=ranked[1],ranked[2];local delta=first.score-second.score
 local lower=text:lower();local afterInstall=first.id=='install' and (lower:match('%f[%a]after%f[%A]') or lower:match('%f[%a]already%f[%A]') or lower:match('%f[%a]next%f[%A]'))
 local phaseAmbiguity=afterInstall or ((first.id=='install' and second.id=='incubate') or (first.id=='incubate' and second.id=='install')) and delta<.10
 if afterInstall then ranked[2]={id='incubate',title='Begin incubation of an installed cell',score=second.score};second=ranked[2] end
 local entityConflict=false
 if first.id=='empty' then
  local container=false;for _,word in ipairs({'vial','bottle','container','tube','flask','dish','plate'}) do if lower:find(word,1,true) then container=true end end
  entityConflict=not container or lower:match('%f[%a]buy%f[%A]') or lower:match('%f[%a]purchase%f[%A]') or lower:match('%f[%a]order%f[%A]')
  if entityConflict then ranked[2]={id=container and 'buy' or 'status',title=container and 'Buy cells and supplies' or 'Current laboratory status',score=second.score} end
 elseif first.id=='cultivate' and (lower:find('another',1,true) or lower:find('different',1,true)) and (lower:find('placed',1,true) or lower:find('place ',1,true) or lower:find('move',1,true) or lower:find('transfer',1,true)) then entityConflict=true;ranked[2]={id='transfer',title='Transfer cells between containers',score=second.score} end
 local threshold=C.threshold;local minMargin=C.margin
 if first.id=='offline' or first.id=='time' or first.id=='depth' then threshold=.40;minMargin=.05 elseif first.id=='edit' then threshold=.42;minMargin=.08 end
 local accepted=first.id~='unknown' and first.score>=threshold and delta>=minMargin and not phaseAmbiguity and not entityConflict
 return {intent=accepted and first.id or nil,score=first.score,margin=delta,reason=first.id=='unknown' and 'outside' or first.score<threshold and 'uncertain' or (delta<minMargin or phaseAmbiguity or entityConflict) and 'ambiguous' or 'matched',candidates={first,second,ranked[3]}}
end
return C
