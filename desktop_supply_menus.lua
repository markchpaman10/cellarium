local Native=require('native_windows');local B=require('biology');local V=require('vessels');local F=require('physical_cells');local T=require('desktop_samples');local Menus={}
local function host() return require('desktop_host') end
local function perform(s,fn) if not require('realtime').sync(s,B.update) then host().message('Synchronizing PC time. Try again shortly.');return end;local ok,why=fn();host().message(why or (ok and 'Done.' or 'Unavailable.'));host().sync();host().render(true) end
function Menus.buy(s)
 local items={};for category,name in ipairs(B.types) do local typ=category;items[#items+1]={label='One '..name..' cell + vial / 1 credit',action=function() perform(s,function() return F.buy(s,typ) end) end} end
 items[#items+1]={label='One blank developmental cell + vial / 1 credit',action=function() perform(s,function() return F.buy(s,'blank') end) end};items[#items+1]={separator=true}
 for kind,def in ipairs(V.types) do local typ=kind;items[#items+1]={label='Empty '..def.name..' / '..def.price..' credits',action=function() perform(s,function() return V.add(s,typ) end) end} end
 local action=Native.menu(items);if action then action() end
end
function Menus.destination(s,frozenId)
 local record;for _,c in ipairs(s.frozen) do if c.id==frozenId then record=c;break end end;if not record then host().message('Frozen sample unavailable.');return end
 local items={};for _,v in ipairs(s.vessels) do if not v.closed and not v.frozen and V.count(v)+(record.frozenQuantity or 1)<=V.types[v.kind].capacity and (#v.contents==0 or T.equal(v.contents[1].cell,record)) then local id=v.id;items[#items+1]={label=(v.label or V.types[v.kind].name)..' #'..id..' / '..V.count(v)..' stored',action=function() perform(s,function() return T.restoreFrozen(s,frozenId,id) end) end} end end
 if #items==0 then host().message('No open compatible container has space. Buy or empty a container first.');return end
 local action=Native.menu(items);if action then action() end
end
function Menus.frozen(s)
 local items={};for _,c in ipairs(s.frozen) do local id=c.id;items[#items+1]={label='#'..id..' / '..F.label(c)..' / '..(c.frozenQuantity or 1)..' cell(s)',action=function() Menus.destination(s,id) end} end
 if #items==0 then host().message('Frozen storage is empty. Freeze a loaded dropper sample first.');return end
 local action=Native.menu(items);if action then action() end
end
function Menus.genome(s,station)
 local items={};for _,dna in ipairs(s.materials) do local id=dna.id;items[#items+1]={label='#'..id..' / '..(dna.name or 'Archived DNA'),action=function() station.config.genomeId=id;require('cell_workshop').log(s,station.id,'Selected archived DNA #'..id..'.') end} end
 if #items==0 then require('cell_workshop').log(s,station.id,'No archived DNA. Extract a genome from an attached cell or archive one in the Forge.');return end
 local action=Native.menu(items);if action then action() end
end
return Menus
