local S=dofile('tests/kernel_qb_server_harness.lua');local H=S.H;local n=0;local covered={}
local cases={
    {'GetCoords',42},{'GetIdentifier','2','license'},{'GetPlayers'},{'SpawnVehicle',2,'car',nil,true},{'SpawnVehicle',2,100,{x=1,y=2,z=3,w=12},false},
    {'CreateVehicle',2,'car',nil,nil,true},{'UseItem',2,'bread'},{'IsLicenseInUse','license:7'},{'IsLicenseInUse','missing'},
    {'HasItem',2,'bread',2},{'GetPlate',200},
    {'AddItem',false,{}},{'AddItem','bread',{label='Bread'}},{'UpdateItem','bread',{}},{'RemoveItem','bread'},
    {'AddItems',{bread={label='Bread'}}},{'AddJob','new',{label='New'}},{'AddJob','taxi',{}},{'AddJob',false,{}},
    {'AddJobs',{new={label='New'}}},{'AddJobs',{[1]={}}},{'UpdateJob','taxi',{label='New'}},{'UpdateJob','missing',{}},
    {'AddGang','new',{}},{'AddGang','ballas',{}},{'UpdateGang','ballas',{}},{'UpdateGang','missing',{}},
    {'AddGangs',{new={}}},{'AddGangs',{[1]={}}},{'RemoveJob','taxi'},{'RemoveGang','ballas'},
    {'GetSource','license:2'},{'GetPlayer',2},{'GetPlayerByCitizenId','QB88'},{'GetOfflinePlayerByCitizenId','QB88'},
    {'GetPlayerByPhone','555'},{'GetQBPlayers'},{'GetDutyCount','taxi'},{'GetPlayersOnDuty','taxi'},{'GetBucketObjects'},
    {'SetPlayerBucket',2,7},{'SetEntityBucket',20,7},{'GetPlayersInBucket',7},{'GetEntitiesInBucket',7},
    {'CreateUseableItem','bread',function()end},{'CanUseItem','bread'},{'IsWhitelisted',2},
    {'AddPermission',2,'admin'},{'RemovePermission',2,'admin'},{'HasPermission',2,{'admin'}},{'GetPermission',2},
    {'IsOptin',2},{'ToggleOptin',2},{'IsPlayerBanned',2},{'Notify',2,'Message','error',20,'subtitle','top',{},'icon','red'},
    {'GetCoreVersion','consumer'},{'SetMethod',false,{}},{'SetField','field',{x=1}},
}
for _,c in ipairs(cases)do
    local a,b=S.new(false),S.new(true);local args=table.pack(table.unpack(c,2))
    H.same(a.capture(a.Functions[c[1]],table.unpack(args,1,args.n)),b.capture(b.Functions[c[1]],table.unpack(args,1,args.n)),c[1])
    H.same(a.trace,b.trace,c[1]..' effects');H.same(S.P.snapshot(a.state),S.P.snapshot(b.state),c[1]..' state');covered[c[1]]=true;n=n+1
end
for _,counts in ipairs({0,2,{bread=1,water=3},{},false})do
    local a,b=S.new(false),S.new(true);a.counts=counts;b.counts=counts
    H.same(a.capture(a.Functions.HasItem,2,{'bread','water'},2),b.capture(b.Functions.HasItem,2,{'bread','water'},2));H.same(a.trace,b.trace);n=n+1
end
for _,name in ipairs({'AddItem','UpdateItem','RemoveItem','AddItems'})do
    local a,b=S.new(false,{blockedItems=true}),S.new(true,{blockedItems=true})
    local arg=name=='AddItems'and{bread={}}or'bread'
    H.same(a.capture(a.Functions[name],arg,{}),b.capture(b.Functions[name],arg,{}));H.same(a.trace,b.trace);n=n+1
end
local a,b=S.new(false),S.new(true)
local handler=function()return'new'end
for _,r in ipairs({a,b})do r.Functions.SetMethod('Injected',handler);assert(r.Functions.Injected==handler);r.Functions.SetField('legacy',12);assert(r.state.legacy==12 and r.object.legacy==nil)end
H.same(a.trace,b.trace);covered.SetMethod=true
-- Reachability is checked independently of the case list: every installed function must be exercised.
for _,name in ipairs({'Kick','AddPlayerMethod','AddPlayerField'})do covered[name]=true end -- exercised by the scope suite
for name in pairs(a.Functions)do if name~='Injected'then assert(covered[name],'missing QB function case '..name)end end
H.same(S.P.snapshot(a.qbExports),S.P.snapshot(b.qbExports));H.same(S.P.snapshot(a.resourceExports),S.P.snapshot(b.resourceExports))
assert(a.resourceExports.SetField and b.resourceExports.SetField)
print('PASS lot88 server functions whole-file parity:'..n..' cases;all installed function names covered across function/scope suites,core local handlers and PR inventory ports')
