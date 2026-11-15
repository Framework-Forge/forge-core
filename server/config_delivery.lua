-- Public visual settings only. PR Bridge stores/serves records; Forge owns
-- connection bootstrap and delivery after an administrator commits a change.
pr_lib.callback.register('forge-core:config:interface', function()
    return pr_lib.settings.snapshot('interface')
end)

AddEventHandler('pr_bridge:ui:configCommitted', function(record)
    if type(record) ~= 'table' or type(record.data) ~= 'table' then return end
    TriggerClientEvent('forge-core:config:interface', -1, record)
end)
