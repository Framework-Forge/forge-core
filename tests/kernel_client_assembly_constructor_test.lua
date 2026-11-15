local A=dofile('tests/kernel_client_assembly_harness.lua');local H,n=A.H,0
local function check(value,label)n=n+1;assert(value,label)end
local r=A.new();local before=r.snapshot();local data,shared=r.state.PlayerData,r.state.Shared
local api=r.mount();H.same(r.snapshot(),before,'no constructor effects or passive bridge hydration')
H.same(api.Order,{'Membership','Helpers','Producers','Legacy','Runtime','Character','Consumption'},'seven real local stages')
check(api.State=='prepared-inactive'and api.Unbound and api.IsCanonical(),'inert canonical composition')
check(r.state.PlayerData==data and r.state.Shared==shared,'does not replace PlayerData/Shared')
check(api.Shared==shared and api.Core==r.state,'one canonical client holder')
check(api.Config.Client==r.config and api.Config.Inventory==r.consumption.config,'local config identities')
check(api.Parts.Producers==r.state.ProducerCore and r.state.Session==api.Parts.Producers.Session.Session,'one session producer')
check(api.Parts.Runtime.State==r.state and api.Parts.Legacy.State==r.state,'same runtime/functions state')
check(api.Parts.Character.Renderer==r.state.CharacterRenderer.Renderer,'flow owns its only renderer')
check(api.Parts.Legacy.Functions.GetPlayerData()==data,'no consumer PlayerData copy')
check(api.Parts.Consumption==r.state.Consumption,'same effects/status consumer')
check(#api.Callbacks==5,'five raw callbacks without registration')
local seen={};for _,d in ipairs(api.Callbacks)do check(type(d.handler)=='function'and not seen[d.name]and type(d.owner)=='string','callback owner/name contract');seen[d.name]=true end
for _,name in ipairs({'helpers','producers','legacy','runtime','character','consumption'})do
 check(r.ports[name].native==nil and r.ports[name].core==nil,'caller native/core untouched '..name)
end
check(r.ports.legacy.helpers==nil and r.ports.runtime.helpers==nil and r.ports.character.functions==nil,'caller owned bindings untouched')
check(not pcall(r.mount),'duplicate assembly refused')
for _,key in ipairs({'Shared','ProducerCore','LegacyCore','RuntimeCore','CharacterCore','Consumption','BridgeCache','Session','CharacterRenderer'})do
 local old=r.state[key];r.state[key]={};check(not api.IsCanonical(),'replaced identity refused '..key);r.state[key]=old
end
check(api.IsCanonical(),'same identities restored')
local external=A.new(true);local old=external.snapshot();local ex=external.mount();H.same(external.snapshot(),old,'external mode constructor inert')
check(not ex.Parts.Character.Flow.Enabled and external.state.CharacterRenderer==nil,'external mode no scene authority')
check(ex.IsCanonical()and #ex.Parts.Character.Flow.Threads==0 and #ex.Parts.Character.Flow.Events==0,'disabled flow has no startup descriptors')
local a=A.new()
for _,name in ipairs({'membership','helpers','producers','legacy','runtime','character','consumption'})do
 local value=a.ports[name];a.ports[name]=nil;check(not pcall(a.mount),'missing ports '..name);check(a.state.ClientAssembly==nil,'preflight before mutation');a.ports[name]=value
end
for _,name in ipairs({'helpers','legacy','runtime','character','consumption'})do
 a.ports[name].native={};check(not pcall(a.mount),'foreign native '..name);check(a.state.ClientAssembly==nil,'foreign native preflight');a.ports[name].native=nil
end
for _,entry in ipairs({{'producers','statusConfig'},{'runtime','config'},{'character','config'},{'consumption','config'},{'legacy','helpers'},{'runtime','helpers'},{'character','functions'}})do
 local p,key=a.ports[entry[1]],entry[2];p[key]={};check(not pcall(a.mount),'foreign core dependency '..entry[1]..'.'..key);check(a.state.ClientAssembly==nil,'owned port preflight');p[key]=nil
end
a.ports.helpers.isServer=true;check(not pcall(a.mount),'server helper cannot enter client graph');a.ports.helpers.isServer=nil
for _,key in ipairs({'Client','Inventory'})do local cfg=a.ports.config[key];a.ports.config[key]=nil;check(not pcall(a.mount),'complete local configs '..key);a.ports.config[key]=cfg end
local broken=A.new();broken.native.AttachEntityToEntity=nil
check(not pcall(broken.mount),'late consumption constructor failure refused')
check(broken.state.ClientAssembly.State=='construction-failed'and broken.state.CharacterCore~=nil,'partial assembly signaled without rollback claim')
check(not pcall(broken.mount),'failed holder not reusable')
print('PASS lot49 construction: '..n..' checks; seven real stages/five raw descriptors, one PlayerData/Shared/session/cache/renderer; external mode, identities, inert preflight/failure/caller ports')
