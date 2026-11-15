local T=dofile('tests/kernel_late_binding_harness.lua');local H=T.H;local root='../../../../.planning/migration/staging/115/'
local function read(name)local f=assert(io.open(root..name,'rb'));local s=f:read('*a');f:close();return s end
local package=test_decode_json(read('package.json'));assert(package.operationalReady==false and package.state=='prepared-inactive')
local compiled=0;for _,f in ipairs(package.files)do if f.path:match('%.lua$')then assert(load(read(f.path),'@@package115/'..f.path,'t',{}));compiled=compiled+1 end end
assert(compiled==17 and #package.requires==8)
for _,public in ipairs({false,true})do
    local path=public and'pr_bridge/init.lua'or'pr_bridge/bridge/init.lua';local source=read(path)
    local code=public and source:match('(local function getBridgePath%(bridgeType%)[%s%S]-)\nlocal function loadBridgeModule')or source:match('(local function getBridge%(bridgeType%)[%s%S]-)\n%s*Bridge = ')
    assert(code,'physical selector source boundary');local active={};local config={Framework='forge'};local registry={frameworks={{resource='qbx_core',folder='qbx'}}};local checks=0
    local env=H.environment({Config=config,ConfigBridge=registry,PRCore={context='server',isResourceStarted=function()checks=checks+1;return true end},
        setActiveBridge=function(kind,folder)active[kind]=folder end})
    env.env={Config=config,ConfigBridge=registry};local fn=assert(load(code..'\nreturn '..(public and'getBridgePath'or'getBridge'),'@@selector115','t',env))()
    local selected=fn('frameworks');assert(selected==(public and'@pr_bridge/bridge/frameworks/forge/server'or'bridge.frameworks.forge.server')and active.frameworks=='forge'and checks==0)
    config.Framework='qbx';assert(fn('frameworks')==(public and'@pr_bridge/bridge/frameworks/qbx/server'or'bridge.frameworks.qbx.server')and checks>0)
    local line=assert(source:match('(local normalizeFramework = [^\n]+)'))
    local normalEnv=H.environment({ActiveBridges={frameworks='forge'},PRCore={load=function()error('legacy normalizer must not run for Forge')end}});normalEnv.env={ActiveBridges={frameworks='forge'}}
    assert(assert(load(line..'\nreturn normalizeFramework','@@normalizer115','t',normalEnv))()==nil)
end
local r=T.new();local N=dofile('tests/kernel_forge_normalization_harness.lua');local n=N.new(true,'server')
n.ports.framework=r.late.Framework;n.ports.resourceName='forge-core';n.ports.isCurrent=function()return r.late.Progress().phase~='closed'and r.api.IsCurrent()end
for name in pairs(n.ports.core)do local fn=r.catalog.Resolve(name);n.ports.core[name]=function(...)assert(r.late.Progress().phase=='attached','normalization core port not ready');return fn(...)end end
local normalized=assert(load(read('pr_bridge/bridge/frameworks/forge/normalization_factory.lua'),'@@normalization84-package115','t',H.environment()))()(n.ports)
local pr={context='server',forgeLateBinding=r.late,forgeNormalizedFacade=normalized.Framework}
local env=H.environment({PRCore=pr,ActiveBridges={frameworks='forge'}})
local returned=assert(load(read('pr_bridge/bridge/frameworks/forge/server.lua'),'@@pr_bridge/forge/server','t',env))()
assert(returned==normalized.Framework and not pcall(returned.GetPlayer,2))
local ox=H.environment({pr_lib={forgeLateBinding=r.late},server=r.ox.server})
assert(load(read('ox_inventory/modules/bridge/forge/server.lua'),'@@ox_inventory/forge/server','t',ox))()
assert(r.ox.active()==0 and #r.ox.timers==0 and not pcall(r.ox.server.UseItem,2,'food'))
assert(r.late.Attach()and returned.GetIdentifier(2)=='LATE114');r.ox.runTimers();assert(r.ox.records[2].owner=='LATE114')
normalized.Close();assert(r.late.Close()and r.late.Progress().complete and returned.GetPlayer(2)==nil);r.finish()
local c=T.A.new('client');local fake={Framework={GetPlayer=function()return'client facade'end},Attach=function()error('entry must not attach eagerly')end}
local clientEnv=H.environment({PRCore={context='client',forgeLateBinding=fake,forgeNormalizedFacade=fake.Framework},ActiveBridges={frameworks='forge'}})
assert(assert(load(read('pr_bridge/bridge/frameworks/forge/client.lua'),'@@pr_bridge/forge/client','t',clientEnv))()==fake.Framework)
print('PASS lot115 physical17 Lua files,two PR selectors/no eager state query,legacy mode preserved,no legacy Forge normalization,PR/OX deferred entries and actual114 late commit/close')
