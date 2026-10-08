local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env
local loaded=true
e.ForgeCore.Session={isLoaded=function() return loaded end}
e.ForgeCore.t=function(key) return key end
r.load('shared/whitelist.lua');r.load('client/whitelist/main.lua')
local whitelist
for _,handle in ipairs(r.events['forge-core:session:changed']) do
    for i=1,20 do local name,value=debug.getupvalue(handle.fn,i);if not name then break end;if name=='Whitelist' then whitelist=value end end
end
assert(whitelist)
local requests=0
e.pr_lib.callback.await=function(name)
    assert(name==e.PR.Whitelist.Callbacks.check)
    requests=requests+1;e.Wait(2000)
    return false,{enabled=true}
end
r.fire('QBCore:Client:OnPlayerLoaded',65535);r.advance(4500);assert(requests==1 and whitelist.checking)
r.fire('forge-core:session:changed',nil,'B');r.advance(1500)
assert(whitelist.checking and not whitelist.active,'Old response cannot clear the new character check')
r.advance(2500);assert(requests==2);loaded=false;r.fire('forge-core:session:changed',nil,nil)
r.advance(2500);assert(not whitelist.active and not whitelist.checking,'Late reply cannot start whitelist after logout')

local s=H.new(true);local se=s.env
se.ForgeCore.State={copy=H.copy};se.ForgeCore.t=function(key) return key end
s.players[1]={PlayerData={citizenid='A'}}
local coords=setmetatable({x=0,y=0,z=0},{__sub=function() return setmetatable({}, {__len=function() return 0 end}) end})
se.GetEntityCoords=function() return coords end
s.load('shared/session.lua');s.load('shared/afk.lua');s.load('server/afk/service.lua')
local service=se.ForgeCore.AfkService;service.start();s.advance(2000)
assert(service.remainingSeconds[1]==899)
s.fire('pr_bridge:server:OnPlayerUnloaded',nil,1);s.advance(1000)
assert(not service.remainingSeconds[1] and not service.previousCoords[1])
s.players[1]={PlayerData={citizenid='B'}};s.fire('pr_bridge:server:OnPlayerLoaded',nil,1);s.advance(1000)
assert(service.remainingSeconds[1]==900,'A new character cannot inherit the previous AFK timer')
s.fire('playerDropped',1);assert(not service.remainingSeconds[1])
print('PASS session consumers: yielding whitelist responses across character/logout and AFK cache reset across unload/load/drop')
