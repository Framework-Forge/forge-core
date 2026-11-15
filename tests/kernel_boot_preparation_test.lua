local H=dofile('tests/kernel_harness.lua');local contract=H.load('kernel/entry/boot_input_contract.lua',H.environment())
local factory=H.load('kernel/entry/boot_preparation.lua',H.environment());local calls={}
local function record(v)calls[#calls+1]=v end
local fn=function()return true end
local options={base={},public={},nativeCache={resource='forge-core'},events={listen=fn,remove=fn,source=fn,markNetwork=fn},
 bootstrap={context={},registration={available=fn},isCurrent=fn,isReady=fn},domainLocale=fn,locale=fn,inventoryBridgeProbe=fn,isCurrent=fn,onError=fn}
local providers={buildInput=function()return options end}
local p={contract=contract,side='client',inspectFunction=function()return{source='@native/provider.lua'}end,providers=providers,
 createRaw=function()record('raw');return{Prepare=function()record('raw.prepare');return true end,Close=function()record('raw.close');return true end}end,
 createEntry=function()record('entry');return{Prepare=function()record('entry.prepare');return true end,Install=function()record('install');return true end,
 Start=function()record('start');return true end,Stop=function()record('stop');return true end,Poll=fn,Progress=function()return{}end}end}
local api=factory(p);assert(api.Inspect().accepted and #calls==0 and not api.Prepare()and #calls==0)
providers.constructionApproved=true;assert(api.Prepare()and table.concat(calls,',')=='raw,raw.prepare,entry,entry.prepare')
assert(not api.Install());providers.installApproved=true;assert(api.Install());assert(not api.Start());providers.startApproved=true;assert(api.Start())
assert(api.Stop()and api.Progress().complete and calls[#calls]=='raw.close')
local blocked=factory({contract=contract,side='client',inspectFunction=p.inspectFunction,createRaw=function()error('must not construct')end})
assert(not blocked.Inspect().accepted and not blocked.Prepare());assert(blocked.Stop())
local changed=blocked.Inspect();changed.accepted=true;changed.issues[1].reason='changed';assert(not blocked.Inspect().accepted and blocked.Inspect().issues[1].reason~='changed')
local test=factory({contract=contract,side='client',inspectFunction=function()return{source='@tests/provider.lua'}end,providers={buildInput=function()error('test builder must not run')end}})
assert(not test.Inspect().accepted and test.Inspect().issues[1].reason=='test_builder')
print('PASS169 missing/test builder refused before invocation;input inspection pure;Prepare/Install/Start separately gated;Stop closes entry then raw')
