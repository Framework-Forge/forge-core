-- Complete installed server branch of the Forge session view. Client branch intentionally deferred.
return function(ports)
    local kernel,cache,native=assert(ports.kernel),assert(ports.cache),assert(ports.native)
    local Session,prefix={},'forge-core:session:'
    local api={Session=Session,Events={}}
    local function listen(name,handler)api.Events[#api.Events+1]={name=name,handler=handler,network=false}end
local function playerData(src)
        local player=kernel.GetPlayer(tonumber(src))
        return player and (player.PlayerData or player) or {}
end
function Session.isLoaded(src)
    if cache.get(prefix..tostring(src))==false then return false end
    local session=cache.GetResourceState('qbx_core','session:'..tostring(src))
    if session and session.connected==false then return false end
    local data=playerData(src)
    local identifier=data.citizenid or data.identifier
    return type(identifier)=='string' and identifier~=''
end
function Session.character(src)
    if not Session.isLoaded(src) then return nil end
    local data=playerData(src);return data.citizenid or data.identifier
end
    listen('pr_bridge:server:OnPlayerLoaded',function(src)
        src=tonumber(src);if not src then return end
        cache.set(prefix..src,true)
    end)
    listen('pr_bridge:server:OnPlayerUnloaded',function(src)
        src=tonumber(src);if not src then return end
        cache.set(prefix..src,false)
    end)
    listen('playerDropped',function()
        cache.set(prefix..tostring(native.source()),false)
    end)
listen('onResourceStop',function(resource)
    if resource==native.resourceName() then cache.set(prefix..'self',{loaded=false}) end
end)
    return api
end

