local M=dofile('tests/kernel_native_entry140_harness.lua');local C=dofile('tests/kernel_native_domains_config_harness.lua');local T={M=M,H=M.H}
function T.client()
    local r=M.client();local c=C.new();r.env140.vec3=c.vec3;r.options140.domainLocale=c.locale
    r.factory145=assert(load(M.read('145/pr_bridge/bridge/forge_native_profile.lua'),'@@entry145','t',r.env140))()
    function r.allocate145()r.entry145=r.factory145(r.raw,r.options140);return r.entry145 end
    function r.finish145()if r.entry145 then r.entry145.Stop();r.clock.advance(120000);r.entry145.Poll()end;r.finish140()end
    return r
end
return T
