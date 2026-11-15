local H=dofile('tests/kernel_harness.lua');local env=H.environment();local calls={};local current=true
local n={TriggerClientEvent=function(...)calls[#calls+1]=table.pack(...)end,GetPlayerIdentifierByType=function()return'license:test'end,
 GetCurrentResourceName=function()return'forge-core'end,GetInvokingResource=function()return nil end,
 GetResourceMetadata=function()return'1.2.3'end,GetResourceState=function()return'started'end}
local json={};for _,k in ipairs({'loadJsonRecovery','saveJsonRecovery','saveJsonBatch','withJsonLock','jsonDraft','wrapJsonMutations','recordJsonIncident'})do json[k]=function(...)return k,...end end
local f={Side='server',IsCurrent=function()return current end,Public={settings={}},RegistrationInput={prCommand=function()return'command'end},
 Seed={Library={Cache={}},IO={JSON=json}}}
local db={};for _,name in ipairs({'query','execute','insert','update','scalar','single','transaction','prepare','rawExecute'})do db[name]={await=function(...)return name,...end}end
local services={Public={inventory={},banking={},vehicle_key={}}}
local s={IsCurrent=f.IsCurrent,Utilities={Library={math=math,table=table,string=string,print={}}},Dependencies={CheckDependency=function()return true end},
 Logging={DeliveryPorts={httpRequest=function()error('no HTTP during construction')end}}}
local p={foundation=f,support=s,values={IsCurrent=f.IsCurrent,Database={IsReady=function()return true end,Database=db}},services=services,native=n,
 environment=env,config={Debug=false},rpc={Ox={await=function(...)return ...end},Owners={native={CaptureRegister=function()return'lease'end}}},
 loadPR=function(path,target)return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end}
local a=H.load('../pr_bridge/bridge/delivery/forge_server_library_ports.lua',env)(p);local lib=a.Library
assert(#calls==0 and lib.framework==nil and lib.registerHook==nil)
assert(lib.notify.NotifyPlayer(3,{description='test'})and calls[1][1]=='bridge:notify'and calls[1][2]==3)
assert(lib.utils.trim(' x ')=='x'and lib.identifiers.getPrimaryLicense(3)=='license:test')
assert(lib.database.query('SELECT')=='query'and lib.db==lib.database and lib.inventory==services.Public.inventory)
assert(lib.withJsonLock('x')=='withJsonLock'and lib.callback.register()=='lease')
assert(not pcall(lib.load,'@qbx_core/server/player'));assert(a.Close()and not pcall(lib.notify.NotifyPlayer,3,{}))
print('PASS202 installed native notify/debug/utils/identifiers,owned RPC/DB/JSON/raw projections;no bootstrap effects and unlisted imports refused')
