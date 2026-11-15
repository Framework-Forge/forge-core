-- Whole installed Forge client Session view, distinct from QBX producer readiness.
return function(ports)
    local kernel,cache,native=assert(ports.kernel),assert(ports.cache),assert(ports.native)
    local Session,prefix={},'forge-core:session:'
    local api={Session=Session,Events={}}
    local function listen(name,handler,network)api.Events[#api.Events+1]={name=name,handler=handler,network=network==true}end
    local function network(name,handler)listen(name,handler,true)end
local function copy(value)
    if type(value)~='table' then return value end
    local result={}; for key,item in pairs(value) do result[key]=copy(item) end; return result
end
local function playerData(src)
    return kernel.GetAuthenticatedPlayerData() or {}
end
function Session.isLoaded(src)
        local record=cache.get(prefix..'self')
        return record and record.loaded==true or false
end
function Session.character(src)
        local record=cache.get(prefix..'self');return record and record.character
end
    local lifecycle=0
    function Session.refresh()
        local data=playerData()
        local identifier=data.citizenid or data.identifier
        local loaded=cache.get('playerLoaded')~=false and kernel.IsAuthenticated()==true and type(identifier)=='string' and identifier~=''
        local old=cache.get(prefix..'self') or {}
        local record={loaded=loaded,character=loaded and identifier or nil,
            job=loaded and copy(data.job) or nil,gang=loaded and copy(data.gang) or nil}
        cache.set(prefix..'self',record)
        if record.character~=old.character or record.loaded~=old.loaded then
            lifecycle=lifecycle+1
            native.TriggerEvent('forge-core:session:changed',record.character,lifecycle)
        end
        return record
    end
    function Session.group(kind)
        local record=cache.get(prefix..'self') or {}
        return record.loaded and record[kind] or nil
    end
    listen('pr_bridge:client:OnPlayerLoaded',Session.refresh)
    listen('pr_bridge:client:OnPlayerUnloaded',function()
        lifecycle=lifecycle+1;cache.set(prefix..'self',{loaded=false})
        native.TriggerEvent('forge-core:session:changed',nil,lifecycle)
    end)
    local function deferRefresh() native.SetTimeout(0,Session.refresh) end
    listen('qbx_core:client:cacheChanged',function(changes)
        if changes.job or changes.gang or changes.playerLoaded then Session.refresh() end
    end)
    listen('pr_bridge:client:OnInventoryChanged',deferRefresh)
    network('QBCore:Client:OnJobUpdate',deferRefresh)
    network('QBCore:Client:OnGangUpdate',deferRefresh)
    network('QBCore:Client:SetDuty',deferRefresh)
listen('onResourceStop',function(resource)
    if resource==native.GetCurrentResourceName() then cache.set(prefix..'self',{loaded=false}) end
end)

    local initialized=false
    function api.Initialize()
        if initialized then return false end
        initialized=true
        Session.refresh()
        return true
    end
    return api
end
