local T=dofile('tests/kernel_domain_context_harness.lua');local s=T.server()
local path={'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle','worker','graph'}
local function at(v)for _,k in ipairs(path)do v=v[k]end;return v end
local a,b=at(s.original143),at(s.profilePorts.bootstrap.context)
assert(a~=b and a.config~=b.config and a.central.inventory.config~=b.central.inventory.config)
assert(a.domains.Stores.inventoryIntegration==b.domains.Stores.inventoryIntegration)
assert(b.central.catalog.library.loadJsonRecovery==s.domainPersistence.Library.loadJsonRecovery)
assert(b.helpers.library.loadJsonRecovery==s.domainPersistence.Library.loadJsonRecovery and a.helpers.library~=b.helpers.library)
s.domainPersistence.Close();assert(not pcall(T.bind.Server,s.original143,s.domainConfig,s.domainPersistence));s.finishProfile()
local c=T.client();local old=c.original143.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
local new=c.profilePorts.bootstrap.context.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
assert(old~=new and old.domains~=new.domains and old.central.config~=new.central.config)
assert(old.domains.domains==new.domains.domains and old.central.character==new.central.character)
c.finishProfile();print('PASS143 five identity/isolation/persistence refusal checks;input/external integration ports preserved')
