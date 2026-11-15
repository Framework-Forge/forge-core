-- One local replica attached to canonical producers; no runtime effects.
local createRuntime=require 'kernel.client.skill.runtime'
return function(state,ports)
    local producer=assert(state.ProducerCore)
    assert(producer.State==state and producer.Status and state.PlayerData,'canonical client producer required')
    assert(state.SkillClientCore==nil,'skills client already attached')
    local client=assert(ports.client)
    if state.JobClientCore then assert(state.JobClientCore.Client==client,'canonical client holder required')end
    assert(client.SkillReplica==nil,'skills replica already published')
    local runtime=createRuntime({config=ports.config,library=ports.library,progression=ports.progression,native=ports.native})
    local api={State=state,Client=client,Producer=producer,Config=ports.config,Runtime=runtime,
        Events=runtime.Events,Threads=runtime.Threads,Exports=runtime.Exports}
    client.SkillReplica,state.SkillClientCore=runtime,api
    return api
end

