local T=dofile('tests/kernel_late_binding_harness.lua');local r=T.new()
assert(r.constructed==0 and r.ox.active()==0 and #r.ox.timers==0,'late facade constructor never queries/installs core')
local facade=r.late.Framework;assert(not pcall(facade.GetPlayer,2)and not pcall(r.late.Inventory.UseItem,2,'food',{}))
assert(r.late.Attach()and r.constructed==1 and not r.late.Attach());assert(r.late.Framework==facade)
assert(facade.GetPlayer(2)==r.contract.Core:GetPlayer(2)and facade.GetIdentifier(2)=='LATE114')
r.ox.runTimers();assert(r.ox.records[2].owner=='LATE114'and r.late.Inventory.setPlayerData(r.ox.player.PlayerData).source==2)
for name,canonical in pairs(r.latePorts.frameworkMethods)do assert(facade[name]==facade[canonical])end
r.ready=false;assert(not pcall(facade.GetPlayer,2));r.ready=true
assert(r.late.Close()and r.late.Progress().complete and r.ox.active()==0 and r.api.IsCurrent())
assert(not pcall(facade.GetPlayer,2));r.finish()
local I=dofile('tests/kernel_compat_identity_harness.lua');local c=I.new('client');local a=T.A.new('client')
local data=c.catalog.Resolve('GetPlayerData')();a.ports.adapter.view={PlayerData=data};a.ports.adapter.cache=nil
local aliases={};local seen={};for name,fn in pairs(a.source.api.Framework)do seen[fn]=seen[fn]or name;aliases[name]=seen[fn]end
local late=T.H.load('../pr_bridge/bridge/frameworks/forge/late_binding_factory.lua',T.H.environment())({side='client',frameworkMethods=aliases,
    isCurrent=function()return c.api.IsCurrent()end,isReady=function()return true end,
    createSelection=function()return T.H.load('../pr_bridge/bridge/frameworks/forge/selection_factory.lua',T.H.environment())({side='client',identity=c.identity,isCurrent=function()return c.api.IsCurrent()end})end,
    createAdapter=function()return a.mount()end})
assert(next(late.Inventory)==nil and a.active()==0);assert(late.Attach()and a.active()==9 and a.source.pulls==0)
assert(a.ports.adapter.view.PlayerData==data and c.catalog.Resolve('GetPlayerData')()==data)
assert(late.Close()and late.Progress().complete and a.active()==0 and c.api.IsCurrent());c.finish()
print('PASS lot114 no eager core calls,stable facades,53-method adapter aliases,late111/112/83/113 commit,same Forge Player,money/groups,owned reverse close without closing core')
