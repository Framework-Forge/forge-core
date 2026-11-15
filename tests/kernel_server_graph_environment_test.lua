local N=dofile('tests/kernel_native_foundation_harness.lua');local H=N.H;local req=N.loader()
local env=H.environment({load=load,GlobalState={},promise={new=function()return{}end},Citizen={Await=function(x)return x end}})
local current=true;local config={'qbx:max_jobs_per_player','qbx:max_gangs_per_player'};local n={IsDuplicityVersion=function()return true end,
 GetCurrentResourceName=function()return'forge-core'end,vec4=function(...)return{...}end,GetPlayerRoutingBucket=function()return 9 end,
 GetConvar=function(k,d)if k=='qbx:setjob_replaces'then return'false'end;return d end,GetConvarInt=function(_,d)return d+1 end}
local execution={Native=n,IsCurrent=function()return current end,GetSource=function()return 0 end,Bind=function(names)local r={};for _,k in ipairs(names)do r[k]=assert(n[k],k)end;return r end}
local db={driver='oxmysql',context='server',isReady=function()return true end};for _,name in ipairs({'query','execute','insert','update','scalar','single','transaction','prepare','rawExecute'})do db[name]=function(sql,p,cb)cb(true)end end
local f={Side='server',IsCurrent=function()return current end,Locale=function(x)return x end,Events={listen=function()end},
 Seed={Execution=execution,Registry={Require=req},IO={Codec={decode=function(v)return test_decode_json(v)end}}}}
local function loadPR(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end
local support={IsCurrent=function()return true end,Utilities={Clock={time=os.time,date=os.date},Random=math.random},Configuration={
 Configuration={},CreateConfiguration=function()return{Ports={getResourceState=function()return'missing'end,getVehicleNumberPlateText=function()end,
 setVehicleDoorsLocked=function()end,random=math.random,randomString=function()return'x'end,vehicleKeys={pr={},qbx={}}},Close=function()return true end}end}}
local a=req('kernel.entry.server_graph_environment')(f,support,{loadPR=loadPR,environment=env,services={Public={database=db}}})
assert(a.Settings.maxJobs==2 and a.Settings.maxGangs==2 and not a.Settings.setJobReplaces and a.Settings.setGangReplaces)
assert(a.Settings.accounts[1]=='money'and a.Counters.PlayerCount==0 and env.GlobalState.PlayerCount==nil)
a.Counters.PlayerCount=4;assert(env.GlobalState.PlayerCount==4);env.GlobalState.PlayerCount=8;assert(a.Counters.PlayerCount==8)
assert(a.Shared.defaultSpawn[1]==-540.58 and a.Server.player.status.hungerRate==4.2 and a.GetBucket(1)==9)
assert(a.Close()and not pcall(a.GetBucket,1));assert(not pcall(function()return a.Counters.PlayerCount end))
print('PASS201 installed server/shared config,legacy convars/accounts,one GlobalState counter view,PR platform/database and revocation')
