local C=dofile('tests/kernel_configuration_harness.lua');local H,P=C.H,C.P
local cases=0
for _,state in ipairs({'started','starting','stopped','missing'})do
    for _,action in ipairs({'temporary','permanent','timed','lock','unlock'})do
        local a,b=C.new(),C.new();a.keys.states.pr_carkeys=state;b.keys.states.pr_carkeys=state
        a.keys.states.qbx_vehiclekeys='started';b.keys.states.qbx_vehiclekeys='started';local original=a.original()
        local function run(config)
            if action=='lock'or action=='unlock'then return config.setVehicleLock(101,action)end
            return config.giveVehicleKeys(2,' TEST ',101,action,90)
        end
        local expected,actual=table.pack(run(original)),table.pack(run(b.config))
        H.same(P.snapshot(actual),P.snapshot(expected),'config06 installed returns')
        H.same(b.trace,a.trace,'config06 installed port order');H.same(b.keys.calls,a.keys.calls,'config06 installed raw arguments')
        cases=cases+1
    end
end
assert(cases==20)
local r=C.new();assert(#r.trace==0 and #r.keys.calls==0,'configuration construction and Open inert')
r.keys.modes.CreateTempKeyItem=table.pack(nil);r.keys.modes.GiveTempKey=table.pack(false)
assert(r.config.giveVehicleKeys(2,'TEST',101)==true,'installed fallback reports pcall success despite logical false')
r.keys.modes.GiveTempKey='error';assert(r.config.giveVehicleKeys(2,'TEST',101)==false)
r.keys.modes={};assert(r.config.giveVehicleKeys(2,nil,101)=='TEMP')
local last=r.keys.calls[#r.keys.calls];assert(last.name=='CreateTempKeyItem'and last.args[2]=='NATIVE','plate fallback trims native plate')
local value=r.config.player.identifierTypes.AccountNumber.valueFunction();assert(value:match('^US0%dQBX'),'legacy account identifier format preserved')
local wallet=r.config.player.identifierTypes.WalletId.valueFunction();assert(wallet:match('^QB%-'),'legacy wallet identifier format preserved')
r.keys.states.pr_carkeys='stopped';r.keys.states.qbx_vehiclekeys='started';r.config.setVehicleLock(101,'lock')
assert(r.qbxCalls[#r.qbxCalls].args[2]=='lock','alternate lock keeps textual argument')
r.keys.states.qbx_vehiclekeys='missing';assert(table.pack(r.config.giveVehicleKeys(2,'NONE',101)).n==0,'missing providers give zero tuples')
r.config.setVehicleLock(101,'unlock');assert(r.trace[#r.trace].kind=='native-lock'and r.trace[#r.trace].args[2]==1)
local absent=C.new();absent.ports.qbxVehiclekeys={};absent.mount();assert(absent.api.Open(),'absent alternate resource not probed at construction/Open')
absent.keys.states.pr_carkeys='stopped';absent.keys.states.qbx_vehiclekeys='started'
local cfg=H.load('kernel/config/server.lua',H.environment())(absent.api.Ports)
assert(not pcall(cfg.giveVehicleKeys,2,'TEST',101),'selected missing alternate export is not silent success')
print('PASS lot66 config ports:20 installed config comparisons,PR priority/starting/errors/tuples,logical false-success fallback,optional alternate/text lock/native fallback,legacy IDs;no real providers')
