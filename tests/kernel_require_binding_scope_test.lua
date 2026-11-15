local T=dofile('tests/kernel_require_binding_harness.lua')
local r=T.new();r.files['qbx_core/modules/lib.lua']='return false';assert(r.require('@qbx_core/modules/lib')==false)
r.mount();local before=#r.env.package.searchers
assert(not pcall(r.api.Install)and #r.env.package.searchers==before,'false cached alias refuses binding')
r.api.Close()
local failed=T.new(nil,'ox');failed.mount();failed.api.Install();failed.getHook=function()error('getter failed',0)end
assert(not pcall(failed.require,'@qbx_core.modules.playerdata'))
assert(failed.env.package.loaded['@qbx_core.modules.playerdata']=='__loading','whole loader retains failure sentinel')
local ok,problem=pcall(failed.require,'@qbx_core.modules.playerdata');assert(not ok and problem:find('circular%-dependency'))
failed.api.Close();assert(failed.api.Progress().cachedAliases['@qbx_core.modules.playerdata']=='__loading')
local pr=T.new();pr.mount();pr.api.Install();pr.getHook=function()error('PR getter failed',0)end
assert(not pcall(pr.require,'@qbx_core.modules.playerdata')and pr.env.package.loaded['@qbx_core.modules.playerdata']==nil,'PR clears failed module cache')
local retry,reason=pcall(pr.require,'@qbx_core.modules.playerdata')
assert(not retry and reason:find('not_repeatable',1,true)and pr.gets==1,'PR retry does not replay partial context77');pr.api.Close()
local late=T.new();late.mount();late.api.Install();late.getHook=function()coroutine.yield()end
local co=coroutine.create(function()assert(not pcall(late.require,'@qbx_core.modules.playerdata'))end)
assert(coroutine.resume(co));assert(late.api.Progress().pending>0);late.api.Close();assert(not late.api.Progress().complete)
assert(coroutine.resume(co));assert(late.api.Progress().complete and late.target.QBX==late.oldQBX and late.active()==0)
local replaced=T.new();replaced.mount();replaced.api.Install();local held=replaced.env.package.searchers[1]('@qbx_core.modules.lib')
local foreign={function()end};replaced.env.package.searchers=foreign
assert(not pcall(held));replaced.api.Close();assert(replaced.env.package.searchers==foreign)
print('PASS lot78 scope:prior false cache refusal,no mutation on refusal,installed sticky loading error/circular path,pending require drain,retained shell refusal and foreign searcher table;no live require changes')
