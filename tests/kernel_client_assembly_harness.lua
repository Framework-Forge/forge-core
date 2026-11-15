-- Actual inactive factories; virtual native/UI/codec/wire effects, never a FiveM runtime.
local R=dofile('tests/kernel_client_runtime_harness.lua')
local U=dofile('tests/kernel_session_harness.lua')
local F=dofile('tests/kernel_character_flow_harness.lua')
local V=dofile('tests/kernel_character_renderer_harness.lua')
local C=dofile('tests/kernel_consumables_harness.lua')
local E=dofile('tests/kernel_assembly_harness.lua')
local H=R.H;local A={H=H,P=R.P,R=R,U=U,F=F,V=V,C=C,E=E}
local function copy(t)local o={};for k,v in pairs(t)do o[k]=v end;return o end
function A.new(external)
    local r={runtime=R.new(true,'events'),producer=U.new(true,'client'),helper=R.V.T.new(true,'client'),
        legacy=R.V.new(true,'client'),flow=F.new(true),world=V.new(true),consumption=C.new('client',true),groupPulls=0}
    local n,library={},{}
    for _,v in ipairs({r.helper,r.legacy,r.producer,r.runtime,r.flow,r.world,r.consumption})do
        for k,value in pairs(v.native or{})do n[k]=value end
        for k,value in pairs(v.library or{})do library[k]=value end
    end
    n.Wait=r.flow.native.Wait;n.GetGameTimer=function()return r.flow.now end
    n.GetInvokingResource=function()return r.runtime.caller end
    n.GetResourceState=r.flow.native.GetResourceState
    n.GetEntityCoords=function(id)return assert(r.world.entities[id],'virtual entity missing').coords end
    n.DoesEntityExist=function(id)return r.world.entities[id]~=nil or r.consumption.entities[id]==true end
    n.DeleteEntity=function(id)if r.world.entities[id]then return r.world.native.DeleteEntity(id)end;return r.consumption.native.DeleteEntity(id)end
    n.CreateThread=r.world.native.CreateThread;n.TriggerEvent=r.producer.emit
    r.consumption.nextEntity=1000
    local env=E.env()
    local config=H.load('kernel/config/client.lua',env)({getResourceState=n.GetResourceState,
        getVehicleNumberPlateText=n.GetVehicleNumberPlateText,vec4=n.vec4,joaat=n.joaat,vehicleKeys={}})
    config.characters.useExternalCharacters=external==true
    local state={PlayerData=r.producer.core.PlayerData,Shared=r.runtime.core.Shared,IsLoggedIn=false}
    local ports={native=n,library=library,cache=r.world.cache,config={Client=config,Inventory=r.consumption.config},
        membership={tableType=H.tableType,warn=r.helper.ports.warn},
        helpers={audio=r.helper.audio,warn=r.helper.ports.warn},producers={delivery=r.producer.delivery},
        legacy=copy(r.legacy.bindings),runtime=copy(r.runtime.bindings),character=copy(r.flow.bindings),
        consumption={integrations=r.consumption.integrations}}
    for _,key in ipairs({'legacy','runtime','character'})do
        for _,name in ipairs({'core','native','library','cache','config','helpers','functions','membership'})do ports[key][name]=nil end
    end
    ports.legacy.jobs={taxi={label='Taxi'}};ports.legacy.gangs={none={label='None'}}
    ports.legacy.notify=r.runtime.bindings.notify
    ports.legacy.awaitGroups=function()r.groupPulls=r.groupPulls+1;return{jobs=ports.legacy.jobs,gangs=ports.legacy.gangs}end
    ports.runtime.notify=nil
    for _,name in ipairs({'renderer','notify','nationalities'})do ports.character[name]=nil end
    ports.character.streaming=r.world.bindings.streaming;ports.character.json=r.world.bindings.json
    ports.character.setPedAppearance=r.world.bindings.setPedAppearance
    library.framework=setmetatable({},{__index=function()error('forbidden live framework/self cycle')end})
    r.native,r.library,r.state,r.ports,r.config=n,library,state,ports,config
    r.factory=H.load('kernel/client/assembly_core.lua',env)
    function r.mount()r.api=r.factory(state,ports);return r.api end
    function r.snapshot()
        local out={groupPulls=r.groupPulls,delivery=H.copy(r.producer.cache)}
        for _,key in ipairs({'runtime','producer','helper','legacy','flow','world','consumption'})do
            local v=r[key];out[key]={trace=#v.trace,threads=#(v.threads or{}),timers=#(v.timers or{}),
                workers=#(v.workers or{}),tasks=#(v.tasks or{}),events=#(v.events or{}),callbacks=A.P.snapshot(v.callbacks or{})}
        end
        return out
    end
    function r.installEvents()
        local p,x=r.api.Parts.Producers,r.api.Parts.Runtime
        for _,module in ipairs({p.Cache,p.Status,p.Session,x.Main,x.Events,x.Loops,x.Discord,r.api.Parts.Character.Flow,r.api.Parts.Consumption})do
            for _,entry in ipairs(module.Events or{})do r.producer.listen(entry.name,entry.handler,entry.network)end
        end
    end
    function r.dispatch(name,...)
        for _,event in ipairs(r.producer.events)do if event.name==name then event.handler(...)end end
    end
    return r
end
return A
