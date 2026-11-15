local T=dofile('tests/kernel_engine_ports_harness.lua');local schema=T.H.load('kernel/entry/client_engine_schema.lua',T.H.environment())()
local r=T.new('client',schema);local e=r.mount146();local p=e.Select(schema);local count=0
for name,target in pairs(schema)do if target:sub(1,1)~='$'and target~='CreateThread'and target~='SetTimeout'and target~='Wait'then
    local token={};T.H.same(table.pack(p[name](token,nil,12)),table.pack(r.native[target](token,nil,12)),name);count=count+1
end end
assert(schema.time=='GetGameTimer'and schema.SetTrafficLightsState2==nil)
r.clock.now=9182;assert(p.time()==9182 and p.gameTimer()==9182);r.source=65535;assert(p.source()==65535)
assert(p.vector==p.vec3 and p.vector3==p.vec3 and p.playerPed==p.PlayerPedId and p.serverId==p.GetPlayerServerId)
e.Close();assert(not pcall(p.PlayerPedId));r.finish146()
print('PASS147 client engine aliases:'..count..' direct forwarding comparisons,Skills milliseconds,vectors/player aliases and optional native preserved')
