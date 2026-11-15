local T=dofile('tests/kernel_consumer_context_harness.lua');local L=dofile('tests/kernel_client_locale_harness.lua')
local client=L.new();client.prepareLocale();local core=client.fixture.state
local data={citizenid='RADIO77',job={name='police',onduty=true},gang={name='none'},charinfo={firstname='Ana',lastname='Forge'},metadata={}}
core.PlayerData=data
local consumer=T.new();consumer.ports.getPlayerData=core.LegacyCore.Functions.GetPlayerData
consumer.ports.isCurrent=function()return consumer.current and client.graph.IsCanonical()end
consumer.mount();consumer.api.Require('modules.playerdata');assert(consumer.target.QBX.PlayerData==core.PlayerData)
local cache={};local trace={voice=0,kvp=0,inventory=0,exports={},keybinds={}}
local radio={userData={},onRadio=false};local shared={RestrictedChannels={},RadioItem={'radio'}}
local env=T.H.environment({Radio=radio,QBX=consumer.target.QBX,Shared=shared,
    locale=function(key)return key end,
    pr_lib={addKeybind=function(spec)trace.keybinds[#trace.keybinds+1]=spec.name end,cache={set=function(key,value)cache[key]=value end},table={contains=function(list,item)
        for _,v in pairs(list)do if v==item then return true end end;return false
    end},inventory={Search=function(mode,item)assert(mode=='slots'and item=='radio');trace.inventory=trace.inventory+1;return{}end}},
    SetResourceKvp=function(key)assert(key=='radioSettings2');trace.kvp=trace.kvp+1 end,json={encode=function()return'<virtual>'end},
    exports=setmetatable({['pma-voice']={setVoiceProperty=function(_,key,value)assert(key=='micClicks'and value==true);trace.voice=trace.voice+1 end}},
        {__call=function(_,name,fn)assert((name=='JoinRadio'or name=='LeaveRadio')and type(fn)=='function');trace.exports[#trace.exports+1]=name end})})
T.H.load('../../../[voice]/mm_radio/client/function.lua',env)
T.H.same(trace.exports,{'JoinRadio','LeaveRadio'});T.H.same(trace.keybinds,{'radio','+channel','-channel'})
radio:Init();assert(radio.identifier=='RADIO77'and radio.PlayerJob=='police'and radio.PlayerDuty==true and radio.PlayerGang=='none')
assert(radio.userData.RADIO77.name=='Ana Forge'and cache['mm_radio:character']=='RADIO77')
assert(trace.voice==1 and trace.kvp==1 and trace.inventory==1,'whole installed Radio.Init uses complete character/cache/PR inventory ports')
local nextData={citizenid='B77',job={name='ambulance',onduty=false},gang={name='none'},charinfo={firstname='Bia',lastname='Forge'},metadata={}}
core.PlayerData=nextData;consumer.emit('QBCore:Player:SetPlayerData',nextData);radio:Init()
assert(radio.identifier=='B77'and radio.PlayerJob=='ambulance'and not radio.PlayerDuty and radio.userData.B77.name=='Bia Forge')
consumer.emit('QBCore:Client:OnPlayerUnload');assert(next(consumer.target.QBX.PlayerData)==nil and core.PlayerData==nextData,'unload consumer cannot reset canonical state')
local held=consumer.target.QBX;consumer.api.Close();consumer.emit('QBCore:Player:SetPlayerData',data)
assert(next(held.PlayerData)==nil and core.PlayerData==nextData and consumer.api.Progress().complete)
client.api.Stop();client.clock.advance(120000);client.api.Poll();assert(client.api.Progress().complete)
print('PASS lot77 actual75/76:canonical complete getter,whole installed mm_radio Radio.Init/job/gang/charinfo/character switch,PR inventory/cache ports,unload and closure cannot replace core;virtual only')
