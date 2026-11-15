local H=dofile('tests/kernel_harness.lua');local W=dofile('tests/kernel_worker_harness.lua');local clock=W.clock()
local env=H.environment();env.string.strsplit=function(sep,text)local out={};for p in text:gmatch('[^'..sep..']+')do out[#out+1]=p end;return table.unpack(out)end
local pending,events,removed={},{},0;local n={};for k,v in pairs(clock.native)do n[k]=v end
n.GetConvar=function(key,default)return ({['ox:logger']='fivemanage',['fivemanage:key']='test-only',['sv_projectName']='Test'})[key]or default end
n.GetPlayerName=function()return'Test'end;n.GetNumPlayerIdentifiers=function()return 1 end;n.GetPlayerIdentifier=function()return'license:test'end
n.GetInvokingResource=function()return'test-consumer'end;n.GetGameTimer=function()return clock.now end
n.PerformHttpRequest=function(url,cb,...)pending[#pending+1]={url=url,callback=cb};return nil,false end
local codec={encode=function()return'test-json'end,decode=function(v)return v end}
local f={Side='server',IsCurrent=function()return true end,Seed={IO={Codec=codec},Library={Cache={resource='forge-core'},Library={print={warn=function()end,error=function()end}}}}}
local p={foundation=f,native=n,events={listen=function(name,fn)local t={name=name,fn=fn};events[#events+1]=t;return t end,
 remove=function()removed=removed+1 end,source=function()return 7 end},clock={time=function()return 10 end,date=os.date,microtime=function()return clock.now*1000 end},
 loadPR=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end,createTasks=W.create,
 running=coroutine.running,onError=error,environment=env,checkDependency=function()return true end}
local a=H.load('../pr_bridge/bridge/delivery/forge_logging_ports.lua',H.environment())(p)
assert(#events==0 and #clock.queue==0 and #pending==0);assert(a.Open()and #events==1 and events[1].name=='playerDropped')
local delivery=H.load('../pr_bridge/bridge/logging/forge_delivery.lua',H.environment())(a.DeliveryPorts);assert(delivery.Open())
delivery.LibraryLogger(7,'test','message');assert(#pending==0);clock.advance(500);assert(#pending==1 and a.Progress().pendingHTTP==1)
assert(not a.Close()and removed==1);pending[1].callback(200,'',{},'');assert(a.Close()and a.Progress().complete)
assert(not pcall(a.DeliveryPorts.logger,7,'test','closed'));delivery.Close()
print('PASS193 installed PR logger/provider;deferred owned playerDropped,timer,accepted HTTP drain,late callback suppression and hook/logger ports')
