-- One canonical AutoMedic client, menus and Forge Session view. No installs or workers here.
local createRuntime=require 'kernel.client.automedic.runtime'
local createHospital=require 'kernel.client.automedic.hospital'
local createMenu=require 'kernel.client.menu.automedic'
local createSession=require 'kernel.client.forge_session'
return function(state,ports)
    local producer,work,admin=assert(state.ProducerCore),assert(state.WorkMenus),assert(state.AdministrationMenus)
    assert(producer.State==state and work.State==state and admin.State==state,'canonical state required')
    local client=assert(ports.client)
    assert(client==work.Client and client.Menu==work.Menu and work.Menu==admin.Menu and work.Shared==admin.Shared,
        'canonical menu/controller required')
    assert(state.AutoMedicClientCore==nil and client.Hospital==nil and client.ForgeSession==nil,'AutoMedic already attached')
    assert(work.Menu.openAutoMedicMenu==nil and work.Menu.openAutoMedicBeds==nil,'AutoMedic menus already attached')
    local library,native,config=assert(ports.library),assert(ports.native),assert(ports.config)
    assert(config.AutoMedic and producer.Status and state.PlayerData,'canonical producer/config required')
    local cache=assert(library.cache)
    local function getAuthenticated()
        local record=cache.GetResourceState('qbx_core','session')
        if record and record.authenticated==false then return {} end
        return state.PlayerData or {}
    end
    local function statusHandler(name)
        for _,entry in ipairs(producer.Status.Events)do if entry.name==name then return entry.handler end end
        error('missing canonical Status handler: '..name)
    end
    local kernel={
        GetPlayerData=function()return state.PlayerData end,
        GetStatus=assert(producer.Status.Exports.GetStatus),
        GetAuthenticatedPlayerData=getAuthenticated,
        IsAuthenticated=function()local d=getAuthenticated();return type(d)=='table'and(d.citizenid~=nil or d.identifier~=nil)end,
        IsPlayerDead=function()
            local d=getAuthenticated()
            -- Exact installed PR normalizer policy, not producer Session.isDead (includes laststand).
            return native.IsEntityDead(native.PlayerPedId()) or d.dead==true
                or d.metadata and(d.metadata.isdead==true or d.metadata.dead==true)
        end,
        RefreshNativeStatus=statusHandler('qbx_core:client:refreshNativeStatus'),
        SetDeathPoseOverride=statusHandler('qbx_core:client:setDeathPoseOverride'),
    }
    local bindings={config=config,library=library,native=native,kernel=kernel,translate=assert(ports.translate),
        menu=work.Menu,shared=work.Shared}
    local session=createSession({kernel=kernel,cache=cache,native=native})
    local hospital=createHospital(bindings);bindings.hospital=hospital.Hospital
    local runtime=createRuntime(bindings)
    local menu=createMenu(bindings)
    local api={State=state,Client=client,Producer=producer,Config=config.AutoMedic,Kernel=kernel,
        Runtime=runtime,Hospital=hospital,Menu=menu,Session=session}
    local initialized=false
    function api.Initialize()
        if initialized then return false end
        initialized=true
        hospital.Initialize()
        session.Initialize()
        return true
    end
    client.Hospital,client.ForgeSession,state.AutoMedicClientCore=hospital.Hospital,session.Session,api
    return api
end
