-- Attach actual zone consumers to the same client holder/producer/legacy/replica; constructors have no UI effects.
local createPoints=require 'kernel.client.job.points'
local createBusiness=require 'kernel.client.job.business'
return function(state,ports)
    local producer,legacy,jobs=assert(state.ProducerCore),assert(state.LegacyCore),assert(state.JobClientCore)
    assert(producer.State==state and legacy.State==state and jobs.State==state,'canonical client state required')
    assert(state.JobZoneCore==nil,'job zones already attached')
    local client=assert(ports.client)
    assert(client==jobs.Client and client.JobState==jobs.JobState,'canonical job holder required')
    assert(client.JobPoints==nil and client.JobBusiness==nil,'job consumers already attached')
    local getData=assert(legacy.Functions.GetPlayerData)
    local access={GetPlayerData=getData}
    function access.GetJobInfo()
        local data=getData()
        if not data or not data.job then return {} end
        local job=data.job
        return {grade=job.grade.level,gradeName=job.grade.name,jobName=job.name,jobLabel=job.label}
    end
    local bindings={library=ports.library,playerAccess=access,client=client,translate=ports.translate,
        config=ports.config,native=ports.native,integrations=ports.integrations,
        debugEnabled=ports.debugEnabled,notifyPosition=ports.notifyPosition}
    local points,business=createPoints(bindings),createBusiness(bindings)
    local api={State=state,Client=client,Replica=jobs,PlayerAccess=access,Points=points.Points,Business=business.Business,
        PointModule=points,BusinessModule=business,Events={}}
    for _,module in ipairs({points,business})do for _,event in ipairs(module.Events)do api.Events[#api.Events+1]=event end end
    client.JobPoints,client.JobBusiness=points.Points,business.Business
    state.JobZoneCore=api
    return api
end

