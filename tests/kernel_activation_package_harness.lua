local B=dofile('tests/kernel_pr_native_api_harness.lua');local H=B.H;local T={B=B,H=H,root='../../../../.planning/migration/staging/120/'}
function T.read(name)local f=io.open(T.root..name,'rb');if not f then return end;local s=f:read('*a');f:close();return s end
function T.new(side)
    local r=B.new(side);r.stopTokens={};local env=H.environment(r.bindingPorts.native)
    local names=assert(load(T.read('pr_bridge/bridge/runtime/forge/native_names.lua'),'@@native_names120','t',{}))()
    for _,name in ipairs(names)do if rawget(env,name)==nil then env[name]=false end end -- Side-specific absent natives,not callable substitutes.
    env.exports={['forge-core']=r.nativeProxy};env.AddEventHandler=function(name,fn)local t={name=name,fn=fn};r.stopTokens[#r.stopTokens+1]=t
        if r.listenHook then r.listenHook(t)end;return t end
    env.RemoveEventHandler=function(t)if r.refuseRemove then return false end;t.removed=true end;env._ENV=env
    r.pr.context=side;r.pr.load=function(path)
        local n=path:gsub('^@pr_bridge/',''):gsub('%.lua$','');if not n:find('/',1,true)then n=n:gsub('%.','/')end
        local text=T.read('pr_bridge/'..n..'.lua');if text then return assert(load(text,'@@package120/'..n,'t',env))()end
        return H.load('../pr_bridge/'..n..'.lua',env)
    end
    r.activation={contracts=r.bindingPorts.contracts,isCurrent=r.bindingPorts.isCurrent,isReady=r.bindingPorts.isReady,
        readDeclarations=r.bindingPorts.readDeclarations,view=r.bindingPorts.view,cacheNamespace='qbx_core',readSessionReady=r.bindingPorts.readSessionReady,
        readProviders=function()return r.bindingPorts.getServices()end}
    r.entryFactory=assert(load(T.read('pr_bridge/bridge/runtime/forge/allocation_entry.lua'),'@@allocation120','t',env))()
    function r.enter()r.entry=r.entryFactory(r.pr,r.public,{compatFramework='forge'},r.activation);return r.entry end
    local finish=r.finish;function r.finish()if r.entry then r.entry.Close()end;return finish()end
    return r
end
function T.barrier()
    local probes={};for _,key in ipairs({'allocations','rawProviders','bootstrap','nativeAPI','compatIdentity','consumerBindings','oxHooks','catalogs','banking','keys','decisions','environment'})do probes[key]=function()return true end end
    local a=H.load('kernel/entry/activation_barrier.lua',H.environment())({generation='ports120',consumers={'consumer120'},probes=probes,isCurrent=function()return true end})
    function T.open(a)
        assert(a.ConsumerState('ports120','consumer120','prepared'));for i=1,4 do assert(a.Advance(i))end
        assert(a.ConsumerState('ports120','consumer120','attaching')and a.ConsumerState('ports120','consumer120','committed'))
        assert(a.Advance(5)and a.Advance(6))
    end
    return a
end
return T
