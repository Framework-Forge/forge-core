-- Attach to the same canonical player, job, VIP and callback services, without activation.
local createConfig=require 'kernel.config.forge_skills'
local createRegistry=require 'kernel.server.skill.registry'
local createStorage=require 'kernel.server.skill.storage'
local createService=require 'kernel.server.skill.service'
local createCallbacks=require 'kernel.server.skill.callbacks'
local createCommands=require 'kernel.server.skill.commands'
return function(base,ports)
    local pc,catalog,groups=assert(base.PlayerCore),assert(base.JobCatalog),assert(base.Groups)
    local deps,transport=assert(catalog.Dependencies),assert(catalog.Transport)
    assert(pc.Groups==groups and catalog.Groups==groups,'canonical Groups required')
    assert(base.Callbacks==transport.Security,'canonical Security required')
    assert(base.SkillCore==nil and deps.SkillService==nil,'skills already attached')
    assert(catalog.Service and deps.VipService==assert(catalog.Finance).Vip,'canonical services required')
    assert(type(ports.isReady)=='function','explicit internal readiness required')
    assert(type(ports.integrations)=='table'and type(ports.integrations.invoke)=='function','explicit PR integration contract required')
    local config=ports.config or createConfig()
    local registry=createRegistry(config)
    local storage=createStorage({config=config,library=ports.library})
    local services=setmetatable({JobService=catalog.Service},{__index=function(_,key)return deps[key]end})
    local boundary=createService({config=config,registry=registry,storage=storage,services=services,
        library=ports.library,json=ports.json,progression=ports.progression,translate=ports.translate,
        adminAce=ports.adminAce,notifyPosition=ports.notifyPosition,native=ports.native,
        integrations=ports.integrations,kernel={GetPlayer=assert(pc.Lookup.GetPlayer),isReady=ports.isReady}})
    local api={Base=base,PlayerCore=pc,Groups=groups,Config=config,Registry=registry,Storage=storage,
        Service=boundary.Service,Boundary=boundary,Security=transport.Security,
        Callbacks=createCallbacks({config=config,service=boundary.Service}),
        Commands=createCommands({config=config,service=boundary.Service,library=ports.library,translate=ports.translate}).Commands}
    deps.SkillService,base.SkillCore=api.Service,api
    return api
end

