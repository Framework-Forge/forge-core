-- Installed policy, same optional PR prison provider, local player/permission services.
return function(ports)
    local services,playerAccess=assert(ports.services),assert(ports.playerAccess)
local provider = ports.provider
local service = {}
function service.status(src)
    if not provider or not provider.isAvailable() then return nil end
    local status = provider.getStatus(tonumber(src))
    return type(status) == 'table' and status or nil
end
function service.canChangeJobs(src)
    if provider and provider.isAvailable() then
        local status = service.status(src)
        if not status then return false end -- Do not authorize an unloaded/transitioning sentence.
        return status.jailed ~= true and status.status ~= 'jailed'
    end
    local player = playerAccess.GetPlayer(src)
    local metadata = player and player.PlayerData and player.PlayerData.metadata or {}
    return metadata.prisonStatus ~= 'jailed' and (tonumber(metadata.injail) or 0) <= 0
end
function service.setSentence(actor, target, sentence)
    if not services.JobService.canManage(actor) then return false, 'no_permission' end
    target = tonumber(target)
    if not target or not playerAccess.GetPlayer(target) then return false, 'invalid_player' end
    if type(sentence) ~= 'table' then return false, 'invalid_sentence' end
    local ok, reason = provider.jail(target, sentence)
    return ok == true, reason
end
function service.release(actor, target)
    if not services.JobService.canManage(actor) then return false, 'no_permission' end
    target = tonumber(target)
    if not target or not playerAccess.GetPlayer(target) then return false, 'invalid_player' end
    local ok, reason = provider.release(target)
    return ok == true, reason
end
return service
end

