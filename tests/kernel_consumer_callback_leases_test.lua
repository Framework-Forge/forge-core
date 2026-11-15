local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/consumer_callback_leases.lua',H.environment())
for _,mode in ipairs({'plain','secure'})do
 local listeners={};local removed=0;local count=0;local e={AddEventHandler=function(name,fn)count=count+1;listeners[count]=fn;return count end,
 RemoveEventHandler=function(id)listeners[id]=nil;removed=removed+1 end,RegisterNetEvent=function()end}
 local env=setmetatable({},{__index=e})
 local public={register=function(name,fn)if mode=='plain'then env.RegisterNetEvent(name);env.AddEventHandler(name,fn)else env.RegisterNetEvent(name,fn)end end}
 local owner=create({environment=env,side='server',running=coroutine.running,isCurrent=function()return true end,getCallback=function()return public end})
 local lease=owner.Reserve('a');assert(owner.Bind(lease,function()return mode end));assert(listeners[1]()==mode)
 assert(owner.Release(lease)and removed==1 and not pcall(owner.Reserve,'a'))
 assert(owner.Close()and owner.Progress().complete and env.RegisterNetEvent==e.RegisterNetEvent)
end
print('PASS275 leases retain installed callback API/wire and capture/remove only owned listener;no second callback transport')
