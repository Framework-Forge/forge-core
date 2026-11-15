local H=dofile('tests/kernel_harness.lua');local env=H.environment();local calls={};local events={};local dropped=0;local lookups=0
local n={GetResourceState=function(r)return r=='forge-dk'and'started'or'missing'end,
 GetConvar=function(k,d)if k=='pr_bridge:admin'then return'citizenid:CID'end;return d end,
 GetPlayerIdentifiers=function()return{}end,IsPlayerAceAllowed=function()return false end,IsPrincipalAceAllowed=function()return false end,
 ExecuteCommand=function()end,GetCurrentResourceName=function()return'forge-core'end,LoadResourceFile=function()return nil end,
 TriggerClientEvent=function(...)calls[#calls+1]=table.pack(...)end,TriggerEvent=function(...)calls[#calls+1]=table.pack(...)end}
local ext={['forge-dk']={GetDocumentItems=function(self)assert(self==ext['forge-dk']);return true,{license=true}end}}
-- Declare receiver after the table exists;no global export is used.
ext['forge-dk'].GetDocumentItems=function(self)assert(self==ext['forge-dk']);return true,{license=true}end
local f={Side='server',IsCurrent=function()return true end,Seed={IO={Codec={},Files={LoadResourceFile=n.LoadResourceFile,SaveResourceFile=function()return true end}}},
 Events={listen=function(name,cb)local t={name=name,fn=cb};events[#events+1]=t;return t end,remove=function()dropped=dropped+1;return true end}}
local a=H.load('../pr_bridge/bridge/delivery/forge_server_integrations.lua',env)({foundation=f,native=n,external=ext,environment=env,
 loadPR=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end,
 identity={GetIdentifier=function()lookups=lookups+1;return'CID'end,GetPlayer=function()return{PlayerData={citizenid='CID'}}end},httpRequest=function()end,
 debug=function()end,lang={t=function(_,key)return key end}})
assert(#calls==0 and #events==0 and lookups==0)
assert(#a.Callbacks==1 and a.Callbacks[1].name=='pr_bridge:checkPlayerAce')
assert(a.Ace.isPlayerAceAllowed(3,'forge-core.admin')and lookups>0)
local ready,items=a.Documents.getDocumentItems();assert(ready and items.license)
assert(not a.Prison.isAvailable());local no,why=a.Prison.jail(3,{});assert(no==nil and why=='prison_unavailable')
local fired=0;a.Purchases.onPurchaseResult('owned',function()fired=fired+1 end);events[1].fn();assert(fired==1)
a.Consumption.useLockpick(3,true);assert(#calls==2 and calls[1][1]=='lockpicks:UseLockpick')
assert(type(a.Progression.accept)=='function'and a.Progression.round(1.23456)==1.2346)
assert(a.Close()and dropped==1);events[1].fn();assert(fired==1 and not pcall(a.Documents.getDocumentItems))
print('PASS203 installed ACE local identity/admin whitelist,PR documents/prison/progression,purchase ownership,lockpick dual event and revocation')
