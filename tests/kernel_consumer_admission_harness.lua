local B=dofile('tests/kernel_activation_barrier_harness.lua');local H=B.H;local T={B=B,H=H,path='../pr_bridge/bridge/frameworks/forge/consumer_admission_factory.lua'}
function T.new()
    local r=B.new();r.nativeAPI.Close();r.consumerInstance='consumer124-v1';r.nativeCaller=r.boundResource
    r.admissionPorts={generation='barrier119',side='server',consumers={r.boundResource},isCurrent=function()return r.api.IsCurrent()end,
        getInvokingResource=function()return r.nativeCaller end,invalidate=function()r.policy.Close()end,
        describe=function(name)
            assert(name==r.boundResource);local d={protocol='forge-pr-consumer/1',resource=name,side='server',instance=r.consumerInstance,current=r.api.IsCurrent(),
                phase=r.bindings.Progress().phase,proxyReady=r.proxy and r.proxy.Progress().phase=='prepared'or false}
            if r.describeHook then r.describeHook(d)end;return d
        end}
    r.admission=H.load(T.path,H.environment())(r.policy,r.admissionPorts)
    local imports={['kernel.shared.public_registration']='kernel/shared/public_registration.lua',['kernel.server.framework_backend']='kernel/server/framework_backend.lua',
        ['kernel.compat.qbx.export_catalog']='kernel/compat/qbx/export_catalog.lua'}
    local env=H.environment({require=function(name)return H.load(assert(imports[name]),H.environment())end})
    r.nativeAPI=H.load('kernel/compat/qbx/pr_native_api.lua',env)(r.graph,'server',r.origin,{generation='barrier119',
        isCurrent=function()return r.api.IsCurrent()end,isReady=r.policy.CanServe,getInvokingResource=r.admissionPorts.getInvokingResource,
        isConsumerAllowed=r.admission.IsAllowed,getCoreObject=r.boundAPI.getCoreObject,public=r.api.Transport.Public})
    r.control=H.load('kernel/entry/consumer_admission_binding.lua',env)(r.admission,{side='server',isCurrent=function()return r.api.IsCurrent()end,public=r.api.Transport.Public})
    function r.prepareAdmission()assert(r.bindings.Prepare());assert(r.admission.ObservePrepared());r.publish();assert(r.control.Install())end
    function r.commitAdmission()
        r.makeProxy();assert(r.proxy.Prepare());assert(r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'attaching'))
        r.bindingPorts.api=r.proxy.API;assert(r.bindings.Attach())
        assert(r.surface.exports.ForgePrConsumerState('barrier119',r.consumerInstance,'committed'));assert(r.policy.Advance(5))
    end
    local finish=r.finish;function r.finish()r.control.Close();r.admission.Close();return finish()end
    return r
end
return T
