local inputName,outputName,root=...;local input=love.thread.getChannel(inputName);local output=love.thread.getChannel(outputName)
local engine
local ok,why=xpcall(function()
 engine=require('assistant_nlu').open(root);local index=require('assistant_index');local C=require('assistant_classifier');output:push({type='ready',runtime=engine.version})
 while true do local request=input:demand();if request.type=='stop' then break end
  if request.type=='question' then local success,result=xpcall(function() return C.classify(engine,index,request.text) end,debug.traceback);output:push(success and {type='answer',id=request.id,classification=result} or {type='error',id=request.id,message=tostring(result)}) end
 end
end,debug.traceback)
if engine then engine.close() end;if not ok then output:push({type='error',message=tostring(why)}) end
