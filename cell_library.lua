local L={filter=0,sort=1,favoritesOnly=false,page=1}
L.sortNames={'Type / strain','Viability','Recent mutations','Generation'}
function L.indices(s)
 local list={};for i,c in ipairs(s.cells) do if (L.filter==0 or c.type==L.filter) and (not L.favoritesOnly or c.favorite) then list[#list+1]=i end end
 table.sort(list,function(i,j) local a,b=s.cells[i],s.cells[j]
  if L.sort==2 and a.viability~=b.viability then return a.viability>b.viability elseif L.sort==3 and a.mutated~=b.mutated then return a.mutated elseif L.sort==4 and a.generation~=b.generation then return a.generation>b.generation end
  if a.type~=b.type then return a.type<b.type end;if a.strain~=b.strain then return a.strain<b.strain end;return a.id<b.id
 end);return list
end
function L.draw(s,x,y,w,h,c)
 local text,button,panel,col=c.text,c.button,c.panel,c.col;local C,B=c.C,c.B;panel(x,y,w,h);text('STRAIN COLLECTION',x+17,y+17,13,C.mint);text('Grouped by cell type and lineage',x+17,y+42,11,C.muted)
 button('+ Purchase DNA vial',x+16,y+71,w-32,35,function() local vial,why=require('lab_engineering').buyVial(s);if vial then c.msg('DNA vial acquired. Open Genome laboratory to engineer cells.') else c.msg(why) end end)
 button(L.filter==0 and 'All cell types' or B.types[L.filter],x+16,y+119,w-76,30,function() L.filter=(L.filter+1)%8;L.page=1 end,L.filter~=0)
 button('Fav',x+w-52,y+119,36,30,function() L.favoritesOnly=not L.favoritesOnly;L.page=1 end,L.favoritesOnly)
 button('Sort: '..L.sortNames[L.sort],x+16,y+158,w-32,29,function() L.sort=L.sort%#L.sortNames+1;L.page=1 end)
 local list=L.indices(s);local pages=math.max(1,math.ceil(#list/10));L.page=math.min(L.page,pages)
 for row=0,9 do local index=list[(L.page-1)*10+row+1];if index then local v=s.cells[index];local yy=y+199+row*38;local donor=false;for _,id in ipairs(c.donors) do if id==v.id then donor=true end end
  button('',x+16,yy,w-76,34,function() c.select(index) end,c.selected==index)
  text((donor and '+ ' or '')..B.types[v.type]..' / '..v.id,x+23,yy+3,12,c.selected==index and C.bg or B.colors[v.type])
  text((v.name or 'Strain '..v.strain):sub(1,16)..'  G'..v.generation..'  '..math.floor(v.viability*100)..'%',x+23,yy+20,11,c.selected==index and C.bg or C.muted)
  button('*',x+w-52,yy,36,34,function() v.favorite=not v.favorite end,v.favorite)
 end end
 button('<',x+16,y+h-48,44,29,function() L.page=math.max(1,L.page-1) end);button('>',x+w-60,y+h-48,44,29,function() L.page=math.min(pages,L.page+1) end)
 if #list==0 then text('No matching cells. Change filters.',x+17,y+230,12,C.muted) end
 text('* favorite  /  filters keep genomes intact',x+17,y+h-17,11,C.muted)
 text(L.page..' / '..pages..'   '..#list..' cells',x+76,y+h-40,11,C.muted)
end
return L
