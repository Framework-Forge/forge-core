local R=dofile('tests/kernel_callback_registration_harness.lua');local H=R.H
local r=R.new();local w=r.transport;local before=r.snapshot();local s,c=r.prepare()
H.same(r.snapshot(),before,'callback constructors do not run services/RPC/IO')
assert(s.Count==201 and c.Count==13,'196 protected, four Character ox, one World native; thirteen client')
assert(not s.Install()and s.State=='prepared-inactive','transport opening is explicitly required')
local protected,ox=0,0
for _,d in ipairs(s.Describe())do if d.protected then protected=protected+1;assert(d.protocol=='native')end;if d.protocol=='ox'then ox=ox+1;assert(d.owner=='Character')end end
assert(protected==196 and ox==4,'server protocols and Security/raw separation')
assert(next(r.serverGraph.Security.registrations)==nil,'Security metadata absent before install')
r.install()
local admins,players=0,0
for _,d in ipairs(s.Describe())do if d.protected then
 local cfg=r.serverGraph.Security.registrations[d.name];assert(cfg,'protected callback omitted')
 if cfg.access=='admin'then admins=admins+1 else players=players+1 end
end end
assert(admins==131 and players==65,'all196 installed through actual Security48')
w.playerSource=1
local denied=0
for _,d in ipairs(s.Describe())do
 if d.protected and r.serverGraph.Security.registrations[d.name].access=='admin'then
  local ok,why=w.client.api.native.await(d.name,10000)
  assert(ok==false and why=='no_permission','admin callback lost Security: '..d.name);denied=denied+1
 end
end
assert(denied==131,'all administrative callbacks denied before their body')
-- Actual fixture ACE permission controls the unchanged Security/JobService implementation.
local f=r.server.central
w.playerSource=1
local ok,reason=r.rpc('Job','saveGroup',{});assert(ok==false and reason=='no_permission','administrative write denied over installed native wire')
w.playerSource=2
local accepted,payload=r.rpc('Objects','getAll');assert(accepted and type(payload)=='table','player query reaches actual local service')
w.playerSource=1
for _=1,15 do assert(r.rpc('Objects','getAll'),'player callback accepted within real Security rate window')end
local limited,limitReason=r.rpc('Objects','getAll');assert(limited==false and limitReason=='rate_limited','real Security rate limit preserved')
w.playerSource=2
local raw=w.client.api.ox.await('qbx_core:server:getCharacters',false)
assert(type(raw)=='table','Character raw request delivered over installed ox wire')
local world=w.client.api.native.await('forge-core:cache:snapshot',10000)
assert(type(world)=='table','World raw snapshot delivered without Security wrapping')
local security=r.serverGraph.Security
local name=r.config.Objects.Callbacks.getAll
-- Ports captured by the unchanged Security constructor remain explicit test functions.
local previous=w.playerSource;w.playerSource=0
local called=false;local key=w.client.api.native.trigger(name,function()called=true end)
assert(not called and w.client.api.native.getPending()[key],'transport refuses source0 before Security');w.client.api.native.cancel(key);w.playerSource=previous
local captured=w.server.find(name);local metadata=security.registrations[name]
local original=r.serverGraph.Parts.Stores;r.serverGraph.Parts.Stores={}
local stale=w.client.api.native.await(name,10000);assert(stale==nil,'canonical replacement blocks already installed callback')
r.serverGraph.Parts.Stores=original
assert(s.Dispose(),'explicit server callback cleanup')
assert(next(security.registrations)==nil,'only owned Security metadata removed')
for _,d in ipairs(s.Describe())do assert(w.server.find(d.protocol=='ox'and'__ox_cb_'..d.name or d.name)==nil,'owned wire listener leaked')end
assert(w.server.registry.exists('qbx_core:server:getCharacters')==false,'owned Character claim removed')
assert(w.server.active()>0,'transport base listeners are not claimed as full R07 cleanup')
assert(not s.Install(),'disposed server callbacks never reactivated')
-- Dedicated delivery must be supplied before construction. No fallback to unowned legacy facade.
local t=R.T.new();t.clientGraph=t.mount();local graph=t.server.mount();local wire=R.wire();wire.Initialize()
wire.server.owners.securityLibrary=t.server.central.library
local installed,error=pcall(R.H.load('kernel/server/callback_registration.lua',R.env()),graph,wire.server.owners)
assert(not installed and error:find('owned delivery'),'wrong pre-construction Security delivery fails before any registration')
assert(next(graph.Security.registrations)==nil and next(t.server.central.handlers)==nil,'wrong delivery has no unowned installation side effects')
print('PASS server callback registration:201 real descriptors,196 Security wrappers/131admin/65player, Character ox/World native, canonical refusal and cleanup; no real SQL/FiveM')
