local H=dofile('tests/kernel_harness.lua');local factory=H.load('kernel/entry/resource_stop_ports.lua',H.environment());local cases=0
local function setup(before)
    local r={};r.input={registration={native={GetCurrentResourceName=function()return'forge-core'end,
        AddEventHandler=function(name,fn)r[name]=fn;return'handle'end}}}
    r.api=factory(r.input,'client',before);r.add=r.api.Bootstrap.registration.native.AddEventHandler;return r
end
do local fn=function()end;local r=setup(function()error('unexpected')end);r.add('other',fn);assert(r.other==fn);r.other();assert(r.api.Progress().signals==0);cases=cases+1 end
do local called=0;local r=setup(function()error('cleanup failure')end);r.add('onClientResourceStop',function()called=called+1 end)
r.onClientResourceStop('forge-core');assert(called==1 and r.api.Progress().failures==1)
local snapshot=r.api.Progress();snapshot.errors[1]='changed';assert(r.api.Progress().errors[1]~='changed');cases=cases+1 end
do local called=0;local r=setup(function()return false end);r.add('onClientResourceStop',function()called=called+1;error('body failure')end)
local ok,err=pcall(r.onClientResourceStop,'forge-core');assert(not ok and tostring(err):find('body failure')and called==1 and r.api.Progress().failures==1);cases=cases+1 end
do local r;local before=0;r=setup(function()before=before+1;r.onClientResourceStop('forge-core');return true end)
local body=0;r.add('onClientResourceStop',function()body=body+1 end);r.onClientResourceStop('forge-core');assert(before==1 and body==2 and r.api.Progress().pending==0);cases=cases+1 end
do assert(not pcall(factory,{registration={native={GetCurrentResourceName=function()return'foreign'end}}},'client',function()return true end))
assert(not pcall(factory,{},'wrong',function()return true end));cases=cases+1 end
assert(cases==5);print('PASS157 five scope checks:other events,failing cleanup,false/body error,reentry,resource/side')
