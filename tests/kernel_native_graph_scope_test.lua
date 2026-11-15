local T=dofile('tests/kernel_native_graph_harness.lua');local s=T.server();local old=s.original139;local path={'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle','worker','graph','central','session','player'}
local a,b=old,s.profilePorts.bootstrap.context;for _,key in ipairs(path)do a,b=a[key],b[key]end;assert(a~=b and a.db==b.db and a.platform~=b.platform)
assert(not pcall(T.bind.Server,old,{Side='client'}));s.platform.Close();s.finishProfile()
local c=T.client();local oc=c.original139.runtimeContext.deliveryContext.configurationContext.mediaContext.worker.central
local nc=c.profilePorts.bootstrap.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker.central
assert(oc.native~=nc.native and oc.library~=nc.library and oc.library.callback==nc.library.callback)
assert(oc.cache==nc.cache and #T.bind.DescribeClientNatives()==22 and nc.library.getClosestPlayer==c.utilities.Library.getClosestPlayer)
assert(not pcall(T.bind.Client,c.original139,{Side='server'},c.utilities));c.platform.Close();c.utilities.Close();c.finishProfile()
local env=T.H.environment();local tables=T.H.load('../pr_bridge/bridge/delivery/forge_native_tables.lua',env)
local inner=tables.freeze({a=1});local outer=tables.freeze({inner=inner});assert(outer.inner==inner and not pcall(function()outer.inner.a=2 end))
print('PASS lot139 six clone/DB/side/callback-cache/native-bind/nested-frozen checks;zero native/bootstrap/registration at bind')
