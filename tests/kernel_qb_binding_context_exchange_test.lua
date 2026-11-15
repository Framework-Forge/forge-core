local T=dofile('tests/kernel_qb_binding_context_harness.lua');local H=T.H
local client,server=T.client(),T.server()
client.prepareBinding();server.prepareBinding();assert(client.binding.Install());assert(server.binding.Install())
local cb,sb=client.lookup('GetCoreObject')(),server.lookup('GetCoreObject')()
client.qbPorts.native.TriggerServerEvent=function(name,...)
    local previous=server.source;server.source=2
    local result=table.pack(pcall(server.emit,name,...));server.source=previous
    if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
end
server.qbPorts.native.TriggerClientEvent=function(name,src,...)
    assert(src==2,'only fixture player2 is routed');return client.emit(name,...)
end
local fromServer,fromClient
sb.Functions.CreateCallback('server95',function(src,reply,...)assert(src==2);reply('server',nil,...)end)
cb.Functions.TriggerCallback('server95',function(...)fromServer=table.pack(...)end,'request',nil,7)
H.same(fromServer,table.pack('server',nil,'request',nil,7));assert(cb.ServerCallbacks.server95==nil)
cb.Functions.CreateClientCallback('client95',function(reply,...)reply(false,nil,...)end)
sb.Functions.TriggerClientCallback('client95',2,function(...)fromClient=table.pack(...)end,'query')
H.same(fromClient,table.pack(false,nil,'query'));assert(sb.ClientCallbacks.client95==nil)
assert(client.binding.Progress().events.pending==0 and server.binding.Progress().events.pending==0)
local clientRoot,serverPlayers=client.root,server.graph.PlayerCore.State.Players
assert(client.binding.Close()and server.binding.Close())
assert(client.nativeCore.IsCurrent()and server.nativeCore.IsCurrent())
assert(client.root==clientRoot and server.graph.PlayerCore.State.Players==serverPlayers)
client.shutdownAll();server.shutdownAll()
assert(client.binding.Progress().complete and server.binding.Progress().complete)
print('PASS lot95 two actual graphs client75-server74 through registered QB lookups/events,both callback directions/nil tuples/cleanup/source,same authorities and independent core lifecycle;all wire/SQL/providers virtual')
