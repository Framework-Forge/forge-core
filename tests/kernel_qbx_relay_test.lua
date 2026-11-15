local T=dofile('tests/kernel_qbx_relay_harness.lua');local H=T.H
for _,side in ipairs({'server','client'})do
    local r=T.new(side);assert(next(r.published)==nil);assert(r.installRelay())
    local n=0;for _ in pairs(r.published)do n=n+1 end;assert(n==(side=='server'and 105 or 24))
    if side=='server'then
        local pc=r.graph.PlayerCore;pc.Players.CheckPlayerData(2,{citizenid='RELAY103',license='license:test',userId=101,money={cash=10,bank=0}})
        assert(r.published.GetPlayer(2)==pc.Lookup.GetPlayer(2),'no new Player in shim')
        r.published.SetMetadata(2,'relay103',17);assert(pc.Lookup.GetPlayer(2).PlayerData.metadata.relay103==17)
        assert(r.published.AddMoney(2,'cash',5,'relay103'));assert(r.published.GetMoney(2,'cash')==15)
        local allowed,reason=r.published.SetVehicles({});assert(allowed==false and reason=='unauthorized_resource','consumer identity must not become privileged Forge')
        r.caller='forge-core';assert(r.published.SetVehicles({}));r.caller='consumer103'
        local callback=function(...)return nil,'returned',...end;r.published.CreateUseableItem('relay103',callback)
        assert(r.published.CanUseItem('relay103')==callback);local result=table.pack(r.published.CanUseItem('relay103')(1,nil,3,nil))
        H.same(result,table.pack(nil,'returned',1,nil,3,nil),'callback reference/nil tuples retained')
        assert(r.published.GetCachedState('session:2')~=nil)
    else
        local data=r.fixture.state.PlayerData;data.citizenid='RELAY103C';assert(r.published.GetPlayerData()==data)
        assert(r.published.GetJobs()==r.graph.Central.Parts.Legacy.Groups.Exports.GetJobs())
        assert(r.published.GetCachedState('invented-domain')==nil)
    end
    r.relay.Close();assert(not pcall(r.published.GetJobs));assert(r.api.IsCurrent(),'relay Close must not close core')
    r.gateway.Close();assert(r.api.IsCurrent());assert(r.finish())
end
print('PASS lot103 actual server74/client75 relay:105/24 native exports,same Player/money/metadata/groups/session,origin-aware vehicle ACL,callbacks/nils,owned Close;all resource/SQL/native boundaries virtual')
