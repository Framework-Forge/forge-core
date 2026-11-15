local R=dofile('tests/kernel_automedic_client_harness.lua')
local n=0
local function case(name,fn)R.case(name,fn);n=n+1 end
case('authenticated-not-world-ready',function(r)assert(r.session.Session.isLoaded()and r.session.Session.character()=='C1')end)
case('loaded-false',function(r)r.library.cache.set('playerLoaded',false);assert(not r.session.Session.refresh().loaded)end)
case('auth-false',function(r)r.library.cache.SetResourceState('qbx_core','session',{authenticated=false});assert(not r.session.Session.refresh().loaded)end)
case('no-identifier',function(r)r.data={};assert(not r.session.Session.refresh().loaded)end)
case('empty-identifier',function(r)r.data.citizenid='';assert(not r.session.Session.refresh().loaded)end)
case('identifier-fallback',function(r)r.data.citizenid=nil;r.data.identifier='fallback';assert(r.session.Session.refresh().character=='fallback')end)
case('changed-character',function(r)r.data.citizenid='C2';r.session.Session.refresh();r.session.Session.refresh()end)
case('copy-job',function(r)r.session.Session.refresh();r.data.job.grade.level=8;assert(r.session.Session.group('job').grade.level==1)end)
case('group-refresh',function(r)r.data.job.name='taxi';r.fire('qbx_core:client:cacheChanged',0,{job=true});assert(r.session.Session.group('job').name=='taxi')end)
case('cache-other-no-refresh',function(r)r.data.citizenid='C2';r.fire('qbx_core:client:cacheChanged',0,{health=true});assert(r.session.Session.character()=='C1')end)
case('unload',function(r)r.fire('pr_bridge:client:OnPlayerUnloaded',0);assert(not r.session.Session.isLoaded())end)
case('load',function(r)r.fire('pr_bridge:client:OnPlayerUnloaded',0);r.fire('pr_bridge:client:OnPlayerLoaded',0);assert(r.session.Session.isLoaded())end)
for _,name in ipairs({'pr_bridge:client:OnInventoryChanged','QBCore:Client:OnJobUpdate','QBCore:Client:OnGangUpdate','QBCore:Client:SetDuty'})do
    case('defer-'..name,function(r)r.data.citizenid='C2';r.fire(name,0);assert(r.session.Session.character()=='C1');r.advance(1);assert(r.session.Session.character()=='C2')end)
end
case('stop-own',function(r)r.fire('onResourceStop',0,'forge-core');assert(not r.session.Session.isLoaded())end)
case('stop-other',function(r)r.fire('onResourceStop',0,'other');assert(r.session.Session.isLoaded())end)
case('late-defer-after-unload',function(r)r.fire('QBCore:Client:SetDuty',0);r.fire('pr_bridge:client:OnPlayerUnloaded',0);r.advance(1)
    assert(r.session.Session.isLoaded(),'installed deferred refresh can repopulate without new delivered flag')end)
print('PASS Forge client session view differentials '..n)
