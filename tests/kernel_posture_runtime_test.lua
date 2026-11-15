local H=dofile('tests/cache_harness.lua')
local create=dofile('kernel/pr_integration/posture_runtime.lua')
local Input=dofile('tests/kernel_state_input_harness.lua')
local function setup(server)
    local r=H.new(server); local e=r.env
    e.RegisterNetEvent=function() end
    local postEnv
    e.PRCore={load=function(path,env)
        local file=path:gsub('^@forge%-core/',''):gsub('^@pr_bridge/','../pr_bridge/')..'.lua'
        if path:find('kernel/posture/interactions',1,true) then postEnv=env end
        return assert(loadfile(file,'t',env))()
    end}
    local input=Input.ports()
    local keyowner=input.provider
    local keymap=keyowner.list
    e.PRCore.forgeKeybindScope={Keybind=keyowner}
    local callbacks={}
    local rpc={Native={await=function(name,timeout,...)
        return assert(callbacks[name],name)(1,...)
    end},Owners={native={Reserve=function(name)assert(not callbacks[name]);return name end,
        Bind=function(name,fn)callbacks[name]=fn;return true end,
        Release=function(name)callbacks[name]=nil;return true end}}}
    local commands={}
    local lib=e.pr_lib
    local passiveCache=lib.cache
    lib.command=function(name,options,fn)commands[name]=fn;return true end
    local session={character=function()return 'A'end,isLoaded=function()return true end}
    local graph=server and {Base={ForgeSession={Session=session},PlayerCore={Lookup={GetPlayer=function(id)return r.players[id]end}}}}
        or {Parts={AutoMedic={Session={Session=session},Hospital={Hospital={isRecovering=function()return false end}}}}}
    local entry={Providers={Library=lib,DomainConfiguration={Config={},Translate=function(k)return k end}},
        Foundation={Seed={Library={Cache=passiveCache}}},
        Bootstrap={Graph=graph},IsCurrent=function()return true end}
    e.PlayerPedId=function()return 1 end;e.PlayerId=function()return 0 end
    e.IsPedDeadOrDying=function()return false end
    e.GetActivePlayers=function()return {} end
    if not server then
        e.GetPlayerServerId=function()return 1 end
        e.GetVehiclePedIsIn=function()return 0 end
        e.GetCurrentPedWeapon=function()return false,0 end
        e.GetInteriorFromEntity=function()return 0 end
        local nativeCache=dofile('kernel/entry/native_import_cache.lua')({native=e,isCurrent=function()return true end})
        lib.cache=nativeCache.Cache
        assert(lib.cache~=passiveCache and lib.cache.clearPrefix==nil,'real client cache is not the passive data cache')
    end
    local runtime=create(e,rpc,entry)
    return r,runtime,callbacks,keymap,commands,function()return postEnv end,input,entry,rpc
end
local r,server,callbacks=setup(true)
r.players[1]={PlayerData={citizenid='A',metadata={}}}
assert(server.Start())
local begin=assert(callbacks['forge-core:posture:begin'])(1)
assert(begin.character=='A' and begin.token)
local publish=assert(callbacks['forge-core:posture:publish'])
local posture={sit={coords={x=0,y=0,z=0},heading=0,scenario='WORLD_HUMAN_SEAT_LEDGE',inPlace=true},lean=false}
assert(publish(1,begin.token,1,posture)==true)
assert(publish(1,begin.token,1,posture)==false,'replay must fail')
assert(publish(1,'wrong',2,posture)==false,'wrong session must fail')
r.players[1].PlayerData.metadata.isdead=true
assert(publish(1,begin.token,2,posture)==false,'dead posture must fail')
assert(server.Close());assert(next(callbacks)==nil)
local c,client,_,keys,commands,environment,input=setup(false)
assert(client.Start())
local env=assert(environment())
local sit,lean=env.ForgeCore.Client.Sit,env.ForgeCore.Client.Lean
local ckey=assert(keys.forge_core_toggle_sit)
local okey
for name,key in pairs(keys) do if key.defaultKey=='O' then okey=key end end
assert(ckey.defaultKey=='C' and okey,'both original default keys must be installed')
local sits,leans,stands=0,0,0
sit.toggle=function()sits=sits+1 end
lean.toggle=function()leans=leans+1 end
sit.sit=function()sits=sits+1 end
sit.stand=function()stands=stands+1 end
assert(ckey.combos[1].keys[1]=='C' and okey.combos[1].keys[1]=='O')
input.key(ckey.name);input.key(ckey.name,false)
input.key(okey.name);input.key(okey.name,false)
commands.sit();commands.stand()
assert(sits==2 and leans==1 and stands==1,'key/command must invoke the actual posture domain')
assert(client.Close());assert(next(keys)==nil)
ckey.onPressed();okey.onPressed();commands.sit()
assert(sits==2 and leans==1,'closed callbacks must not run')
c.advance(2000);assert(#c.queue==0,'closed posture threads must finish')
-- Exercise the actual boot coordinator with the installed posture extension, not a Start stub.
local b,_,_,bootKeys,_,_,_,entry,rpc=setup(false)
local e=b.env
local loadModule=e.PRCore.load
e.PRCore.forgeOwnedCallbacks=rpc
e.PRCore.load=function(path,env)
    if path=='@pr_bridge/bridge/runtime/forge/control_client' then
        return function()return{Call=function()error('no consumers expected')end}end
    end
    return loadModule(path,env)
end
entry.Bootstrap.Progress=function()return{phase='running'}end
local stops=0
local boot=dofile('kernel/pr_integration/core_activation_runtime.lua')({environment=e,
    candidate={GetPreparedEntry=function()return entry end,Activate=function()return true end,
        Activation={Barrier={Progress=function()return{stage=6,ingressOpen=true}end}},
        Stop=function()stops=stops+1;return true end,Poll=function()return true end},
    profile={Generation='posture-regression',Consumers=function()return{}end},
    configuration={IsCurrent=function()return true end,Ready=function()return true end,Close=function()return true end,
        PhysicalOptions={registration={publishExport=function()return true end}}},timeout=1000,interval=1,
    createTasks=dofile('../pr_bridge/bridge/runtime/owned_tasks.lua'),createPosture=create})
assert(boot.Run());b.advance(1)
assert(boot.Status().phase=='running' and stops==0,'posture startup must not abort the framework')
assert(bootKeys.forge_core_toggle_sit)
assert(boot.Close());b.advance(2000)
assert(stops==1 and next(bootKeys)==nil and #b.queue==0)
print('PASS installed posture runtime: C/O, sit/stand, session RPC, replay/death rejection, cleanup and stale handlers')
