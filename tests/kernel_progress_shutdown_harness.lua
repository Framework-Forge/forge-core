local P=dofile('tests/kernel_progress_harness.lua');local T={H=P.H,P=P}
function T.new()
    local r=P.new(false);r.factory=T.H.load('../pr_bridge/bridge/delivery/forge_client_progress_shutdown.lua',T.H.environment())
    r.api=r.factory(r.ports);assert(r.api.Open());r.lib=r.api.Library
    return r
end
function T.count(r,kind,value)
    local n=0;for _,entry in ipairs(r.trace)do if entry[1]==kind and(value==nil or entry[2]==value)then n=n+1 end end;return n
end
return T
