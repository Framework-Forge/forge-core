local G=dofile('tests/kernel_gateway_binding_harness.lua');local H=G.H;local T={G=G,H=H}
function T.new(side)
    local r=G.new(side);assert(r.binding.Install());r.loadPhysical();r.providers={}
    r.portsFactory=H.load('../pr_bridge/bridge/compat/qbx/import_ports_factory.lua',H.environment())
    function r.consumerPorts()
        local c=r.consumer();rawset(c.target,'ForgeQbxConsumerPorts',nil);local old=c.consumerPorts;local v=c.legacy
        c.providerReady=true;c.providerCurrent=true;local core={}
        for _,name in ipairs(side=='server'and{'GetVehiclesByHash','SetEntityBucket','EnablePersistence'}or{'GetPlayerData'})do core[name]=r.catalog.Resolve(name)end
        c.providerPorts={side=side,environment=c.target,resource='consumer109',isCurrent=function()return c.providerCurrent end,
            isReady=function()if c.providerReadyHook then c.providerReadyHook()end;return c.providerReady end,
            library=v.library,native=v.native,cache=v.cache,audio=v.audio,inventory={Search=old.utils.searchInventory},core=core,
            compile=c.deliveryPorts.compile,moduleEnvironment=c.deliveryPorts.moduleEnvironment,events=old.events,
            random=old.utils.random,strsplit=old.utils.strsplit,discordLink=old.utils.discordLink}
        c.provider=r.portsFactory(c.providerPorts);r.providers[#r.providers+1]=c.provider
        return c
    end
    local finish=r.finish
    function r.finish()for _,c in ipairs(r.consumers)do c.stopPhysical()end;for _,p in ipairs(r.providers)do p.Close()end;return finish()end
    return r
end
return T
