local P=dofile('tests/kernel_consumer_ports_harness.lua');local H=P.H;local T={P=P,H=H}
function T.new(side)
    local r=P.new(side);r.metadata={};r.metadataCounts={};r.identityCurrent=true;r.shimState='started'
    for key,value in P.G.P.read('fxmanifest.lua'):gmatch("([%w_]+)%s+'([^']*)'")do r.metadata[key]=value;r.metadataCounts[key]=1 end
    r.identityPorts={isCurrent=function()return r.identityCurrent end,
        getResourceState=function(name)if r.stateHook then r.stateHook(name)end;return name=='forge-core'and r.forgeState or r.shimState end,
        getNumResourceMetadata=function(resource,key)assert(resource=='qbx_core');return r.metadataCounts[key]or 0 end,
        getResourceMetadata=function(resource,key,index)assert(resource=='qbx_core'and index==0)
            if r.metadataHook then return r.metadataHook(key,r.metadata[key])end;return r.metadata[key]end}
    r.identityFactory=H.load('../pr_bridge/bridge/compat/forge/compat_identity_factory.lua',H.environment())
    r.identity=r.identityFactory(r.identityPorts)
    function r.identifiedConsumer()
        local c=r.consumerPorts();c.providerReadyHook=function()c.providerReady=r.identity.Probe()~=nil end;return c
    end
    local versionEnv=H.environment({pr_lib={},GetResourceMetadata=r.identityPorts.getResourceMetadata,
        GetInvokingResource=function()return'ox_inventory'end,GetCurrentResourceName=function()return'consumer110'end})
    r.installedVersion=H.load('../pr_bridge/bridge/github/server.lua',versionEnv)
    local finish=r.finish
    function r.finish()r.identity.Close();return finish()end
    return r
end
return T
