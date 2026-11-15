-- Real private graph through world35, plus Vinewood37. All external effects remain virtual.
local R=dofile('tests/kernel_vinewood_harness.lua')
local H=R.H
local file=assert(io.open('tests/kernel_world_composition_test.lua','r'))
local source=file:read('*a'):gsub('\r\n','\n');file:close()
local cut=assert(source:find('graph.register(client.Events)',1,true))
local g=assert(load(source:sub(1,cut-1)..[[
return {graph=graph,base=base,r=r,wire=wire,config=config,server=server,client=client,fixture=fixture,settings=g.settings,menus=g.menus}
]],'@canonical-world35-settings34','t',_ENV))()
local graph,base,r,wire,config=g.graph,g.base,g.r,g.wire,g.config
local fixture=R.new(true)
fixture.library.framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})
fixture.native.GetGameTimer=g.fixture.native.GetGameTimer
local before,ioBefore=#fixture.trace,#fixture.m.trace
local server=H.load('kernel/server/vinewood_core.lua',R.env())(base,{
    config=fixture.config,library=fixture.library,native=fixture.native,translate=fixture.translate})
assert(#fixture.trace==before and #fixture.m.trace==ioBefore and not server.Service.started,'inactive Vinewood composition')
assert(server.Base==base and server.PlayerCore==base.PlayerCore and server.Security==base.Callbacks)
assert(server.State==g.server.State and server.State==base.JobCatalog.Dependencies.State,'same world authority')
assert(base.JobCatalog.Dependencies.VinewoodService==server.Service,'holder exposes one service')
assert(not pcall(H.load('kernel/server/vinewood_core.lua',R.env()),base,{}),'duplicate server refused')
for _,d in ipairs(server.Callbacks)do base.Callbacks.register(d.name,d.handler,d.options)end
for _,d in ipairs(g.server.RawCallbacks)do wire.server.api.register(d.name,d.handler)end
config.Vinewood=server.Config.Vinewood
R.platform(r)
r.library.command=function()error('command not installed by constructor')end
local clientPorts={client=graph.client,config=config,library=r.library,native=r.native}
before=#r.trace
local client=H.load('kernel/client/vinewood_core.lua',R.env())(graph.state,clientPorts)
assert(#r.trace==before+1 and r.trace[#r.trace].kind=='translate'and next(r.entities)==nil,'only local command help translation; no registration/entity/IO')
assert(client.Menu==g.menus.Menu and client.Shared==g.menus.Shared and client.WorldState==g.client.WorldState)
assert(client.Session==graph.medical.Session and client.Session.Session==graph.client.ForgeSession,'Session31 reused')
assert(#client.Commands==1 and client.Commands[1].transport=='pr','command registration remains a descriptor')
assert(not pcall(H.load('kernel/client/vinewood_core.lua',R.env()),graph.state,clientPorts),'duplicate client refused')
graph.register(g.client.Events);graph.register(client.Events)
for _,d in ipairs(client.Subscriptions)do client.WorldState.onChange(d.key,d.handler)end
g.server.World.Initialize();g.client.World.Initialize()
server.Service.start();g.fixture.advance(0);r.advance(0)
assert(client.WorldState.get('vinewood').text=='FORGE'and r.entities[101],'initial JSON reaches actual world renderer')
local function rpc(name,...)return r.library.callback.await(name,10000,...)end
wire.playerSource=1
local ok,err=rpc(config.Vinewood.Callbacks.getSettings);assert(not ok and err=='no_permission')
ok,err=rpc(config.Vinewood.Callbacks.saveSettings,{text='NO'});assert(not ok and err=='no_permission')
wire.playerSource=2
ok,err=rpc(config.Vinewood.Callbacks.getSettings);assert(ok and err.text=='FORGE')
local context=graph.context.api
context.RegisterContext({id='forge_core_main',title='Root',options={}})
g.menus.Menu.openServerSettingsMenu()
context.HandleSelect('forge_core_server_settings',9)
assert(context.GetOpenContextMenu()=='forge_core_vinewood','parent34 routes actual menu37')
r.library.menus.InputDialog=function(_,fields)
    assert(#fields==3 and fields[3].type=='color'and fields[2].max==8)
    return{'true','NOVA BASE','#00AAFF'}
end
g.fixture.now=g.fixture.now+1
context.HandleSelect('forge_core_vinewood',1)
g.fixture.advance(0);r.advance(1100)
local value=assert(client.WorldState.get('vinewood'))
assert(value.text=='NOVA BAS'and value.color=='#00AAFF','normalization -> PR JSON -> actual delta -> same client world')
assert(fixture.m.files[config.Vinewood.Storage.file],'JSON is virtual only')
local live=0;for _ in pairs(r.entities)do live=live+1 end;assert(live==7,'spaces preserve placement without a letter entity')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_server_settings')
context.HandleBack();assert(context.GetOpenContextMenu()=='forge_core_main')
local record=g.server.State.getRecord('vinewood')
fixture.m.onWrite=function()return false end
ok,err=rpc(config.Vinewood.Callbacks.saveSettings,{text='FAIL'});assert(not ok and err=='save_failed')
H.same(g.server.State.getRecord('vinewood'),record,'failed persistence does not publish')
fixture.m.onWrite=nil
local snapshot=wire.client.api.request('forge-core:cache:snapshot',nil,nil,10000)
assert(snapshot.states.vinewood and not snapshot.ready,'remaining world producers not claimed ready')
assert(not client.WorldState.refresh(),'partial world does not announce global hydration')
assert(next(wire.client.api.getPending())==nil and next(wire.server.api.getPending())==nil,'no pending Vinewood RPC')
assert(graph.state.PlayerData.citizenid=='PATIENT'and base.PlayerCore.Lookup.GetPlayer(1).PlayerData.citizenid=='PATIENT')
-- Native command selection parity is separate; here the descriptor executes the actual menu.
client.Commands[1].handler();assert(context.GetOpenContextMenu()=='forge_core_vinewood')
local unchanged=#r.trace
r.fire('onResourceStop',nil,'pr_bridge');assert(#r.trace==unchanged,'unrelated stop ignored by renderer')
r.fire('onResourceStop',nil,'forge-core')
assert(next(r.entities)==nil and client.WorldState.get('vinewood')==nil,'own stop cleans known letters and public world')
assert(graph.state.PlayerData.citizenid=='PATIENT','world never replaces canonical PlayerData')
print('PASS Vinewood composition: canonical Player/Job/Security/World35/Session31/Menu34, actual PR RPC/context/cache/recovery/math; permission refusals, edit/color/parent/save/delta/failure/partial hydration/stop; no real UI/assets/JSON/entities/boot')
