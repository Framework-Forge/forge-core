local H=dofile('tests/kernel_harness.lua');local factory=H.load('kernel/entry/resource_stop_ports.lua',H.environment())
for _,side in ipairs({'client','server'})do
    local trace,registered={},{};local original={GetCurrentResourceName=function()return'forge-core'end,
        AddEventHandler=function(name,fn)registered[name]=fn;return 44,nil,'token'end}
    local input={registration={native=original,available={}},context={},sentinel={}}
    local p=factory(input,side,function(resource)trace[#trace+1]='pre:'..resource;return true end)
    assert(p.Bootstrap~=input and p.Bootstrap.context==input.context and p.Bootstrap.sentinel==input.sentinel)
    assert(p.Bootstrap.registration~=input.registration and input.registration.native==original)
    local name=side=='client'and'onClientResourceStop'or'onResourceStop'
    local out=table.pack(p.Bootstrap.registration.native.AddEventHandler(name,function(resource,a,b)
        trace[#trace+1]='body:'..resource;return nil,a,b,false
    end))
    assert(out.n==3 and out[1]==44 and out[2]==nil and out[3]=='token')
    out=table.pack(registered[name]('forge-core',nil,'end'))
    assert(trace[1]=='pre:forge-core'and trace[2]=='body:forge-core')
    assert(out.n==4 and out[1]==nil and out[2]==nil and out[3]=='end'and out[4]==false)
    assert(p.Progress().signals==1 and p.Progress().failures==0 and p.Progress().pending==0)
    registered[name]('other');assert(#trace==3 and p.Progress().signals==1)
end
print('PASS157 stop prelude before existing body on both sides;arguments/nils/returns preserved;no added listener')
