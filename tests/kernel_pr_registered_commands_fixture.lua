-- Execute the installed PR client manifest using the existing provider fixture.
-- Only Cfx/render/network effects are virtual; collect commands before post-boot assertions.
return function()
 local file=assert(io.open('../pr_bridge/tests/provider_client_boot_test.lua','rb'))
 local source=file:read('*a');file:close()
 local marker="assert(env.Bridge and env.Bridge.cache and env.Bridge.cache.resource == 'pr_bridge')"
 local stop=assert(source:find(marker,1,true),'provider fixture boundary changed')
 local prefix=source:sub(1,stop-1)
 local target=setmetatable({arg={'../pr_bridge','','started','enabled','forge'}},{__index=_G})
 local result=assert(load(prefix..'\nreturn {environment=env,commands=commands,executed=executed,loadedFiles=loadedFiles}',
  '@@tests/pr-manifest-command-fixture','t',target))()
 assert(result.executed>0 and result.commands['+pr_bridge_gizmo_confirm'],'real provider gizmo did not register')
 return result
end
