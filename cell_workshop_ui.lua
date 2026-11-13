local D=require('workshop_docking');local W=require('cell_workshop');local F=require('physical_cells');local V=require('vessels');local UI={}
function UI.draw(s,o,ui)
 local text,button=ui.text,ui.button;local function run(fn) local ok,why=fn();ui.result(o,ok,why);require('desktop_host').sync() end
 local slots=D.slotRects(o)
 for _,slot in ipairs({'input','output'}) do local r=slots[slot];local v,object=D.container(s,o.id,slot);local shade=slot=='input' and {.25,.76,.67} or {.9,.69,.3}
  love.graphics.setColor(.07,.12,.14);love.graphics.rectangle('fill',r.x,r.y,r.w,r.h,12);love.graphics.setColor(shade);love.graphics.setLineWidth(2);love.graphics.rectangle('line',r.x+1,r.y+1,r.w-2,r.h-2,12)
  text(slot=='input' and 'INPUT / CELL SOURCE' or 'OUTPUT / EMPTY CONTAINER',r.x+10,82,13,shade)
  text(v and ('Container #'..v.id..' / '..V.count(v)..' cell(s)') or 'DRAG A CONTAINER HERE',r.x+12,r.y+17,13,shade)
  if not v then text(slot=='input' and 'Must contain a cell.' or 'Must be empty.',r.x+26,r.y+150,14,{.6,.73,.73}) end
  if v then text(v.contents[1] and F.label(v.contents[1].cell) or 'Ready for processed cells',r.x+10,r.y+r.h-28,12,{.7,.84,.82});button('Detach '..slot..' container',r.x,474,r.w,35,function() D.detach(s,object.id);W.log(s,o.id,'Container #'..v.id..' detached; contents unchanged.') end) end
 end
 love.graphics.setColor(.015,.033,.035);love.graphics.rectangle('fill',282,86,486,225,8);love.graphics.setColor(.22,.45,.4);love.graphics.rectangle('line',282.5,86.5,485,224,8)
 text('CELL WORKSHOP / TERMINAL',298,101,14,{.48,.92,.7});text('No cell inventory inside this machine.',298,126,12,{.48,.66,.61})
 local entries=o.config.terminal or {'Attach a cell container to INPUT.','Attach an empty container to OUTPUT.','Extraction archives DNA and keeps its source.','Installation and precursor prep use one input cell.'}
 local row=0;for i=1,#entries do local _,wrapped=love.graphics.getFont():getWrap('> '..tostring(entries[i]),450);for _,line in ipairs(wrapped) do if row<6 then text(line,298,155+row*23,12,{.52,.88,.69});row=row+1 end end;if row>=6 then break end end
 button('Extract DNA to genome archive',285,330,480,39,function() run(function() return W.extract(s,o.id) end) end)
 local dna;for _,record in ipairs(s.materials) do if record.id==o.config.genomeId then dna=record;break end end
 button(dna and ('DNA #'..dna.id..': '..(dna.name or 'Archived genome')..' / choose') or 'Choose an archived genome...',285,382,480,35,function() require('desktop_supply_menus').genome(s,o) end)
 button('Install selected DNA / uses 1 blank cell',285,430,480,39,function() run(function() return W.install(s,o.id) end) end)
 button('Prepare egg / uses 1 stem cell',285,485,233,43,function() run(function() return W.precursor(s,o.id,'Egg') end) end)
 button('Prepare sperm / uses 1 stem cell',532,485,233,43,function() run(function() return W.precursor(s,o.id,'Sperm') end) end)
 text('Cells stay in their attached containers.',300,552,13,{.56,.77,.75});text('Buy cells and empty containers from the tray menu.',285,575,12,{.56,.77,.75})
end
return UI
