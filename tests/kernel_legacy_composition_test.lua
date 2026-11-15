local V=dofile('tests/kernel_legacy_harness.lua')
local H=V.H
local fixture,queries=V.new(true,'client'),V.client(true)
fixture.trace={}
local env,loaded=V.T.env(),{}
local paths={['kernel.modules.utils']='kernel/modules/utils.lua',['kernel.client.functions']='kernel/client/functions.lua',['kernel.client.groups']='kernel/client/groups.lua'}
env.require=function(name)
    local file=assert(paths[name],'External import '..tostring(name))
    if not loaded[name] then loaded[name]=H.load(file,env) end
    return loaded[name]
end
local compose=H.load('kernel/client/legacy_core.lua',env)
local canonical=queries.core
local bindings={};for key,value in pairs(fixture.bindings) do bindings[key]=value end
bindings.membership=queries.membership;bindings.notify=queries.bindings.notify;bindings.notifyPosition='center-left'
local groupPulls=0
local jobData={taxi={label='Taxi'}}
bindings.jobs={seed={}};bindings.gangs={seed={}}
bindings.awaitGroups=function(name)
    groupPulls=groupPulls+1;assert(name=='qbx_core:server:getGroups')
    return {jobs=jobData,gangs={none={label='None'}}}
end
local originalStringSplit,originalMathRound=string.split,math.round
local api=compose(canonical,bindings)
assert(api.State==canonical and canonical.LegacyCore==api and api.Functions.GetPlayerData()==canonical.PlayerData)
assert(groupPulls==0 and #fixture.trace==0 and #queries.trace==0)
assert(not pcall(compose,canonical,bindings),'Reject second attachment before effects')
assert(api.Initialize() and not api.Initialize() and groupPulls==1)
assert(api.Groups.GetJobs()==jobData and api.Functions.HasGroup('taxi'))
api.Functions.Notify('Title','success',500,'Body')
assert(#queries.trace==1 and queries.trace[1].title=='Title')
api.Utils.GetPlate(20);api.Utils.DrawText3D(V.vector(1,2,3),'Test')
local state={citizenid='B'};canonical.PlayerData=state
assert(api.Functions.GetPlayerData()==state,'No shadow PlayerData copy')
assert(string.split==originalStringSplit and math.round==originalMathRound)
-- Explicit initializer cannot acknowledge completion while its group pull awaits.
local waitingBindings={};for key,value in pairs(bindings) do waitingBindings[key]=value end
local waitingPulls=0
waitingBindings.awaitGroups=function()
    waitingPulls=waitingPulls+1;coroutine.yield('waiting')
    return {jobs=jobData,gangs={}}
end
local waiting=compose({PlayerData={} },waitingBindings)
local co=coroutine.create(waiting.Initialize)
assert(coroutine.resume(co) and not waiting.Initialize() and waitingPulls==1)
assert(coroutine.resume(co) and coroutine.status(co)=='dead' and not waiting.Initialize())
assert(not pcall(env.require,'pr_lib.framework'))
for _,name in ipairs({'QBX','qbx','exports','GetPlate','MaleNoGloves','MySQL','CreateThread','RegisterNetEvent'}) do
    assert(rawget(env,name)==nil,'No host global '..name)
end
print('PASS legacy client composition: same canonical state and local Lib/membership; explicit one-shot groups/warnings, PR inventory/notify ports, no global mutation or duplicate authority')
