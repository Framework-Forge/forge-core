local T=dofile('tests/kernel_require_binding_harness.lua');local r=T.new();local old=r.env.package.searchers[1]
r.mount();assert(r.env.package.searchers[1]==old and r.gets==0,'78 allocation inert')
assert(r.api.Install()and r.env.package.searchers[2]==old);local count=0
for name in pairs(r.api.Describe())do assert(r.require(name)==true,name);count=count+1 end
assert(count==16 and r.nativeCalls==0 and #r.reads==0,'all remote aliases resolved before native/file QBX fallback')
assert(r.gets==1 and r.active()==2 and r.target.qbx and r.target.Locale)
local before=r.gets;assert(r.api.ExecuteManifest('@qbx_core/modules/playerdata.lua')and r.gets==before,'same canonical import across require/manifest')
r.files['consumer78/local/value.lua']='return {value=78}'
assert(r.require('local.value').value==78 and r.nativeCalls==1,'unrelated require retains installed physical resolver')
r.files['consumer78/modules/lib.lua']='return "consumer-owned"'
assert(r.require('modules.lib')=='consumer-owned','local modules.lib is never shadowed by QBX aliases')
local foreign=function()end;table.insert(r.env.package.searchers,1,foreign)
assert(r.api.Close());assert(r.env.package.searchers[1]==foreign and r.env.package.searchers[2]==old and r.active()==0)
assert(r.api.Progress().complete and r.api.Progress().cachedAliases['@qbx_core.modules.lib']==true)
assert(r.require('@qbx_core.modules.lib')==true and r.target.qbx.foreign,'installed readonly cache retained after Close;does not reexecute')
assert(not pcall(r.api.ExecuteManifest,'@qbx_core/modules/lib.lua'))
local server=T.new('server');server.mount();server.api.Install();assert(server.require('@qbx_core.modules.playerdata')and server.gets==0 and server.active()==0);server.api.Close()
print('PASS lot78 require:16 aliases,installed whole PR require engine,native/file fallback not reached for QBX,unrelated/local imports,manifest same cache,server noop,owned searcher removal and retained readonly cache;virtual only')
