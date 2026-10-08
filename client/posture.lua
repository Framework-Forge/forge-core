local Posture,cache={},pr_lib.cache
ForgeCore.Posture=Posture
local prefix='forge-core:posture:'
local own,observed,versions={}, {}, {}
local generation,sequence,lifecycle=-1,0,0
local token,character,dirty,stopped=nil,nil,false,false
cache.clearPrefix(prefix)
local function key(id) return prefix..'player:'..id end
local function forget(id)
    local old=cache.get(key(id))
    cache.clear(key(id))
    if old then
        for kind in pairs(old.data) do TriggerEvent('forge-core:posture:changed',id,kind,nil,old.revision) end
    end
end
function Posture.isCurrent(id,rev,ped)
    local record=cache.get(key(id))
    return record and record.revision==rev and observed[id]==ped
end
local function apply(id,record,force)
    if not observed[id] or type(record)~='table' or type(record.data)~='table'
        or not ForgeCore.PostureContract.finite(record.generation)
        or not ForgeCore.PostureContract.finite(record.revision) or record.generation<generation then return end
    if record.generation>generation then
        for other in pairs(observed) do forget(other) end
        versions={};generation=record.generation
    end
    -- Visibility loss is not a player mutation and must not advance its revision.
    if record.visible==false then forget(id);return end
    if record.revision<(versions[id] or -1) then return end
    if record.revision==versions[id] and not force and cache.get(key(id)) then return end
    local old=cache.get(key(id))
    local data={}
    for _,kind in ipairs({'sit','lean'}) do
        local valid,value=ForgeCore.PostureContract.normalize(kind,record.data[kind])
        if not valid then return end
        data[kind]=value
    end
    versions[id]=record.revision
    cache.set(key(id),{generation=record.generation,revision=record.revision,character=record.character,data=data})
    -- Finish a previous kind before starting the new one; a nil must not cancel it.
    for _,kind in ipairs({'sit','lean'}) do
        if old and old.data[kind] and not data[kind] then TriggerEvent('forge-core:posture:changed',id,kind,nil,record.revision) end
    end
    for _,kind in ipairs({'sit','lean'}) do
        if data[kind] then TriggerEvent('forge-core:posture:changed',id,kind,ForgeCore.State.copy(data[kind]),record.revision) end
    end
end
function Posture.set(kind,value)
    if stopped or not ForgeCore.Session.character() then return false end
    local ok,normalized=ForgeCore.PostureContract.normalize(kind,value)
    if not ok then return false end
    own[kind]=normalized;dirty=true
    cache.set(prefix..'self',{character=ForgeCore.Session.character(),data=ForgeCore.State.copy(own)})
    return true
end
local function changed(nextCharacter)
    lifecycle=lifecycle+1;character=nextCharacter;token=nil;sequence=0;own={};dirty=false
    cache.clear(prefix..'self')
end
AddEventHandler('forge-core:session:changed',changed)
changed(ForgeCore.Session.character())
RegisterNetEvent('forge-core:posture:delta',function(id,record)
    if source==65535 then apply(tonumber(id),record,false) end
end)
CreateThread(function()
    while not stopped do
        Wait(100)
        local cycle=lifecycle
        if character and not token then
            local ok,result=pcall(pr_lib.callback.await,'forge-core:posture:begin',10000)
            if cycle==lifecycle and ok and type(result)=='table' and result.character==character and type(result.token)=='string' then
                token=result.token;dirty=true
            elseif cycle==lifecycle then Wait(1000) end
        end
        if token and dirty and cycle==lifecycle then
            dirty=false;sequence=sequence+1
            local values={sit=own.sit or false,lean=own.lean or false}
            local ok,accepted,reason=pcall(pr_lib.callback.await,'forge-core:posture:publish',10000,token,sequence,values)
            if cycle==lifecycle and (not ok or not accepted) then
                -- A newer local posture is retained; never replay an old snapshot.
                if reason=='invalid_session' then token=nil end
                if not ok or reason=='rate_limited' or reason=='invalid_session' then dirty=true;Wait(1000) end
            end
        end
    end
end)
CreateThread(function()
    local elapsed=5000
    while not stopped do
        Wait(1000)
        if ForgeCore.Session.isLoaded() then
            local nextObserved,ids,force={}, {}, {}
            for _,player in ipairs(GetActivePlayers()) do
                local id,ped=GetPlayerServerId(player),GetPlayerPed(player)
                if player~=PlayerId() and id>0 and ped~=0 and DoesEntityExist(ped) then
                    nextObserved[id]=ped;ids[#ids+1]=id
                    if observed[id]~=ped then forget(id);force[id]=true end
                end
            end
            for id in pairs(observed) do if not nextObserved[id] then forget(id);versions[id]=nil end end
            local needs=next(force)~=nil or #ids==0 and next(observed)~=nil
            observed=nextObserved;elapsed=elapsed+1000
            if needs or elapsed>=5000 then
                elapsed=0
                local cycle=lifecycle
                local ok,packet=pcall(pr_lib.callback.await,'forge-core:posture:snapshot',10000,ids)
                if cycle==lifecycle and ok and type(packet)=='table' and type(packet.records)=='table' then
                    for id,record in pairs(packet.records) do apply(tonumber(id),record,force[tonumber(id)]) end
                end
            end
        else
            for id in pairs(observed) do forget(id) end
            observed={};versions={};elapsed=5000
        end
    end
end)
exports('GetCachedPlayerPosture',function(id) return ForgeCore.State.copy(cache.get(key(tonumber(id) or 0))) end)
AddEventHandler('onResourceStop',function(resource)
    if resource~=GetCurrentResourceName() then return end
    stopped=true
    for id in pairs(observed) do forget(id) end
    cache.clearPrefix(prefix)
end)
