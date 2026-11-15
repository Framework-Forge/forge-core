local V=dofile('tests/kernel_legacy_harness.lua');local H,P=V.H,V.P;local T={V=V,H=H,P=P}
function T.new(side)
    local v=V.new(true,side);local r={legacy=v,current=true,side=side or'client'}
    v.trace={};local libPorts={};for k,value in pairs(v.ports)do libPorts[k]=value end
    local env=T.V.T.env();local cache={}
    env.require=function(name)
        assert(name=='kernel.modules.lib'or name=='kernel.modules.utils'or name=='kernel.shared.locale')
        if not cache[name]then cache[name]=H.load(name:gsub('%.','/')..'.lua',env)end;return cache[name]
    end
    r.target={qbx={foreign=true},string=H.copy(string),math=H.copy(math)}
    r.ports={environment=r.target,isServer=r.side=='server',isCurrent=function()return r.current end,
        lib=libPorts,utils=v.bindings,locale={warn=function(...)v.record('locale-warn',...)end}}
    r.factory=H.load('kernel/imports/legacy_registry.lua',env)
    function r.mount()r.api=r.factory(r.ports);return r.api end
    return r
end
return T
