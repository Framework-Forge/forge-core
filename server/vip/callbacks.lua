local function public(active)
    if not active then return {tier='standard',label='Standard',expiresAt=0,expiresAtFormatted='Sem VIP',slots=0,weight=0,xpMultiplier=1.0,salary={enabled=false,account='bank',amount=0}} end
    return {tier=active.tier,label=active.config.label or active.tier,color=active.config.color,expiresAt=active.expiresAt,expiresAtFormatted=os.date('%d/%m/%Y %H:%M',active.expiresAt),slots=active.config.slots,weight=active.config.weight,xpMultiplier=active.config.xpMultiplier,salary=active.config.salary}
end
ForgeCore.Callbacks.register(PR.Vip.Callbacks.get,function(source,target)return true,public(ForgeCore.VipService.get(tonumber(target) or source))end)
ForgeCore.Callbacks.register(PR.Vip.Callbacks.getTiers,function(source)return true,ForgeCore.VipService.getTiers()end)
ForgeCore.Callbacks.register(PR.Vip.Callbacks.saveTier,function(source,data)return ForgeCore.VipService.upsertTier(source,data)end)
ForgeCore.Callbacks.register(PR.Vip.Callbacks.deleteTier,function(source,id)return ForgeCore.VipService.deleteTier(source,id)end)
ForgeCore.Callbacks.register(PR.Vip.Callbacks.grant,function(source,target,tier,days)return ForgeCore.VipService.grant(source,target,tier,days)end)
ForgeCore.Callbacks.register(PR.Vip.Callbacks.revoke,function(source,target)return ForgeCore.VipService.revoke(source,target)end)