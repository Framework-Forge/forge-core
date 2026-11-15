local R = dofile('tests/kernel_client_runtime_harness.lua')
local T = dofile('tests/kernel_session_harness.lua')
local H = R.H
local r, producerFixture, helperFixture = R.new(true,'events'), T.new(true,'client'), R.V.T.new(true,'client')
local env, loaded = R.V.T.env(), {}
local allowed = {['kernel.client.main']=true,['kernel.client.events']=true,['kernel.client.loops']=true,
    ['kernel.client.discord']=true,['kernel.shared.bridge_cache']=true,['kernel.client.bridge_cache']=true,
    ['kernel.client.status']=true,['kernel.client.session']=true}
env.require = function(name)
    assert(allowed[name], 'External import forbidden: '..tostring(name))
    if not loaded[name] then loaded[name]=H.load(name:gsub('%.','/')..'.lua',env) end
    return loaded[name]
end
local state = producerFixture.core
state.Shared = r.core.Shared
local originalPlayer = state.PlayerData
local native = {}
for _,source in ipairs({helperFixture.native,producerFixture.native,r.native}) do for key,value in pairs(source) do native[key]=value end end
local library = {}; for key,value in pairs(helperFixture.library) do library[key]=value end
for key,value in pairs(r.library) do library[key]=value end
local producerCompose = H.load('kernel/client/session_core.lua',env)
local producers = producerCompose(state,{native=native,delivery=producerFixture.delivery,statusConfig=producerFixture.clientConfig})
local lib = H.load('kernel/modules/lib.lua',R.V.T.env())({isServer=false,native=native,cache=r.cache,
    library=library,audio=helperFixture.audio,warn=function() error('Unexpected warning') end})
local membership = H.load('kernel/shared/functions.lua',H.environment())({tableType=H.tableType,warn=function() error('Unexpected warning') end})
local functions = H.load('kernel/client/functions.lua',H.environment())({core=state,membership=membership,
    notify=r.bindings.notify,notifyPosition='center-left'})
local bindings = {}; for key,value in pairs(r.bindings) do bindings[key]=value end
bindings.native, bindings.library, bindings.helpers, bindings.functions = native,library,lib,functions
local compose = H.load('kernel/client/runtime_core.lua',env)
local api = compose(state,bindings)
assert(api.State==state and state.RuntimeCore==api and functions.GetPlayerData()==originalPlayer)
assert(#r.trace==0 and #helperFixture.trace==0 and #producerFixture.trace==0, 'Constructors must have no external effects')
assert(not pcall(compose,state,bindings), 'Duplicate attachment must fail without effects')
assert(#api.Main.Threads==2 and #api.Loops.Threads==1 and #api.Events.StateBags==2 and #api.Events.EntityStateHandlers==1)
assert(#r.threads==0 and #r.timers==0, 'Composition must not start/install descriptors')
assert(producers.Initialize() and not producers.Initialize())
assert(api.Initialize() and not api.Initialize())
assert(state.PlayerData==originalPlayer and functions.GetPlayerData()==originalPlayer)
assert(api.Main.GetVehiclesByName('car')==state.Shared.Vehicles.car)
local categories=api.Main.GetVehiclesByCategory()
assert(categories.cars[1]==state.Shared.Vehicles.car, 'Actual local Lib categorization required')
local handlers={}; for _,e in ipairs(api.Events.Events) do handlers[e.name]=e.handler end
local nextPlayer={citizenid='B',metadata={hunger=42},job={name='taxi'}}
handlers['QBCore:Player:SetPlayerData'](nextPlayer)
assert(state.PlayerData==nextPlayer and functions.GetPlayerData()==nextPlayer)
assert(state.Session.snapshot().data.character=='B' and state.ProducerCore==producers)
assert(producerFixture.cache.player==nil, 'Stopped bridge delivery cannot become a read-through authority')
producerFixture.invoking='foreign' -- The merged platform uses R's caller, not an external framework adapter.
r.caller='foreign'; handlers['QBCore:Player:SetPlayerData']({citizenid='C'})
assert(state.PlayerData==nextPlayer)
r.caller=nil
handlers['QBCore:Notify']('Title','success',500,'Body')
local last=r.trace[#r.trace]; assert(last.kind=='notify' and last.args[1].title=='Title' and last.args[1].description=='Body')
api.Main.Callbacks['qbx_core:client:setHealth'](155)
assert(r.health==155, 'Health callback calls the actual local cache producer then native')
-- Composition initializer may not acknowledge while a platform call is suspended.
local fresh = {PlayerData={},Shared=state.Shared,Status=state.Status,Session=state.Session,BridgeCache=state.BridgeCache}
local waiting = {}; for key,value in pairs(bindings) do waiting[key]=value end
waiting.native = {}; for key,value in pairs(native) do waiting.native[key]=value end
local mapCalls=0
waiting.native.AddTextEntry=function() mapCalls=mapCalls+1; coroutine.yield('map pending') end
local api2=compose(fresh,waiting); local co=coroutine.create(api2.Initialize)
assert(coroutine.resume(co) and not api2.Initialize() and mapCalls==1)
assert(coroutine.resume(co) and coroutine.status(co)=='dead' and not api2.Initialize())
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','qbx','exports','RegisterNetEvent','CreateThread','GlobalState','MySQL'}) do
    assert(rawget(env,name)==nil,'No ambient runtime '..name)
end
print('PASS client runtime composition: actual local Shared/Lib/Functions/cache/session/status, canonical identity and caller guard, no constructor/bootstrap installation or duplicate authority; one-shot init across yield')
