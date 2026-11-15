local B=dofile('tests/kernel_pr_native_api_harness.lua');local H=B.H;local T={H=H,B=B}
T.path='kernel/entry/activation_barrier.lua'
function T.new()
    local r=B.new('server');r.nativeAPI.Close();r.policyCurrent=true;r.facts={oxHooks=false,catalogs=false,banking=false,keys=false,decisions=false,environment=false}
    r.makeBindings();local probes={allocations=function()return r.bindings.Allocation~=nil end,rawProviders=function()return r.services~=nil end,
        bootstrap=function()return r.api.IsCurrent()end,nativeAPI=function()return r.nativeAPI.Progress().phase=='installed'end,
        compatIdentity=function()return r.identity.Probe()~=nil end,consumerBindings=function()return r.bindings.Allocation.IsAttached()end}
    for name in pairs(r.facts)do probes[name]=function()if r.probeHook then r.probeHook(name)end;return r.facts[name]end end
    r.policyPorts={generation='barrier119',isCurrent=function()return r.policyCurrent and r.api.IsCurrent()end,
        consumers={r.boundResource},probes=probes,ownedCleanup={{name='nativeAPI',close=function()return r.nativeAPI.Close()end},
            {name='bindings',close=function()return r.bindings.Close()end}}}
    r.policy=H.load(T.path,H.environment())(r.policyPorts)
    local imports={['kernel.shared.public_registration']='kernel/shared/public_registration.lua',['kernel.server.framework_backend']='kernel/server/framework_backend.lua',
        ['kernel.compat.qbx.export_catalog']='kernel/compat/qbx/export_catalog.lua'}
    r.nativeAPI=H.load('kernel/compat/qbx/pr_native_api.lua',H.environment({require=function(n)return H.load(assert(imports[n]),H.environment())end}))(r.graph,'server',r.origin,{
        generation='barrier119',isCurrent=function()return r.api.IsCurrent()end,isReady=r.policy.CanServe,getInvokingResource=function()return r.nativeCaller end,
        isConsumerAllowed=r.policy.IsConsumerAllowed,getCoreObject=r.boundAPI.getCoreObject,public=r.api.Transport.Public})
    function r.allocate()assert(r.bindings.Prepare());assert(r.policy.ConsumerState('barrier119',r.boundResource,'prepared'))end
    function r.publish()for i=1,3 do assert(r.policy.Advance(i))end;assert(r.nativeAPI.Install());assert(r.policy.Advance(4))end
    function r.attach()
        r.makeProxy();assert(r.proxy.Prepare());assert(not pcall(r.proxy.API.framework.GetPlayer,2))
        assert(r.policy.ConsumerState('barrier119',r.boundResource,'attaching'))
        r.bindingPorts.api=r.proxy.API;assert(r.bindings.Attach())
        assert(r.policy.ConsumerState('barrier119',r.boundResource,'committed'));assert(r.policy.Advance(5))
    end
    local finish=r.finish;function r.finish()r.policy.Close();return finish()end
    return r
end
return T
