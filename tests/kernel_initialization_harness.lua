-- Existing client50 construction; explicit virtual platform/cache/groups/streaming only.
local S=dofile('tests/kernel_subscription_harness.lua')
local T={S=S,H=S.H}
function T.unit()
    local r={calls={},readyCalls=0,preflights=0,ready=true}
    r.spec={owner={},isCurrent=function()return not r.replaced end,preflight=function()r.preflights=r.preflights+1 end,entries={}}
    for _,name in ipairs({'first','second','third'})do
        r.spec.entries[#r.spec.entries+1]={name=name,owner='unit',handler=function()r.calls[#r.calls+1]=name;return name=='first'and false or nil end}
    end
    r.ports={isReady=function()r.readyCalls=r.readyCalls+1;if r.readyHook then r.readyHook()end;return r.ready end}
    r.factory=T.H.load('kernel/shared/initialization_sequence.lua',T.H.environment())
    function r.prepare()r.api=r.factory(r.spec,r.ports);return r.api end
    return r
end
function T.new()
    local r=S.new();r.ready=true;r.readyCalls=0
    r.ports={isReady=function()r.readyCalls=r.readyCalls+1;return r.ready end}
    r.factory=T.H.load('kernel/client/initialization_sequence.lua',S.D.A.E.env())
    function r.prepare()r.api=r.factory(r.graph,r.ports);return r.api end
    return r
end
return T
