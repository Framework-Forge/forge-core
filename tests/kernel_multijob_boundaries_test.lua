local N=dofile('tests/kernel_multijob_harness.lua')
local H=N.H
for _,state in ipairs({'stopped','starting','started'})do
    for _,status in ipairs({{jailed=false,status='free'},{jailed=true},{status='jailed'},'invalid'})do
        N.case('prison status '..state..tostring(status.status or status),function(r)r.prisonState=state;r.prisonStatus=status;return r.prison.status('1'),r.prison.canChangeJobs('1')end)
    end
end
N.case('provider returns nil',function(r)r.prisonState='started';r.prisonStatus=nil;return r.prison.canChangeJobs(1)end)
N.case('provider error becomes nil',function(r)r.prisonState='started';r.providerError=true;return r.prison.status(1),r.prison.canChangeJobs(1)end)
N.case('metadata jailed fallback',function(r)r.players[1].PlayerData.metadata.prisonStatus='jailed';return r.prison.canChangeJobs(1)end)
N.case('metadata injail string fallback',function(r)r.players[1].PlayerData.metadata.injail='2';return r.prison.canChangeJobs(1)end)
N.case('missing player fallback permits but multijob guards ownership',function(r)return r.prison.canChangeJobs(999),r.api.setActiveJob(999,'taxi')end)
N.case('nil provider fallback',function(r)return r.prison.status(1),r.prison.canChangeJobs(1)end,function(r)r.providerNil=true end)
N.case('prison sentence admin',function(r)r.prisonState='started';return r.prison.setSentence(2,'1',{time=3})end)
N.case('prison sentence permission',function(r)return r.prison.setSentence(1,2,{})end)
N.case('prison sentence invalid target',function(r)return r.prison.setSentence(2,999,{})end)
N.case('prison sentence invalid type',function(r)return r.prison.setSentence(2,1,'invalid')end)
N.case('prison sentence unavailable',function(r)return r.prison.setSentence(2,1,{})end)
N.case('prison sentence provider throws',function(r)r.prisonState='started';r.providerError=true;return r.prison.setSentence(2,1,{})end)
N.case('prison release',function(r)r.prisonState='started';return r.prison.release(2,1)end)
N.case('prison release permission',function(r)return r.prison.release(1,2)end)
N.case('prison release invalid target',function(r)return r.prison.release(2,'bad')end)
N.case('prison exact true only',function(r)r.prisonState='started';r.prisonResult=table.pack(1,'not boolean');return r.prison.release(2,1)end)
for _,key in ipairs({'getSettings','saveSettings','getPlayerJobs','setActiveJob','removeOwnJob','addJob','removeJob','getTargetJobs'})do
    N.case('callback '..key,function(r)
        local args={getSettings={2},saveSettings={2,{}},getPlayerJobs={1},setActiveJob={1,'police'},
            removeOwnJob={1,'taxi'},addJob={2,1,'taxi',0},removeJob={2,1,'taxi'},getTargetJobs={2,'1'}}
        return r.callbacks[r.config.Callbacks[key]](table.unpack(args[key]))
    end)
end
N.case('callback settings denied',function(r)return r.callbacks[r.config.Callbacks.getSettings](1)end)
N.case('callback target denied',function(r)return r.callbacks[r.config.Callbacks.getTargetJobs](1,2)end)
N.case('callback target coerced',function(r)return r.callbacks[r.config.Callbacks.getTargetJobs](2,'bad')end)
local r=N.new(true);local api=r.core
assert(not api.Service.Initialize(),'idempotent wrapping')
assert(not pcall(H.load('kernel/server/multijob/multijob_core.lua',N.env()),r.base,{}),'duplicate attach rejected')
local alien={Groups=r.groups,PlayerCore={Groups={}},JobCatalog=r.base.JobCatalog,Callbacks=r.base.Callbacks}
assert(not pcall(H.load('kernel/server/multijob/multijob_core.lua',N.env()),alien,{}),'foreign groups rejected')
local admins={getSettings=true,saveSettings=true,addJob=true,removeJob=true,getTargetJobs=true}
for key,name in pairs(r.config.Callbacks)do
    local found
    for _,entry in ipairs(api.Callbacks)do if entry.name==name then found=entry end end
    assert(found and found.options.access==(admins[key]and'admin'or'player'),'explicit installed access classification '..key)
end
print('PASS multijob/prison boundaries: '..N.count..' differential cases; complete four policy methods/eight callback handlers, installed PR prison and explicit admin/player classification, no real jail/release')

