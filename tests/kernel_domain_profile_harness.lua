local G=dofile('tests/kernel_native_graph_harness.lua');local C=dofile('tests/kernel_native_domains_config_harness.lua');local T={G=G,C=C,H=G.H}
function T.new(side)
    -- The IO127 fixture originally encoded only {value=n}. Full domain state needs a JSON test codec.
    local function encode(v,seen)
        if type(v)=='nil'then return'null'end
        if type(v)=='boolean'or type(v)=='number'then return tostring(v)end
        if type(v)=='string'then return'"'..v:gsub('[%z\1-\31\\"]',function(ch)return('\\u%04x'):format(ch:byte())end)..'"'end
        assert(type(v)=='table','JSON test codec value');seen=seen or{};assert(not seen[v],'JSON cycle');seen[v]=true
        local count=0;for _ in pairs(v)do count=count+1 end;local out={};local array=count>0 and count==#v
        if array then for i=1,count do out[i]=encode(v[i],seen)end
        else for k,x in pairs(v)do out[#out+1]=encode(tostring(k),seen)..':'..encode(x,seen)end;table.sort(out)end
        seen[v]=nil;return(array and'['or'{')..table.concat(out,',')..(array and']'or'}')
    end
    local r
    if side=='server'then
        local S=G.M.T.S;local prior=S.io;S.io=function(...)local io=prior(...);io.codec.encode=encode;return io end
        local ok,value=pcall(G.server);S.io=prior;assert(ok,value);r=value
    else r=G.client()end
    local c=C.new();r.configFixture144=c
    r.profilePorts.domainConfigurationPorts={vec3=c.vec3,getConvar=c.getConvar,locale=c.locale}
    r.factory144=T.H.load('kernel/entry/domain_native_profile.lua',T.H.environment())
    function r.allocate144()
        r.profile=r.factory144(side=='server'and r.fixture.base or r.fixture.state,r.profilePorts)
        r.api=side=='server'and r.profile or r.profile.Bootstrap;return r.profile
    end
    return r
end
return T
