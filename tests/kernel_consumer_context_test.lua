local T=dofile('tests/kernel_consumer_context_harness.lua');local H,P=T.H,T.P
local cases=0
for _,kind in ipairs({'initial','missing','false','set','nil','unload'})do
    local data={citizenid='A',job={name='police'},gang={name='none'},charinfo={firstname='Ana'}}
    if kind=='missing'then data=nil elseif kind=='false'then data=false end
    local old=T.original('client',data);local r=T.new();r.data=data;r.mount()
    assert(r.gets==0 and r.active()==0 and r.target.QBX==r.oldQBX,'constructor inert')
    assert(r.api.Require('@qbx_core/modules/playerdata.lua')==true)
    assert(r.api.Require('modules.playerdata')and r.gets==1 and r.active()==2 and #r.marked==2)
    if kind=='set'or kind=='nil'then
        local value=kind=='set'and{citizenid='B',money={cash=7}}or nil
        old.emit('QBCore:Player:SetPlayerData',value);r.emit('QBCore:Player:SetPlayerData',value)
        assert(r.target.QBX.PlayerData==value,'payload reference and nil retained')
    elseif kind=='unload'then
        old.emit('QBCore:Client:OnPlayerUnload');r.emit('QBCore:Client:OnPlayerUnload');assert(data.citizenid=='A')
    elseif data then assert(r.target.QBX.PlayerData==data)end
    H.same(P.snapshot(r.target.QBX),P.snapshot(old.target.QBX),kind);assert(r.gets==old.gets);cases=cases+1
    assert(r.api.Close());assert(r.active()==0 and r.target.QBX==r.oldQBX and r.api.Progress().complete)
end
local server=T.new('server');server.mount();assert(server.api.Require('modules/playerdata.lua'))
assert(server.gets==0 and server.active()==0 and server.target.QBX==server.oldQBX)
assert(T.original('server',{}).target.QBX==nil);cases=cases+1;server.api.Close();assert(server.api.Progress().complete)
local mixed=T.new();mixed.mount();mixed.api.Require('modules.lib');mixed.api.Require('modules.playerdata')
assert(mixed.target.qbx.string.trim(' a ')=='a'and mixed.api.Has('shared.locale'))
local foreign={name='other consumer'};mixed.target.QBX=foreign;mixed.emit('QBCore:Player:SetPlayerData',{citizenid='WRONG'})
assert(foreign.PlayerData==nil and not mixed.api.IsCurrent());mixed.api.Close();assert(mixed.target.QBX==foreign)
local a,b=T.new(),T.new();a.mount();b.mount();a.api.Require('modules.playerdata');b.api.Require('modules.playerdata');a.api.Close()
b.emit('QBCore:Player:SetPlayerData',{citizenid='B'});assert(b.target.QBX.PlayerData.citizenid=='B'and b.active()==2)
print('PASS lot77 consumer:'..cases..' whole original PlayerData cases,aliases/cache/inert side,full references/nil/unload,mixed76,foreign namespace and consumer isolation;virtual only')
