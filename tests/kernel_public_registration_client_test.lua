local T=dofile('tests/kernel_public_registration_harness.lua');local H=T.H
local r=T.new();r.preparePublic();r.prepare();r.install();r.installPublic()
local c=r.publicClient;local e=r.surfaces.client;local exports=e.exports;local graph=r.clientGraph
assert(exports.GetPlayerData()==r.state.PlayerData,'same client PlayerData reference')
assert(exports.GetJobs()==graph.Central.Parts.Legacy.Groups.GetJobs(),'same client Groups')
assert(exports.GetStatusSnapshot~=nil and exports.AddStatuses~=nil,'status APIs exported')
local session=exports.GetCachedState('session');assert(type(session)=='table','client Session dispatcher preserved')
local state=graph.Parts.World.WorldState
assert(state.apply({generation=10,states={stores={generation=10,revision=1,data={value=21}}}}),'virtual public World delivery')
local world=exports.GetCachedState('stores');assert(world.data.value==21,'client World dispatcher preserved')
world.data.value=81;assert(exports.GetCachedState('stores').data.value==21,'client public record is copy')
assert(exports.GetCachedState('session:2')==nil,'client never invents server session domain')
assert(c.Counts.callbacks==0,'client callbacks remain owned by lot52')
local reachable=T.callbacks(graph);for _,d in ipairs(r.clientRegistration.Describe())do assert(reachable[d.name]);reachable[d.name]=nil end
assert(next(reachable)==nil,'all reachable client callbacks remain covered')
local before=exports.GetPlayerData();local old=graph.Parts.Skills;graph.Parts.Skills={}
assert(exports.GetPlayerData()==nil,'client domain replacement blocks public wrapper');graph.Parts.Skills=old
assert(exports.GetPlayerData()==before,'same canonical client restored')
assert(c.Dispose(),'client surface revoked')
c.State='installed';assert(exports.GetPlayerData()==nil,'public State cannot resurrect revoked client surface')
assert(e.commands[next(e.commands)]~=nil,'native command records remain explicitly outside physical cleanup contract')
assert(r.publicServer.Dispose());assert(r.serverRegistration.Dispose());assert(r.clientRegistration.Dispose())
print('PASS public client: '..c.Counts.exports..' exports/'..c.Counts.commands..' commands; same PlayerData/Groups/Status/Session/World and revocation; virtual public registry only')
