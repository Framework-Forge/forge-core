local cache,Contract=pr_lib.cache,ForgeCore.PostureContract
local prefix='forge-core:posture:'
local generation=os.time()*1000+GetGameTimer()
local revision,nonce=0,0
cache.clearPrefix(prefix)
local function key(src) return prefix..'player:'..src end
local function binding(src) return cache.get(prefix..'binding:'..src) end
local function nearby(a,b)
    if a==b or GetPlayerRoutingBucket(a)~=GetPlayerRoutingBucket(b) then return false end
    local pa,pb=GetPlayerPed(a),GetPlayerPed(b)
    if pa==0 or pb==0 then return false end
    local ca,cb=GetEntityCoords(pa),GetEntityCoords(pb)
    return (ca.x-cb.x)^2+(ca.y-cb.y)^2+(ca.z-cb.z)^2<=200^2
end
local function deliver(src,record)
    for _,viewer in ipairs(GetPlayers()) do
        viewer=tonumber(viewer)
        local watched=cache.get(prefix..'watch:'..viewer)
        if watched and watched[src] and nearby(src,viewer) then
            TriggerClientEvent('forge-core:posture:delta',viewer,src,ForgeCore.State.copy(record))
        end
    end
end
local function store(src,character,data)
    revision=revision+1
    local record={generation=generation,revision=revision,character=character,data=data or {}}
    cache.set(key(src),record);deliver(src,record)
    return ForgeCore.State.copy(record)
end
local function reset(src)
    src=tonumber(src);if not src then return end
    cache.clear(prefix..'binding:'..src)
    store(src,nil,{})
    cache.clear(prefix..'watch:'..src)
end
local function empty(visible) return {generation=generation,revision=revision,data={},visible=visible} end
ForgeCore.Callbacks.register('forge-core:posture:begin',function(src)
    local character=ForgeCore.Session.character(src)
    if not character then return nil end
    nonce=nonce+1
    local token=('%s:%s:%s'):format(generation,src,nonce)
    cache.set(prefix..'binding:'..src,{character=character,token=token,sequence=0})
    store(src,character,{})
    return {token=token,character=character,generation=generation}
end,{limit=10,window=5000,maxPayload=1024})
ForgeCore.Callbacks.register('forge-core:posture:publish',function(src,token,sequence,values)
    local session=binding(src)
    if not session or session.token~=token or session.character~=ForgeCore.Session.character(src) then
        return false,'invalid_session'
    end
    if not Contract.finite(sequence) or sequence%1~=0 or sequence<=session.sequence or type(values)~='table' then
        return false,'invalid_sequence'
    end
    local data={}
    for _,kind in ipairs({'sit','lean'}) do
        local ok,value=Contract.normalize(kind,values[kind])
        if not ok then return false,'invalid_posture' end
        data[kind]=value
    end
    if data.sit and data.lean then return false,'conflicting_postures' end
    if data.sit or data.lean then
        local player=cache.GetPlayer(src,1000)
        local pd=player and (player.PlayerData or player) or {}
        local metadata=pd.metadata or {}
        if metadata.isdead or metadata.inlaststand then return false,'dead_player' end
        local ped=GetPlayerPed(src);if ped==0 then return false,'missing_ped' end
        local pos=GetEntityCoords(ped)
        local coords=(data.sit or data.lean).coords
        if (pos.x-coords.x)^2+(pos.y-coords.y)^2+(pos.z-coords.z)^2>8^2 then return false,'invalid_position' end
    end
    session.sequence=sequence;cache.set(prefix..'binding:'..src,session)
    return true,store(src,session.character,data)
end,{limit=40,window=5000,maxPayload=4096})
ForgeCore.Callbacks.register('forge-core:posture:snapshot',function(src,ids)
    if type(ids)~='table' or #ids>256 then return nil end
    local watched,records={},{}
    for _,id in ipairs(ids) do
        if not Contract.finite(id) or id<=0 or id%1~=0 then return nil end
        if nearby(src,id) then
            watched[id]=true
            local record=cache.get(key(id))
            if record and record.character and record.character~=ForgeCore.Session.character(id) then
                reset(id);record=cache.get(key(id))
            end
            records[id]=ForgeCore.State.copy(record or empty())
        else records[id]=empty(false) end
    end
    cache.set(prefix..'watch:'..src,watched)
    return {generation=generation,records=records}
end,{limit=10,window=5000,maxPayload=8192})
AddEventHandler('pr_bridge:server:OnPlayerLoaded',reset)
AddEventHandler('pr_bridge:server:OnPlayerUnloaded',reset)
AddEventHandler('playerDropped',function()
    local src=tonumber(source);reset(src);cache.clear(key(src))
    for _,viewer in ipairs(GetPlayers()) do
        local watched=cache.get(prefix..'watch:'..viewer)
        if watched then watched[src]=nil end
    end
end)
exports('GetCachedPlayerPosture',function(src) return ForgeCore.State.copy(cache.get(key(tonumber(src) or 0))) end)
AddEventHandler('onResourceStop',function(resource)
    if resource==GetCurrentResourceName() then cache.clearPrefix(prefix) end
end)
