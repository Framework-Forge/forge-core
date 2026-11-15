local T=dofile('tests/kernel_qb_binding_context_harness.lua');local r=T.server();local H=T.H
local core=r.root.EventRegistration;local baseline=r.active()
r.prepareBinding();assert(r.active()==baseline)
r.onListen=function(token)
    if token.name=='QBCore:CallCommand'then
        r.surface.exports.SetField('premature95',true)
        assert(r.lookup('GetCoreObject')==nil,'QB lookup must wait for event commit')
    end
end
assert(r.binding.Install()and not r.binding.Install())
r.onListen=nil;assert(r.graph.PlayerCore.State.premature95==nil,'native export must also wait for both commits')
assert(r.active()==baseline+24 and r.root.EventRegistration==core and core.State=='installed')
local get=r.lookup('GetCoreObject');local object=get()
local pc=r.graph.PlayerCore
pc.Players.CheckPlayerData(2,{citizenid='BIND95',license='license:test',userId=101,money={cash=5,bank=0}})
local player=pc.Lookup.GetPlayer(2)
assert(object.Functions.GetPlayer(2)==player and object.Players==pc.State.Players)
assert(r.framework.GetPlayer(2)==player)
local add=r.lookup('AddJob')
assert(add('bind95job',{label='Bind95',grades={[0]={name='Entry',payment=0}}}))
assert(pc.Groups.GetJob('bind95job')==object.Shared.Jobs.bind95job)
assert(r.surface.exports.SetField('binding95_marker',{active=true}))
assert(pc.State.binding95_marker.active)
r.source=47;local origin
object.Functions.CreateCallback('origin95',function(src,cb,...)origin=table.pack(src,...);cb(nil,'tail')end)
r.emit('QBCore:Server:TriggerCallback','origin95','first',nil,'third')
H.same(origin,table.pack(47,'first',nil,'third'))
assert(r.binding.Close()and r.active()==baseline and core.State=='installed'and r.nativeCore.IsCurrent())
assert(get()==nil and r.surface.exports.SetField('should_not_write',true)==nil and pc.State.should_not_write==nil)
assert(pc.Lookup.GetPlayer(2)==player and r.framework.GetPlayer(2)==player)
r.shutdownAll();assert(r.nativeCore.Progress().complete and r.binding.Progress().complete)
print('PASS lot95 actual server74/89/93/94:14 alias+10 event subscriptions/SetField,same canonical Player/PR81/jobs/source,nil tuples,owned close leaves core registration/data alive;virtual only')
