-- Public world data only. Character/economy authority stays in its services.
ForgeCore = ForgeCore or {}
local State, cache = {}, pr_lib.cache
ForgeCore.State = State
local server = IsDuplicityVersion()
local prefix = 'forge-core:world:'
local domains = {stores=true,objects=true,npcs=true,density=true,vinewood=true,
    starterpack=true,farms=true,billboards=true,characterPreviews=true,spotlights=true}
local listeners, pending = {}, {}
local generation = server and (os.time()*1000+GetGameTimer()) or -1
local revision, scheduled, stopped = 0, false, false
local function copy(value)
    if type(value)~='table' then return value end
    local result={}; for key,item in pairs(value) do result[key]=copy(item) end; return result
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,value in pairs(a) do if not equal(value,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local function finite(value) return type(value)=='number' and value==value and math.abs(value)<math.huge end
State.copy=copy
function State.peek(key)
    local record=cache.get(prefix..key)
    return record and record.data -- Internal read-only view; public reads are copies.
end
function State.get(key) return copy(State.peek(key)) end
function State.getRecord(key)
    if not domains[key] then return nil end
    return copy(cache.get(prefix..key))
end
local function emit(key,record)
    for _,entry in ipairs(listeners[key] or {}) do
        entry.pending={record=copy(record)}
        if not entry.running then
            entry.running=true
            CreateThread(function()
                -- Serialize yielding scene/route handlers; retain only the newest pending update.
                while entry.pending do
                    local nextRecord=entry.pending.record;entry.pending=nil
                    local current=cache.get(prefix..key)
                    local valid=nextRecord and current and current.generation==nextRecord.generation and current.revision==nextRecord.revision
                        or not nextRecord and not current
                    if valid then
                        local ok,err=pcall(entry.fn,nextRecord and copy(nextRecord.data) or nil)
                        if not ok then entry.running=false;error(err) end
                    end
                end
                entry.running=false
            end)
        end
    end
    TriggerEvent('pr_bridge:resourceState:changed','forge-core',key,copy(record))
end
function State.onChange(key,fn)
    assert(domains[key] and type(fn)=='function','Invalid Forge world subscription')
    listeners[key]=listeners[key] or {}; listeners[key][#listeners[key]+1]={fn=fn}
end
local function ready()
    for key in pairs(domains) do if not cache.get(prefix..key) then return false end end
    return true
end
local function snapshot()
    local states={}; for key in pairs(domains) do states[key]=State.getRecord(key) end
    return {generation=generation,states=states,ready=ready()}
end
if server then
    cache.clearPrefix(prefix)
    function State.publish(key,value)
        assert(domains[key] and type(value)=='table','Invalid Forge world publication')
        if equal(State.peek(key),value) then return false end
        revision=revision+1
        local record={generation=generation,revision=revision,data=copy(value)}
        cache.set(prefix..key,record); pending[key]=record
        if not scheduled then
            scheduled=true
            SetTimeout(0,function()
                scheduled=false
                if stopped then return end
                local changes=pending;pending={}
                TriggerClientEvent('forge-core:cache:world',-1,{generation=generation,states=copy(changes),ready=ready()})
            end)
        end
        emit(key,record)
        return true
    end
    local requests={}
    pr_lib.callback.register('forge-core:cache:snapshot',function(src)
        local now=GetGameTimer()
        if requests[src] and now-requests[src]<500 then return nil end
        requests[src]=now
        return snapshot()
    end)
    AddEventHandler('playerDropped',function() requests[source]=nil end)
else
    cache.clearPrefix(prefix)
    local hydrated,refreshing=false,false
    local function apply(packet)
        if type(packet)~='table' or not finite(packet.generation) or type(packet.states)~='table' then return false end
        if packet.generation<generation then return false end
        -- Validate the entire batch before modifying any domain.
        for key,record in pairs(packet.states) do
            if not domains[key] or type(record)~='table' or record.generation~=packet.generation
                or not finite(record.revision) or record.revision<0 or type(record.data)~='table' then return false end
        end
        if packet.generation>generation then
            generation=packet.generation;hydrated=false
            for key in pairs(domains) do
                if cache.get(prefix..key) then cache.clear(prefix..key);emit(key,nil) end
            end
        end
        for key,record in pairs(packet.states) do
            local old=cache.get(prefix..key)
            if not old or record.revision>old.revision then
                cache.set(prefix..key,copy(record));emit(key,record)
            end
        end
        hydrated=packet.ready==true and ready()
        return true
    end
    State.apply=apply
    RegisterNetEvent('forge-core:cache:world',function(packet) if source==65535 then apply(packet) end end)
    function State.refresh()
        local ok,packet=pcall(pr_lib.callback.await,'forge-core:cache:snapshot',10000)
        return ok and apply(packet) and hydrated
    end
    local function hydrate()
        if refreshing or stopped then return end
        refreshing=true
        CreateThread(function()
            local delay=1000
            while not stopped and not State.refresh() do Wait(delay);delay=math.min(10000,delay*2) end
            refreshing=false
        end)
    end
    CreateThread(function() Wait(0);hydrate() end)
    AddEventHandler('pr_bridge:client:OnPlayerLoaded',hydrate)
end
exports('GetCachedState',State.getRecord)
AddEventHandler('onResourceStop',function(resource)
    if resource~='forge-core' then return end
    stopped=true;cache.clearPrefix(prefix)
    for key in pairs(domains) do emit(key,nil) end
end)
