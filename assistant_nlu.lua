-- Local MiniLM embeddings through ONNX Runtime's versioned native C API.
-- No HTTP client, external process, API key or text-generation model.
local ffi=require('ffi');local N={dimension=384,maxTokens=256}
ffi.cdef[[
typedef struct OrtEnv OrtEnv;typedef struct OrtSession OrtSession;typedef struct OrtSessionOptions OrtSessionOptions;typedef struct OrtValue OrtValue;typedef struct OrtMemoryInfo OrtMemoryInfo;typedef struct OrtStatus OrtStatus;typedef struct OrtTensorTypeAndShapeInfo OrtTensorTypeAndShapeInfo;
typedef struct {const void* (__stdcall *GetApi)(uint32_t);const char* (__stdcall *GetVersionString)(void);} CellOrtApiBase;
const CellOrtApiBase* __stdcall OrtGetApiBase(void);
int __stdcall MultiByteToWideChar(unsigned int,unsigned long,const char*,int,uint16_t*,int);
int __stdcall WideCharToMultiByte(unsigned int,unsigned long,const uint16_t*,int,char*,int,const char*,int*);
int __stdcall NormalizeString(int,const uint16_t*,int,uint16_t*,int);
]]
local kernel=ffi.load('kernel32');local normaliz=ffi.load('normaliz')
local function wide(text) local n=kernel.MultiByteToWideChar(65001,0,text,#text,nil,0);assert(n>0,'Invalid UTF-8');local w=ffi.new('uint16_t[?]',n+1);assert(kernel.MultiByteToWideChar(65001,0,text,#text,w,n)>0);return w,n end
local function normalize(text)
 local w,n=wide(text);local count=normaliz.NormalizeString(2,w,n,nil,0);if count>0 then local result=ffi.new('uint16_t[?]',count+4);count=normaliz.NormalizeString(2,w,n,result,count+4);if count>0 then local nbytes=kernel.WideCharToMultiByte(65001,0,result,count,nil,0,nil,nil);local out=ffi.new('char[?]',nbytes);kernel.WideCharToMultiByte(65001,0,result,count,out,nbytes,nil,nil);text=ffi.string(out,nbytes) end end
 -- BERT uncased: lowercase ASCII and remove decomposed combining accents.
 text=text:lower():gsub('[\204\205][\128-\191]','');return text
end
local function basic(text)
 local words={};local buffer='';local function flush() if #buffer>0 then words[#words+1]=buffer;buffer='' end end
 text=normalize(text)
 for i=1,#text do local b=text:byte(i);local c=text:sub(i,i)
  if b<=32 or b==127 then flush() elseif (b>=33 and b<=47) or (b>=58 and b<=64) or (b>=91 and b<=96) or (b>=123 and b<=126) then flush();words[#words+1]=c else buffer=buffer..c end
 end;flush();return words
end
function N.tokenizer(path)
 local vocab={};local id=0;for line in assert(io.lines(path)) do vocab[line:gsub('\r$','')]=id;id=id+1 end
 assert(vocab['[CLS]']==101 and vocab['[SEP]']==102 and id>30000,'Unexpected MiniLM vocabulary')
 return function(text)
  local ids={101}
  for _,word in ipairs(basic(text)) do
   if #word>100 then ids[#ids+1]=100 else
    local pieces={};local start=1
    while start<=#word do local ending=#word;local found
     while ending>=start do local piece=word:sub(start,ending);if start>1 then piece='##'..piece end;local value=vocab[piece];if value then found=value;break end;ending=ending-1 end
     if not found then pieces={100};break end;pieces[#pieces+1]=found;start=ending+1
    end
    for _,piece in ipairs(pieces) do ids[#ids+1]=piece end
   end
   if #ids>=N.maxTokens-1 then while #ids>N.maxTokens-1 do table.remove(ids) end;break end
  end;ids[#ids+1]=102;return ids
 end
end
function N.open(root)
 local tokenize=N.tokenizer(root..'/vocab.txt');local nativeDependencies={};for _,name in ipairs({'vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll','msvcp140_1.dll','msvcp140_2.dll','concrt140.dll'}) do nativeDependencies[#nativeDependencies+1]=ffi.load(root..'/'..name) end;local dll=ffi.load(root..'/onnxruntime.dll');local base=dll.OrtGetApiBase();local api=ffi.cast('void**',assert(base.GetApi(17),'ONNX API 17 unavailable'));local functions={}
 local specs={
  CreateEnv={3,'OrtStatus* (__stdcall *)(int,const char*,OrtEnv**)'},DisableTelemetryEvents={6,'OrtStatus* (__stdcall *)(const OrtEnv*)'},
  CreateSession={7,'OrtStatus* (__stdcall *)(const OrtEnv*,const uint16_t*,const OrtSessionOptions*,OrtSession**)'},
  Run={9,'OrtStatus* (__stdcall *)(OrtSession*,const void*,const char* const*,const OrtValue* const*,size_t,const char* const*,size_t,OrtValue**)'},
  CreateSessionOptions={10,'OrtStatus* (__stdcall *)(OrtSessionOptions**)'},SetSessionGraphOptimizationLevel={23,'OrtStatus* (__stdcall *)(OrtSessionOptions*,int)'},SetIntraOpNumThreads={24,'OrtStatus* (__stdcall *)(OrtSessionOptions*,int)'},
  CreateTensorWithDataAsOrtValue={49,'OrtStatus* (__stdcall *)(const OrtMemoryInfo*,void*,size_t,const int64_t*,size_t,int,OrtValue**)'},GetTensorMutableData={51,'OrtStatus* (__stdcall *)(OrtValue*,void**)'},
  GetDimensionsCount={61,'OrtStatus* (__stdcall *)(const OrtTensorTypeAndShapeInfo*,size_t*)'},GetDimensions={62,'OrtStatus* (__stdcall *)(const OrtTensorTypeAndShapeInfo*,int64_t*,size_t)'},GetTensorTypeAndShape={65,'OrtStatus* (__stdcall *)(const OrtValue*,OrtTensorTypeAndShapeInfo**)'},
  CreateCpuMemoryInfo={69,'OrtStatus* (__stdcall *)(int,int,OrtMemoryInfo**)'},GetErrorMessage={2,'const char* (__stdcall *)(const OrtStatus*)'},
  ReleaseEnv={92,'void (__stdcall *)(OrtEnv*)'},ReleaseStatus={93,'void (__stdcall *)(OrtStatus*)'},ReleaseMemoryInfo={94,'void (__stdcall *)(OrtMemoryInfo*)'},ReleaseSession={95,'void (__stdcall *)(OrtSession*)'},ReleaseValue={96,'void (__stdcall *)(OrtValue*)'},ReleaseTensorTypeAndShapeInfo={99,'void (__stdcall *)(OrtTensorTypeAndShapeInfo*)'},ReleaseSessionOptions={100,'void (__stdcall *)(OrtSessionOptions*)'}
 }
 for name,spec in pairs(specs) do functions[name]=ffi.cast(spec[2],api[spec[1]]) end
 local function check(status) if status~=nil then local message=ffi.string(functions.GetErrorMessage(status));functions.ReleaseStatus(status);error(message,2) end end
 local env,session,options,mem=ffi.new('OrtEnv*[1]'),ffi.new('OrtSession*[1]'),ffi.new('OrtSessionOptions*[1]'),ffi.new('OrtMemoryInfo*[1]')
 local closed=false
 local function close() if closed then return end;closed=true;if session[0]~=nil then functions.ReleaseSession(session[0]) end;if options[0]~=nil then functions.ReleaseSessionOptions(options[0]) end;if mem[0]~=nil then functions.ReleaseMemoryInfo(mem[0]) end;if env[0]~=nil then functions.ReleaseEnv(env[0]) end end
 local ok,why=pcall(function() check(functions.CreateEnv(3,'CellariumOfflineNLU',env));check(functions.DisableTelemetryEvents(env[0]));check(functions.CreateSessionOptions(options));check(functions.SetIntraOpNumThreads(options[0],2));check(functions.SetSessionGraphOptimizationLevel(options[0],99));local model=wide(root..'/model.onnx');check(functions.CreateSession(env[0],model,options[0],session));check(functions.CreateCpuMemoryInfo(1,0,mem)) end)
 if not ok then close();error(why) end
 local engine={dll=dll,nativeDependencies=nativeDependencies,version=ffi.string(base.GetVersionString()),tokenize=tokenize,close=close}
 function engine.embed(text)
  assert(not closed,'NLU session closed');local ids=tokenize(text);local n=#ids;local shape=ffi.new('int64_t[2]',{1,n});local inputs=ffi.new('OrtValue*[3]');local arrays={ffi.new('int64_t[?]',n),ffi.new('int64_t[?]',n),ffi.new('int64_t[?]',n)};local output=ffi.new('OrtValue*[1]');local info=ffi.new('OrtTensorTypeAndShapeInfo*[1]')
  local ok,result=xpcall(function()
   for i=0,n-1 do arrays[1][i]=ids[i+1];arrays[2][i]=1;arrays[3][i]=0 end
   for i=0,2 do local value=ffi.new('OrtValue*[1]');check(functions.CreateTensorWithDataAsOrtValue(mem[0],arrays[i+1],n*8,shape,2,7,value));inputs[i]=value[0] end
   local names=ffi.new('const char*[3]',{'input_ids','attention_mask','token_type_ids'});local outputs=ffi.new('const char*[1]',{'last_hidden_state'});check(functions.Run(session[0],nil,names,ffi.cast('const OrtValue* const*',inputs),3,outputs,1,output));check(functions.GetTensorTypeAndShape(output[0],info));local rank=ffi.new('size_t[1]');check(functions.GetDimensionsCount(info[0],rank));assert(tonumber(rank[0])==3,'Unexpected embedding rank');local dims=ffi.new('int64_t[3]');check(functions.GetDimensions(info[0],dims,3));assert(tonumber(dims[2])==N.dimension and tonumber(dims[1])==n,'Unexpected MiniLM dimensions')
   local pointer=ffi.new('void*[1]');check(functions.GetTensorMutableData(output[0],pointer));local values=ffi.cast('float*',pointer[0]);local vector={};local norm=0
   for j=0,N.dimension-1 do local sum=0;for i=0,n-1 do sum=sum+values[i*N.dimension+j] end;local mean=sum/n;vector[j+1]=mean;norm=norm+mean*mean end;norm=math.sqrt(norm);assert(norm>0,'Empty embedding');for j=1,N.dimension do vector[j]=vector[j]/norm end;return vector
  end,debug.traceback)
  if info[0]~=nil then functions.ReleaseTensorTypeAndShapeInfo(info[0]) end;if output[0]~=nil then functions.ReleaseValue(output[0]) end;for i=0,2 do if inputs[i]~=nil then functions.ReleaseValue(inputs[i]) end end
  if not ok then error(result) end;return result
 end
 return engine
end
function N.cosine(a,b) local sum=0;for i=1,N.dimension do sum=sum+a[i]*b[i] end;return sum end
return N
