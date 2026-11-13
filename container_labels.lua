local U=require('utf8');local L={limit=40}
function L.record(s,kind,id)
 local list=kind=='dna' and s.materials or s.vessels
 for _,record in ipairs(list or {}) do if record.id==id then return record end end
end
function L.input(value)
 value=tostring(value or ''):gsub('[%c]',' ')
 if not U.len(value) then return nil,'Label contains invalid text.' end
 local stop=U.offset(value,L.limit+1);if stop then value=value:sub(1,stop-1) end
 return value
end
function L.clean(value) local clean,why=L.input(value);if not clean then return nil,why end;return clean:match('^%s*(.-)%s*$') end
function L.set(s,kind,id,value)
 local record=L.record(s,kind,id);if not record then return false,'This container is unavailable.' end
 local clean,why=L.clean(value);if not clean then return false,why end
 record.label=clean~='' and clean or nil;return true,record.label and ('Container labeled: '..record.label) or 'Custom label cleared.'
end
function L.backspace(value) local at=U.offset(value,-1);return at and value:sub(1,at-1) or '' end
function L.fit(value,font,width)
 value=tostring(value or '');if font:getWidth(value)<=width then return value end
 while value~='' and font:getWidth(value..'...')>width do value=L.backspace(value) end
 return value..'...'
end
return L
