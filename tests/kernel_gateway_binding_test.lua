local T=dofile('tests/kernel_gateway_binding_harness.lua')
for _,side in ipairs({'server','client'})do
    local r=T.new(side);local count=#r.bus;local published=0
    r.surface.onPublish=function(fn)published=published+1;assert(not pcall(fn)or fn()==nil,'precommit endpoint inert')end
    assert(r.binding.Install()and published==4 and #r.bus==count)
    assert(not r.binding.Install());r.loadPhysical()
    local data=r.surface.exports.ForgeQbxCompatDescribe();assert(data.authority=='forge-core'and #data.names==(side=='server'and 105 or 24))
    if side=='server'then
        assert(r.published.SetField('bound108',{same=true}));assert(r.graph.PlayerCore.State.bound108.same)
        assert(r.lookup('GetCoreObject')().Players==r.graph.PlayerCore.State.Players)
    else
        local c=r.consumer();assert(c.loadEntry('modules/playerdata.lua'));assert(c.target.QBX.PlayerData==r.published.GetPlayerData())
    end
    local retained=r.surface.exports.ForgeQbxCompatDescribe
    assert(r.binding.Close()and r.binding.Progress().complete);assert(retained()==nil and r.api.IsCurrent())
    assert(r.gateway.IsCurrent(),'publication must not own gateway');r.finish()
end
local d=T.new('server',false);assert(d.binding.Install());d.loadPhysical();assert(d.published.SetField==nil);d.finish()
print('PASS lot108 four endpoints through actual53/99 transports and physical107;same State/PlayerData,no duplicate listeners,disabled QB,owned revocation preserves Forge/gateways')
