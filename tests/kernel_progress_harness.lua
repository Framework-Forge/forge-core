local H=dofile('tests/kernel_harness.lua');local T={H=H,path='../pr_bridge/bridge/delivery/forge_client_progress.lua'}
function T.new(wrapped)
    local r={now=0,current=true,trace={},handlers={},serial=0,state={invBusy='before'},dead=false,invokeOwner=nil}
    local function record(...)r.trace[#r.trace+1]=table.pack(...)end
    local function listen(name,fn)r.serial=r.serial+1;r.handlers[r.serial]={name,fn};return r.serial end
    local function remove(token)if r.refuseRemove then return false end;r.handlers[token]=nil;return true end
    local function vector(x,y,z)return setmetatable({x=x,y=y,z=z},{__sub=function(a,b)return vector(a.x-b.x,a.y-b.y,a.z-b.z)end})end
    local stream={requestModel=function(m)record('requestModel',m);return true,m end,releaseModel=function(m)record('releaseModel',m)end,
        requestAnimDict=function(d)record('requestAnim',d);return true end,releaseAnimDict=function(d)record('releaseAnim',d)end}
    local env=H.environment({LocalPlayer={state=r.state},GetCurrentResourceName=function()return'forge-core'end,GetInvokingResource=function()return r.invokeOwner end,
        GetGameTimer=function()return r.now end,PlayerPedId=function()return 12 end,PlayerId=function()return 2 end,
        IsEntityDead=function()return r.dead end,IsPedRagdoll=function()return false end,IsPedCuffed=function()return false end,IsPedFalling=function()return false end,IsPedSwimming=function()return false end,
        IsModelAPed=function()return false end,IsModelAVehicle=function()return false end,GetModelDimensions=function()return vector(0,0,0),vector(1,1,1)end,
        IsControlJustPressed=function()return r.cancelKey end,Wait=function()coroutine.yield('frame')end,
        AddEventHandler=listen,TaskPlayAnim=function(...)record('anim',...)end,TaskStartScenarioInPlace=function(...)record('scenario',...)end,
        StopAnimTask=function(...)record('stopAnim',...)end,ClearPedTasks=function(...)record('clearTasks',...)end,
        DisableControlAction=function(...)record('control',...)end,DisablePlayerFiring=function(...)record('firing',...)end,
        TriggerEvent=function(...)record('event',...)end,TriggerServerEvent=function(...)record('serverEvent',...)end})
    local settings={get=function(_,fallback)return{layout={progressBar='test-position'}}end};env.Bridge={settings=settings,fivem={streaming=stream}}
    r.environment,r.streaming,r.settings=env,stream,settings;r.core={resource='forge-core',context='client'}
    r.ports={prCore=r.core,events={listen=listen,remove=remove},environment=env,streaming=stream,settings=settings,isCurrent=function()return r.current end,
        load=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target)end}
    if wrapped then r.factory=H.load(T.path,H.environment());r.api=r.factory(r.ports);assert(r.api.Open());r.lib=r.api.Library
    else r.lib=H.load('../pr_bridge/bridge/progressbar/native/client.lua',env)end
    function r.begin(method,data)r.result=nil;r.co=coroutine.create(function()r.result=table.pack(pcall(r.lib[method],data))end);assert(coroutine.resume(r.co))end
    function r.step(ms)r.now=r.now+ms;if coroutine.status(r.co)~='dead'then assert(coroutine.resume(r.co))end end
    return r
end
return T
