-- Local Player/Job/Finance/Access authority. Consumer descriptors only; no public installation.
local createPlayerConfig=require 'kernel.config.forge_player'
local createManagementConfig=require 'kernel.config.forge_player_management'
local createManagement=require 'kernel.server.player_management'
local createInfo=require 'kernel.server.player_info'
local createCallbacks=require 'kernel.server.player_management_callbacks'
local createPlugins=require 'kernel.server.plugins'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local deps,security=assert(catalog.Dependencies),assert(base.Callbacks)
    assert(pc.Groups==groups and catalog.Groups==groups and catalog.Transport.Security==security,'canonical Player/Job/Security required')
    assert(deps.VipService==assert(catalog.Finance).Vip,'canonical VIP required')
    assert(deps.MultiJobService==assert(base.MultiJobCore).Service and deps.PrisonService==base.MultiJobCore.PrisonService,'canonical multi-job/prison required')
    assert(deps.WhitelistService==assert(base.AccessCore).Whitelist.Service and deps.AfkService==base.AccessCore.Afk.Service,'canonical access required')
    assert(deps.PasswordService==assert(base.ServerSettingsCore).Password.Service,'canonical password required')
    assert(deps.DensityService==assert(base.WorldCore).Density.Service and deps.WeatherService==base.WorldCore.Weather.Service,'canonical world required')
    for _,pair in ipairs({{'StaffCore','StaffService'},{'SkillCore','SkillService'},{'WeaponCore','WeaponService'}})do
        assert(base[pair[1]]==nil or base[pair[1]].Service==deps[pair[2]],'canonical optional service required: '..pair[2])
    end
    assert(base.PlayerAdminCore==nil and deps.PlayerManagementService==nil,'player administration already attached')
    local config={};for k,v in pairs(assert(ports.config))do config[k]=v end
    config.Player=config.Player or createPlayerConfig();config.PlayerManagement=config.PlayerManagement or createManagementConfig()
    assert(type(config.Staff)=='table'and config.Staff.Metadata,'shared Staff config required')
    assert(base.StaffCore==nil or config.Staff==base.StaffCore.Config,'canonical Staff config required')
    assert(config.Weather==base.WorldCore.Config.Weather,'canonical Weather config required')
    local services=setmetatable({JobService=assert(catalog.Service),JobRegistry=assert(catalog.Registry)},{__index=function(_,k)return deps[k]end})
    local bindings={config=config,services=services,lookup=assert(pc.Lookup),native=ports.native,clock=ports.clock,
        translate=ports.translate,managementIntegration=ports.managementIntegration,print=ports.print}
    local management=createManagement(bindings);services.PlayerManagementService=management
    local api={Base=base,PlayerCore=pc,Lookup=pc.Lookup,Security=security,Services=services,Config=config,Service=management,Callbacks={}}
    api.Plugins=createPlugins(bindings)
    for _,list in ipairs({createInfo(bindings),createCallbacks(bindings),api.Plugins.Callbacks})do
        for _,entry in ipairs(list)do api.Callbacks[#api.Callbacks+1]=entry end
    end
    api.Events=api.Plugins.Events
    deps.PlayerManagementService,base.PlayerAdminCore=management,api
    return api
end
