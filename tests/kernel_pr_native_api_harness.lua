local B=dofile('tests/kernel_native_bindings_harness.lua');local H=B.H;local T={B=B,H=H}
function T.new(side)
    local r=B.new(side,side=='server');r.nativeCaller=r.boundResource;r.callAllowed=true;r.describeAllowed=true;r.apiReady=true
    local modules={['kernel.shared.public_registration']='kernel/shared/public_registration.lua',
        ['kernel.server.framework_backend']='kernel/server/framework_backend.lua',['kernel.compat.qbx.export_catalog']='kernel/compat/qbx/export_catalog.lua'}
    local env=H.environment({require=function(name)return H.load(assert(modules[name]),H.environment())end})
    r.nativeAPI=H.load('kernel/compat/qbx/pr_native_api.lua',env)(r.graph,side,r.origin,{
        generation='native118-'..side,isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.apiReady end,
        getInvokingResource=function()return r.nativeCaller end,isConsumerAllowed=function(caller,mode)
            return caller==r.boundResource and(mode=='describe'and r.describeAllowed or mode=='call'and r.callAllowed)end,
        getCoreObject=r.boundAPI.getCoreObject,public=r.api.Transport.Public})
    local function names(t)local n={};for k in pairs(t or{})do n[#n+1]=k end;table.sort(n);return n end
    r.expected={framework=names(r.boundAPI.framework),core=names(r.boundAPI.core),inventory=names(r.boundAPI.inventory),
        native=r.boundAPI.getCoreObject and{'GetCoreObject'}or{}}
    r.nativeProxy={ForgePrDescribe=function()local d=assert(r.surface.exports.ForgePrDescribe)();if r.handshakeHook then r.handshakeHook(d)end;return d end,
        ForgePrCall=function(_,...)return assert(r.surface.exports.ForgePrCall)(...)end}
    function r.makeProxy()r.proxy=H.load('../pr_bridge/bridge/frameworks/forge/native_api_factory.lua',H.environment())({
        isCurrent=function()return r.api.IsCurrent()end,side=side,proxy=r.nativeProxy,expected=r.expected});return r.proxy end
    local finish=r.finish
    function r.finish()if r.proxy then r.proxy.Close()end;r.nativeAPI.Close();return finish()end
    return r
end
return T
