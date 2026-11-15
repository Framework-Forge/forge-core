local P=dofile('tests/kernel_physical_delivery_harness.lua');local H=P.H;local T={P=P,H=H}
function T.new(side,enabled)
    local r=P.new(side,enabled);r.bindingReady=true
    if side=='client'then r.qbGateway=H.load('kernel/compat/qbx/qb_gateway.lua',H.environment())('client',{Enabled=false},{},r.origin,{
        generation='client108',isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.bindingReady end,getInvokingResource=function()return r.invoker end})end
    local env=H.environment({require=function(name)assert(name=='kernel.shared.public_registration');return H.load('kernel/shared/public_registration.lua',H.environment())end})
    r.bindingFactory=H.load('kernel/compat/qbx/gateway_binding.lua',env)
    r.bindingPorts={side=side,public=r.api.Transport.Public,isCurrent=function()return r.api.IsCurrent()end,isReady=function()return r.bindingReady end}
    r.binding=r.bindingFactory(r.gateway,r.qbGateway,r.bindingPorts)
    local proxy=r.physicalEnv.exports['forge-core']
    for _,d in ipairs(r.binding.Describe())do proxy[d.name]=function(_,...)return assert(r.surface.exports[d.name])(...)end end
    local finish=r.finish
    function r.finish()r.binding.Close();return finish()end
    return r
end
return T
