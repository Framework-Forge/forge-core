local C=dofile('tests/kernel_qb_client_bridge_harness.lua');local S=dofile('tests/kernel_qb_bridge_harness.lua');local H=C.H
local client,server=C.new(true),S.new(true)
local cf,sf=client.object.Functions,server.object.Functions
local function wire()
    client.serverHook=function(name,...)return server.fire(name,2,...)end
    server.ports.native.TriggerClientEvent=function(name,source,...)
        server.rec('client',name,source,...);assert(source==2,'fixture routes only this player')
        if name=='QBCore:Client:TriggerCallback'or name=='QBCore:Client:TriggerClientCallback'or name=='QBCore:Client:VehicleInfo'then
            return client.fire(name,...)
        end
    end
end
wire()
sf.CreateCallback('serverEcho',function(src,cb,...)assert(src==2);cb('reply',nil,...)end)
local answer
cf.TriggerCallback('serverEcho',function(...)answer=table.pack(...)end,'request',nil,7)
H.same(answer,table.pack('reply',nil,'request',nil,7));assert(client.object.ServerCallbacks.serverEcho==nil)
cf.CreateClientCallback('clientEcho',function(cb,...)cb(false,nil,...)end)
sf.TriggerClientCallback('clientEcho',2,function(...)answer=table.pack(...)end,'query')
H.same(answer,table.pack(false,nil,'query'));assert(server.object.ClientCallbacks.clientEcho==nil)
for _,name in ipairs({'QBCore:Server:SpawnVehicle','QBCore:Server:CreateVehicle'})do
    cf.TriggerCallback(name,function(netId)answer=netId end,'car',{x=1,y=2,z=3,w=4},false)
    assert(type(answer)=='number')
end
server.fire('baseevents:enteredVehicle',2,200,-1,'car',100)
local event=client.trace[#client.trace];assert(event.kind=='event'and event.args[1]=='QBCore:Client:EnteredVehicle'and event.args[2].name==nil)
sf.CreateCallback('failing',function()error('fixture_server_error')end)
assert(not pcall(cf.TriggerCallback,'failing',function()end)and client.object.ServerCallbacks.failing~=nil)
client.api.Close();assert(not pcall(cf.TriggerCallback,'serverEcho',function()end)) -- reply ingress is closed, retained raw callback still mutates before emission
server.api.Close();assert(client.api.Progress().complete and server.api.Progress().complete)
print('PASS lot92 client92-server89 virtual exchange:both callback directions/nil tuples/name cleanup/2 vehicle callbacks/VehicleInfo mismatch/error retention/closed ingress;no real network or aliases')
