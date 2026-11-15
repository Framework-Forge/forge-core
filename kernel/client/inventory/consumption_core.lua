-- Client effects must use the existing authoritative status producer, never a self-export.
local createConsumption = require 'kernel.client.inventory.consumables'
return function(state, ports)
    local producers = assert(state.ProducerCore)
    assert(producers.State==state, 'canonical client state required')
    assert(state.Consumption==nil, 'client consumption already attached')
    local status = assert(producers.Status)
    local fallback
    for _,event in ipairs(status.Events) do
        if event.name=='qbx_core:client:applyStatusEffects' then fallback=event.handler end
    end
    local api = createConsumption({config=assert(ports.config),library=ports.library,native=ports.native,
        integrations=ports.integrations,status={AddStatuses=assert(status.Exports.AddStatuses),
            ApplyStatusEffects=assert(fallback)}})
    state.Consumption=api
    return api
end
