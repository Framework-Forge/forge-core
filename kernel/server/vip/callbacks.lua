return function(ports)
    local PR,service,os=assert(ports.config),assert(ports.service),assert(ports.clock)
    local callbacks={}
    local function describeCallback(name,handler)callbacks[#callbacks+1]={name=name,handler=handler,options={access='admin'}}end
local function public(active)
    if not active then return {tier='standard',label='Standard',expiresAt=0,expiresAtFormatted='Sem VIP',slots=0,weight=0,xpMultiplier=1.0,salary={enabled=false,account='bank',amount=0}} end
    return {tier=active.tier,label=active.config.label or active.tier,color=active.config.color,expiresAt=active.expiresAt,expiresAtFormatted=os.date('%d/%m/%Y %H:%M',active.expiresAt),slots=active.config.slots,weight=active.config.weight,xpMultiplier=active.config.xpMultiplier,salary=active.config.salary}
end
describeCallback(PR.Vip.Callbacks.get,function(source,target)return true,public(service.get(tonumber(target) or source))end)
describeCallback(PR.Vip.Callbacks.getTiers,function(source)return true,service.getTiers()end)
describeCallback(PR.Vip.Callbacks.saveTier,function(source,data)return service.upsertTier(source,data)end)
describeCallback(PR.Vip.Callbacks.deleteTier,function(source,id)return service.deleteTier(source,id)end)
describeCallback(PR.Vip.Callbacks.grant,function(source,target,tier,days)return service.grant(source,target,tier,days)end)
describeCallback(PR.Vip.Callbacks.revoke,function(source,target)return service.revoke(source,target)end)
    return callbacks
end
