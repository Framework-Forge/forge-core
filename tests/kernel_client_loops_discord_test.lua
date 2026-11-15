local R = dofile('tests/kernel_client_runtime_harness.lua')
local H, count = R.H, 0
local function test(module,name,action,options) R.compare(module,name,action,options); count=count+1 end
for _,logged in ipairs({false,true}) do
    for _,status in ipairs({{hunger=100,thirst=100},{hunger=0,thirst=100},{hunger=100,thirst=0},{}}) do
        for _,dead in ipairs({false,true}) do test('loops','status '..tostring(logged)..tostring(dead),function(r)
            r.core.IsLoggedIn=logged; r.core.Status=H.copy(status); r.dead=dead
            local co=r.start(); assert(select(2,r.step(co))==2000)
            r.step(co); r.step(co)
            return r.health
        end) end
    end
end
test('loops','dynamic login/session/status',function(r)
    local co=r.start(); r.step(co); r.core.IsLoggedIn=true; r.core.Status.hunger=0; r.step(co)
    assert(r.health==193); r.dead=true; r.step(co); assert(r.health==193)
    r.dead=false; r.cache.ped=11; r.step(co); assert(r.health==186)
end)
test('discord','disabled',function(r) assert(r.bags.PlayerCount==nil) end,{enabled=false})
test('discord','enabled setup',function() end)
for _,bag in ipairs({'global','player:1'}) do
    for _,value in ipairs({false,0,1,64}) do test('discord','count '..bag..tostring(value),function(r) r.bags.PlayerCount(bag,nil,value) end) end
end
test('discord','nil count',function(r) r.bags.PlayerCount('global',nil,nil) end)
test('discord','max snapshot',function(r) r.globalState.MaxPlayers=128; r.bags.PlayerCount('global',nil,5); assert(r.trace[#r.trace].args[1]=='Players 5/64') end)
local disabled=R.new(true,'discord',{enabled=false}); assert(not disabled.initialize() and #disabled.trace==0)
local enabled=R.new(true,'discord'); assert(enabled.initialize() and not enabled.initialize() and #enabled.trace==7)
print('PASS client loops/Discord: '..count..' differential cases; bounded hunger/sleep/death/RNG threads, config/disabled/setup/statebag snapshot and explicit idempotent initialization')
