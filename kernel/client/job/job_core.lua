-- Canonical client attachment. Never requests payload, refreshes integrations, registers or starts workers here.
local createState=require 'kernel.client.job.state'
local createMain=require 'kernel.client.job.main'
local createBootstrap=require 'kernel.client.job.bootstrap'
return function(state,ports)
    local producers,legacy=assert(state.ProducerCore),assert(state.LegacyCore)
    assert(producers.State==state and legacy.State==state,'canonical client producers required')
    assert(state.JobClientCore==nil,'client jobs already attached')
    local client=assert(ports.client,'shared local client holder required')
    assert(client.JobState==nil,'job replica already published')
    if state.AdministrationMenus and client.Menu then
        assert(client.Menu==state.AdministrationMenus.Menu,'canonical menu controller required')
    end
    local bindings={client=client,config=ports.config,library=ports.library,translate=ports.translate,
        wait=ports.wait,debugEnabled=ports.debugEnabled}
    local stateModule=createState(bindings)
    local mainModule=createMain(bindings)
    local bootstrap=createBootstrap(bindings)
    local api={State=state,JobState=stateModule.State,Replica=stateModule,Main=mainModule,Bootstrap=bootstrap,Client=client}
    client.JobState,state.JobClientCore=stateModule.State,api
    return api
end
