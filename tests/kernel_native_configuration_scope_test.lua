local T=dofile('tests/kernel_native_configuration_harness.lua');local count=0
local function case(side,fn)local r=T.new(side);fn(r);r.finish();count=count+1 end
case('server',function(r)r.mount();r.current=false;assert(not r.config.IsCurrent()and not pcall(r.config.Shared.vec4,1,2,3,4))end)
case('server',function(r)r.mount();local input={isCurrent=function()return false end};for k,v in pairs(r.config.Configuration)do if k~='isCurrent'then input[k]=v end end;local b=r.config.CreateConfiguration(input);assert(not b.Open())end)
case('server',function(r)r.mount();r.config.Close();assert(not pcall(r.config.CreateConfiguration,r.config.Configuration))end)
case('server',function(r)r.mount();local c=T.H.load('kernel/config/server.lua',T.H.environment())(r.boundary.Ports);r.fixture.keys.states.qbx_vehiclekeys='started';r.fixture.keys.states.pr_carkeys='stopped';assert(c.giveVehicleKeys(1,2)=='ALT')end)
case('client',function(r)r.external.pr_carkeys=nil;r.mount();r.fixture.states.pr_carkeys='started';local c=T.H.load('kernel/config/client.lua',T.H.environment())(r.boundary.Ports);assert(not pcall(c.hasKeys,'P131',2))end)
case('client',function(r)r.mount();r.fixture.qbxResult=true;r.fixture.states.qbx_vehiclekeys='started';local c=T.H.load('kernel/config/client.lua',T.H.environment())(r.boundary.Ports);assert(c.hasKeys('P131',2)==true)end)
assert(count==6);print('PASS lot131 six owner/closed/boundary/alternate/missing-custom/client-alternative cases;no generic HaveKey substitution')
