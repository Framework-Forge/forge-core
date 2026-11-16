ForgeCore = ForgeCore or {}
local Session, cache = {}, pr_lib.cache
ForgeCore.Session = Session
local server=IsDuplicityVersion()
local prefix='forge-core:session:'
local function playerData(src)
    if server then
        local player=cache.GetPlayer(tonumber(src),1000)
        return player and (player.PlayerData or player) or {}
    end
    return pr_lib.framework.GetPlayerData() or {}
end
function Session.isLoaded(src)
    if not server then
        local record=cache.get(prefix..'self')
        return record and record.loaded==true or false
    end
    if cache.get(prefix..tostring(src))==false then return false end
    local session=cache.GetResourceState('qbx_core','session:'..tostring(src))
    if session and session.connected==false then return false end
    local data=playerData(src)
    local identifier=data.citizenid or data.identifier
    return type(identifier)=='string' and identifier~=''
end
function Session.character(src)
    if not server then
        local record=cache.get(prefix..'self');return record and record.character
    end
    if not Session.isLoaded(src) then return nil end
    local data=playerData(src);return data.citizenid or data.identifier
end
if server then
    AddEventHandler('pr_bridge:server:OnPlayerLoaded',function(src)
        src=tonumber(src);if not src then return end
        cache.set(prefix..src,true)
    end)
    AddEventHandler('pr_bridge:server:OnPlayerUnloaded',function(src)
        src=tonumber(src);if not src then return end
        cache.set(prefix..src,false)
    end)
    AddEventHandler('playerDropped',function()
        cache.set(prefix..tostring(source),false)
    end)
else
    local lifecycle=0
    function Session.refresh()
        local data=playerData()
        local identifier=data.citizenid or data.identifier
        local loaded=cache.get('playerLoaded')~=false and pr_lib.framework.IsPlayerLoaded()==true and type(identifier)=='string' and identifier~=''
        local old=cache.get(prefix..'self') or {}
        local record={loaded=loaded,character=loaded and identifier or nil,
            job=loaded and ForgeCore.State.copy(data.job) or nil,gang=loaded and ForgeCore.State.copy(data.gang) or nil}
        cache.set(prefix..'self',record)
        if record.character~=old.character or record.loaded~=old.loaded then
            lifecycle=lifecycle+1
            TriggerEvent('forge-core:session:changed',record.character,lifecycle)
        end
        return record
    end
    function Session.group(kind)
        local record=cache.get(prefix..'self') or {}
        return record.loaded and record[kind] or nil
    end
    AddEventHandler('pr_bridge:client:OnPlayerLoaded',Session.refresh)
    AddEventHandler('pr_bridge:client:OnPlayerUnloaded',function()
        lifecycle=lifecycle+1;cache.set(prefix..'self',{loaded=false})
        TriggerEvent('forge-core:session:changed',nil,lifecycle)
    end)
    local function deferRefresh() SetTimeout(0,Session.refresh) end
    AddEventHandler('qbx_core:client:cacheChanged',function(changes)
        if changes.job or changes.gang or changes.playerLoaded then Session.refresh() end
    end)
    AddEventHandler('pr_bridge:client:OnInventoryChanged',deferRefresh)
    RegisterNetEvent('QBCore:Client:OnJobUpdate',deferRefresh)
    RegisterNetEvent('QBCore:Client:OnGangUpdate',deferRefresh)
    RegisterNetEvent('QBCore:Client:SetDuty',deferRefresh)
    Session.refresh()
end
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then cache.set(prefix..'self',{loaded=false}) end
end)
