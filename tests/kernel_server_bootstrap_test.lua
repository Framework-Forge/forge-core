local T=dofile('tests/kernel_server_worker_harness.lua');local H=T.H
local names={'CharacterSlotService','JobService','JobPayments','SkillService','WeaponService','StaffService','AfkService','PasswordService',
    'WhitelistService','DensityService','MultiJobService','VinewoodService','ObjectsService','NpcsService','SpotlightsService','BillboardsService',
    'StoresService','FarmsService','StarterpackService','DatabaseBackupService','AutoMedicService'}
local function fixture(ported,absent,debugEnabled)
    local r={trace={},events={},timers={},source=2,services={}}
    local function record(...)r.trace[#r.trace+1]=table.pack(...)end
    for _,name in ipairs(names)do if name~=absent then r.services[name]={start=function()record('start',name)end}end end
    for name,method in pairs({JobService='sendTo',StaffService='applyPlayer',StarterpackService='handlePlayerLoaded'})do
        if r.services[name]then r.services[name][method]=function(src)record(method,src)end end
    end
    local library={debug={setEnabled=function(v)record('debug',v)end}}
    local native={wait=function(ms)record('wait',ms)end,setTimeout=function(ms,fn)r.timers[#r.timers+1]={ms=ms,fn=fn}end}
    if ported then
        r.api=H.load('kernel/server/bootstrap.lua',H.environment())({services=r.services,library=library,native=native,debugEnabled=debugEnabled})
        for _,d in ipairs(r.api.Events)do r.events[d.name]=function()return d.handler(r.source)end end
        r.begin=function()r.api.Begin();for _,d in ipairs(r.api.Services)do d.handler()end end
    else
        local e=H.environment({ForgeCore=r.services,pr_lib=library,PR={Debug=debugEnabled},source=2,Wait=native.wait,SetTimeout=native.setTimeout,
            CreateThread=function(fn)r.begin=fn end,RegisterNetEvent=function(n,fn)r.events[n]=fn end,AddEventHandler=function(n,fn)r.events[n]=fn end})
        H.load('server/main.lua',e);r.environment=e
    end
    function r.setSource(src)r.source=src;if r.environment then r.environment.source=src end end
    return r
end
local count=0
local function case(name,fn,absent,debugEnabled)
    local a,b=fixture(false,absent,debugEnabled),fixture(true,absent,debugEnabled)
    fn(a);fn(b);H.same(b.trace,a.trace,name..' effects');assert(#b.timers==#a.timers)
    for i,t in ipairs(a.timers)do assert(t.ms==b.timers[i].ms)end
    count=count+1
end
case('all21 startup order',function(r)assert(#r.trace==0);r.begin();assert(#r.trace==23)end,nil,true)
case('debug false',function(r)r.begin()end,nil,false)
case('optional service absent',function(r)r.begin()end,'AutoMedicService',true)
case('loaded source',function(r)r.events['QBCore:Server:OnPlayerLoaded']()end)
case('joining delayed source captured',function(r)r.events.playerJoining();r.setSource(99);for _,t in ipairs(r.timers)do t.fn()end end)
case('two joining sources',function(r)r.events.playerJoining();r.setSource(7);r.events.playerJoining();r.setSource(99);for _,t in ipairs(r.timers)do t.fn()end end)
case('missing job ingress',function(r)r.events['QBCore:Server:OnPlayerLoaded']();r.events.playerJoining();r.timers[1].fn()end,'JobService')
case('missing staff ingress',function(r)r.events['QBCore:Server:OnPlayerLoaded']();r.events.playerJoining();r.timers[1].fn()end,'StaffService')
print('PASS lot59 Forge server/main '..count..' whole-file differential cases;21 ordered starts/two supplemental event descriptors, virtual effects only')
