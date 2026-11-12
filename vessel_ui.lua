local V=require('vessels')
local UI={selected=1,kind=1,medium=1,page=1}
function UI.draw(s,c)
 V.ensure(s)
 local text,button,panel,msg,C,B=c.text,c.button,c.panel,c.msg,c.C,c.B
 panel(314,202,760,650);panel(1094,202,314,650)
 text('CELL WORKSTATIONS',340,225,28)
 text('Reusable vessels / grow, transfer, freeze, store, clean and sell cultures.',340,265,13,C.muted)
 text('Credits '..s.credits..'    |    '..#s.vessels..' vessels    |    '..#s.cells..' loose cells',340,300,14,C.mint)
 local names={'Petri','Flask','Plate','Storage','Cryovial'}
 for i,n in ipairs(names) do button(n,340+(i-1)*144,337,135,32,function() UI.kind=i end,UI.kind==i) end
 button('Buy empty vessel ('..V.types[UI.kind].price..')',340,377,348,36,function() local ok,why=V.add(s,UI.kind);msg(why) end)
 local pages=math.max(1,math.ceil(#s.vessels/8));UI.page=math.min(UI.page,pages)
 for row=0,7 do
  local index=(UI.page-1)*8+row+1;local v=s.vessels[index]
  if v then
   local yy=433+row*43;local n=V.count(v)
   button('',340,yy,707,37,function() UI.selected=index end,UI.selected==index)
   text('#'..v.id..' '..V.types[v.kind].name,351,yy+4,13,UI.selected==index and C.bg or C.text)
   text(n..'/'..V.types[v.kind].capacity..' cells',627,yy+4,12,UI.selected==index and C.bg or C.muted)
   text(v.frozen and 'FROZEN' or v.cultivating and 'GROWING' or n==0 and 'EMPTY' or 'STORED',807,yy+4,12,UI.selected==index and C.bg or C.mint)
  end
 end
 button('Previous',340,795,110,31,function() UI.page=math.max(1,UI.page-1) end)
 text(UI.page..' / '..pages,469,802,13,C.muted)
 button('Next',530,795,110,31,function() UI.page=math.min(pages,UI.page+1) end)
 local v=s.vessels[UI.selected]
 text('VESSEL INSPECTOR',1116,225,13,C.mint)
 if not v then text('Select a vessel to manage.',1116,270,14,C.muted);return end
 local def=V.types[v.kind];text(def.name..' #'..v.id,1116,268,20)
 text('Population: '..V.count(v)..' / '..def.capacity,1116,305,13)
 text('Status: '..(v.frozen and 'Frozen' or v.cultivating and 'Cultivating' or 'Available'),1116,332,13,C.muted)
 local bucket=v.contents[1]
 if bucket then text(B.types[bucket.cell.type]..' / '..(bucket.cell.name or 'Unknown'),1116,365,13,C.mint)
  text('Genome '..require('genome').marker(bucket.cell.genome),1116,389,12,C.muted)
 else text('Empty, clean vessel',1116,365,13,C.muted) end
 button('Add selected cell',1116,427,268,34,function()
  local ok,why=V.transfer(s,c.selected,UI.selected);if ok then c.clearSelection() end;msg(why)
 end,nil,not c.selected or v.frozen)
 button('Withdraw one cell',1116,468,268,34,function() local ok,why=V.withdraw(s,UI.selected);msg(why) end,nil,v.frozen or not bucket)
 button('Culture medium: '..({'Balanced','Rich','Mutagenic'})[UI.medium],1116,509,268,34,function() UI.medium=UI.medium%3+1 end)
 button('Add food',1116,550,268,34,function()
  local ok,why=V.feed(s,UI.selected);msg(why)
 end,nil,v.frozen or def.growth==0 or not bucket)
 button(v.frozen and 'Thaw entire cryovial' or 'Freeze entire cryovial',1116,591,268,34,function()
  local ok,why;if v.frozen then ok,why=V.thaw(s,UI.selected) else ok,why=V.freeze(s,UI.selected) end;msg(why)
 end,nil,v.kind~=5 or not bucket)
 button('Empty / clean / reuse',1116,638,268,34,function() local ok,why=V.discard(s,UI.selected);msg(why) end)
 button('Sell vessel and contents',1116,681,268,34,function() local ok,why=V.sellVessel(s,UI.selected);UI.selected=math.min(UI.selected,#s.vessels);msg(why) end)
 button('Sell selected loose cell',1116,728,268,34,function()
  local ok,why=V.sellCell(s,c.selected);if ok then c.clearSelection() end;msg(why)
 end,nil,not c.selected)
 text(V.timerText(v),1116,798,12,C.muted)
end
return UI

