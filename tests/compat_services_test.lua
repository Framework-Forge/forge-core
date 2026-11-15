-- Run from forge-core. Actual services, isolated persistence/core/export doubles.
local H=dofile('tests/cache_harness.lua')
local r=H.new(true);local e=r.env
e.ForgeCore.t=function(k) return k end
e.joaat=function() return 1 end
e.vector3=function(x,y,z) return {x=x,y=y,z=z} end;e.vec3=e.vector3;e.vec4=e.vector3
e.Config={};e.PRCore={load=function(path)
    local file=path:match('^@pr_bridge/(.*)') or path:gsub('%.','/')
    return r.load('../pr_bridge/'..file..'.lua')
end}
e.pr_lib.load=e.PRCore.load
local definitions,writes,failSync={},0,false
e.exports.ox_inventory={
    Items=function(_,name) if name then return definitions[name] end;return definitions end,
    SetItemDefinition=function(_,name,item)
        if failSync then return false end
        definitions[name]=H.copy(item);writes=writes+1;return true
    end,
}
r.load('shared/inventory.lua');r.load('server/inventory/service.lua')
local inventory=e.ForgeCore.InventoryService
e.SaveResourceFile=function() return false end
assert(not inventory.addCompatibilityItems({{name='water',label='Water',weight=100,stack=true}}))
assert(inventory.items.water==nil and definitions.water==nil and writes==0,'failed save must not mutate inventory')
e.SaveResourceFile=function() return true end
local ok,count=inventory.addCompatibilityItems({{name='water',label='Water',weight=100,stack=true}})
assert(ok and count==1 and inventory.items.water and definitions.water.weight==100,'definition persisted then synchronized')
local before=writes
assert(inventory.addCompatibilityItems({{name='water',label='Changed',weight=500}}))
assert(definitions.water.label=='Water' and writes==before,'AddItems does not overwrite existing definitions')
failSync=true
local success,reason=inventory.addCompatibilityItems({{name='bread',label='Bread',weight=50}})
assert(not success and reason=='runtime_sync_failed:bread' and inventory.items.bread and not definitions.bread,'failed runtime sync is not success')
failSync=false
assert(inventory.addCompatibilityItems({{name='bread',label='Bread',weight=50}}) and definitions.bread,'retry repairs saved-but-unsynchronized definition')
local caller='pr_bridge'
e.GetInvokingResource=function() return caller end
e.IsPrincipalAceAllowed=function(principal,ace) return principal=='resource.allowed' and ace=='forge-core.compat' end
local data={source=1,metadata={},job={name='taxi',grade=0,onduty=true}}
local paid,saves=0,0
local p={PlayerData=data,Functions={
    SetMetaData=function(k,v) data.metadata[k]=v end,Save=function() saves=saves+1 end,
    AddMoney=function(_,amount) paid=paid+amount;return true end,
}}
local jobs={taxi={label='Taxi',type='civ',grades={['0']={name='Driver',payment=50}}}}
e.exports.qbx_core={GetPlayer=function() return p end,GetQBPlayers=function() return {p} end,
    GetJobs=function() return jobs end,GetJob=function(_,name) return jobs[name] end}
e.ForgeCore.JobRegistry={jobs={}}
e.ForgeCore.JobService={upsert=function(source,group,kind)
    assert(source==0 and kind=='job');e.ForgeCore.JobRegistry.jobs[group.name]=group
    jobs[group.name]={label=group.label,type=group.jobtype,grades=group.grades};return true,group
end,reload=function() return true end}
r.load('server/compat.lua')
caller='untrusted'
assert(not pcall(r.exported.CompatTogglePaycheck,1,false),'untrusted server resource must not mutate payroll')
caller='allowed';assert(r.exported.CompatTogglePaycheck(1,false),'explicit resource ACE accepted')
caller='pr_bridge'
assert(not r.exported.CompatIsPaycheckEnabled(1) and saves==1,'native player paycheck metadata persisted')
assert(r.exported.CompatCreateJob({name='taxi',label='Ignored',grades={{grade=1,name='Senior',salary=90}}}))
assert(jobs.taxi.label=='Taxi' and jobs.taxi.grades['0'].payment==50 and jobs.taxi.grades['1'].payment==90,'registry preserves native job fields')
r.load('shared/job.lua');r.load('server/job/payments.lua')
local payments=e.ForgeCore.JobPayments
payments.settings={enabled=true,account='bank',intervalMinutes=10,payOffDuty=true,useSociety=false,notify=false}
local amount=payments.processAll('test')
assert(amount==0 and paid==0,'actual payroll honors individual disabled state')
assert(r.exported.CompatTogglePaycheck(1,true))
amount=payments.processAll('test')
assert(amount==1 and paid==50,'actual payroll resumes with native grade payment')
print('PASS Forge compatibility: item persistence/failure/retry, export authorization, job merge and actual paycheck gate')
