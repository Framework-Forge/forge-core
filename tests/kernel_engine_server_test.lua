local T=dofile('tests/kernel_engine_ports_harness.lua');local r=T.new('server');local p=r.mount146();local before=#r.effects;local view=p.Select(r.schema)
assert(#r.effects==before);local compared=0
for name,target in pairs(r.schema)do
    if target:sub(1,1)~='$'and target~='CreateThread'and target~='SetTimeout'and target~='Wait'then
        local token={};local a=table.pack(view[name](token,nil,11));local b=table.pack(r.native[target](token,nil,11));T.H.same(a,b,name);compared=compared+1
    end
end
r.source=82;assert(view.source()==82 and view.getSource()==82);r.source=91;assert(view.source()==91)
assert(view.time()==101 and view.locale('x',nil,3)=='x');local q=view.promise();assert(q.promise)
local a,b,c=view.await({value='value'});assert(a=='value'and b==nil and c==false)
assert(view.dropPlayer==view.DropPlayer and view.emitClient==view.TriggerClientEvent)
local called=0;view.setTimeout(10,function()called=called+1 end);p.Close();r.clock.advance(10);assert(called==0)
assert(r.api.IsCurrent());r.finish146()
print('PASS146 server engine aliases:'..compared..' direct comparisons,nil/false returns,dynamic source,promise,shared aliases and queued body inert after Close')
