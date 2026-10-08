-- Isolated runtime: actual PR Bridge cache, no FXServer/SQL/file writes.
local H={}
H.bridge='../pr_bridge/'
function H.copy(value)
    if type(value)~='table' then return value end
    local result={};for key,item in pairs(value) do result[key]=H.copy(item) end;return result
end
function H.new(server)
    local runtime={now=10000,queue={},events={},callbacks={},out={},exported={},players={},buckets={},positions={}}
    local env=setmetatable({ForgeCore={},PR={},ActiveBridges={frameworks='qbx'}},{__index=_G})
    runtime.env=env
    local function load(path) return assert(loadfile(path,'t',env))() end
    runtime.load=load
    env.IsDuplicityVersion=function() return server end
    env.GetGameTimer=function() return runtime.now end
    env.GetCurrentResourceName=function() return 'forge-core' end
    env.GetResourceState=function() return 'started' end
    env.GetGameName=function() return 'gta5' end
    env.GetConvar=function(_,fallback) return fallback end
    env.GetConvarInt=function(_,fallback) return fallback end
    env.GetPlayerPing=function(src) return runtime.players[src] and 50 or 0 end
    env.GetPlayers=function()
        local list={};for src in pairs(runtime.players) do list[#list+1]=tostring(src) end;return list
    end
    env.GetPlayerRoutingBucket=function(src) return runtime.buckets[src] or 0 end
    env.GetPlayerPed=function(src) return runtime.players[src] and src or 0 end
    env.GetEntityCoords=function(ped) return runtime.positions[ped] or {x=0,y=0,z=0} end
    env.GetPlayerName=function(src) return runtime.players[src] and 'Player '..src end
    env.IsPlayerAceAllowed=function() return true end
    env.AddEventHandler=function(name,fn)
        runtime.events[name]=runtime.events[name] or {};local handle={fn=fn}
        table.insert(runtime.events[name],handle);return handle
    end
    env.RegisterNetEvent=env.AddEventHandler
    env.RemoveEventHandler=function(handle) handle.fn=nil end
    runtime.fire=function(name,source,...)
        local previous=env.source;env.source=source
        for _,handle in ipairs(runtime.events[name] or {}) do if handle.fn then handle.fn(...) end end
        env.source=previous
    end
    env.TriggerEvent=function(name,...) runtime.fire(name,env.source,...) end
    env.TriggerClientEvent=function(name,target,...)
        runtime.out[#runtime.out+1]={name=name,target=target,args=H.copy({...})}
    end
    env.CreateThread=function(fn) runtime.queue[#runtime.queue+1]={at=runtime.now,co=coroutine.create(fn)} end
    env.Wait=function(ms) return coroutine.yield(ms) end
    env.SetTimeout=function(ms,fn) runtime.queue[#runtime.queue+1]={at=runtime.now+ms,co=coroutine.create(fn)} end
    runtime.advance=function(ms)
        local finish=runtime.now+ms;local steps=0
        while true do
            table.sort(runtime.queue,function(a,b) return a.at<b.at end)
            local task=runtime.queue[1]
            if not task or task.at>finish then break end
            table.remove(runtime.queue,1);runtime.now=task.at;steps=steps+1;assert(steps<10000,'Runaway coroutine')
            local ok,delay=coroutine.resume(task.co);assert(ok,delay)
            if coroutine.status(task.co)~='dead' then
                task.at=runtime.now+math.max(1,tonumber(delay) or 0);runtime.queue[#runtime.queue+1]=task
            end
        end
        runtime.now=finish
    end
    env.exports=setmetatable({}, {__call=function(_,name,fn) runtime.exported[name]=fn end})
    env.exports['forge-core']=setmetatable({}, {__index=function(_,name)
        return function(_,...) return assert(runtime.exported[name],'Missing export '..name)(...) end
    end})
    env.json={encode=function() return '{}' end,decode=function() return {} end}
    env.LoadResourceFile=function() return nil end
    env.SaveResourceFile=function() return true end
    env.GlobalState=setmetatable({}, {__index=function() error('Legacy global read') end,__newindex=function() error('Legacy global write') end})
    env.LocalPlayer={state=setmetatable({}, {__index=function() error('Legacy player read') end})}
    env.AddStateBagChangeHandler=function() error('Legacy bag handler') end
    env.pr_lib={framework={
        GetPlayer=function(src) return runtime.players[src] end,
        GetPlayerData=function() return runtime.data or {} end,
        IsPlayerLoaded=function() return runtime.data and runtime.data.citizenid~=nil or false end,
    },callback={register=function(name,fn) runtime.callbacks[name]=fn end},table={clone=H.copy},
        loadJson=function() return nil end,saveJson=function() return true end,
        inventory={RegisterShop=function() end,RemoveShop=function() end,RegisterUsableItem=function() return true end,GetItems=function() return {} end},
        utils={trim=function(v) return tostring(v or ''):match('^%s*(.-)%s*$') end}}
    env.pr_lib.callback.await=function(name,_,...) return assert(runtime.callbacks[name],'Missing callback '..name)(1,...) end
    load(H.bridge..'bridge/persistence.lua')(env.pr_lib, function(path) return 'forge-core', path end)
    env.pr_lib.loadJsonRecovery=function(...) return env.pr_lib.loadJson(...) end
    env.pr_lib.cache=load(H.bridge..'bridge/cache/shared.lua')(env.pr_lib,env.ActiveBridges)
    load(H.bridge..'bridge/cache/resources.lua')(env.pr_lib.cache)
    return runtime
end
return H
