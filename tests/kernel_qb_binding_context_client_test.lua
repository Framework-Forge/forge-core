local T=dofile('tests/kernel_qb_binding_context_harness.lua');local r=T.client();local H=T.H
local core=r.root.EventRegistration;local baseline=r.active()
r.prepareBinding();assert(r.active()==baseline);assert(r.binding.Install())
assert(r.active()==baseline+15 and core.State=='installed')
local get=r.lookup('GetCoreObject');local object=get()
assert(object.Functions.GetPlayerData()==r.root.PlayerData)
local original=object.PlayerData;r.root.PlayerData={citizenid='CLIENT95',money={cash=9}}
assert(get().Functions.GetPlayerData()==r.root.PlayerData and object.PlayerData==original)
local overlaps=0
for _,d in ipairs(r.binding.Events.Describe())do if d.coreHandlers>0 then overlaps=overlaps+1 end end
assert(overlaps==2,'only the two installed group update names overlap here')
local groups=r.graph.Central.Parts.Legacy.Groups
local old=object.Shared.Jobs
r.fixture.central.ports.legacy.jobs={newSeed={label='New Seed'}}
assert(groups.Initialize());assert(groups.GetJobs()~=old)
local job={label='Update95'}
r.emit('qbx_core:client:onJobUpdate','job95',job)
assert(groups.GetJobs().job95==job and old.job95==job)
local before=#r.fixture.central.runtime.trace
object.Functions.Notify('message95','inform',1000)
assert(#r.fixture.central.runtime.trace==before+1)
r.lookup('DrawText')('Text95','top')
assert(r.stub.trace[#r.stub.trace].kind=='show')
assert(r.binding.Close()and r.active()==baseline and r.root.EventRegistration==core and r.nativeCore.IsCurrent())
assert(get()==nil and r.root.PlayerData.citizenid=='CLIENT95')
r.shutdownAll();assert(r.nativeCore.Progress().complete and r.binding.Progress().complete)
print('PASS lot95 actual client75/92/93/94:5 alias+10 event subscriptions,same current PlayerData/retained QB view/Notify/groups,2 legitimate overlaps after catalog replacement,owned close leaves core alive;virtual only')
