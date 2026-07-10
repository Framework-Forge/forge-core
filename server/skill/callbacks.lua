ForgeCore = ForgeCore or {}

pr_lib.callback.register(PR.Skills.Callbacks.getAll, function(source)
    return ForgeCore.SkillService.getPayload(), ForgeCore.SkillService.canManage(source)
end)

pr_lib.callback.register(PR.Skills.Callbacks.saveSkill, function(source, skill)
    return ForgeCore.SkillService.upsertSkill(source, skill)
end)

pr_lib.callback.register(PR.Skills.Callbacks.deleteSkill, function(source, name)
    return ForgeCore.SkillService.deleteSkill(source, name)
end)

pr_lib.callback.register(PR.Skills.Callbacks.saveReputation, function(source, reputation)
    return ForgeCore.SkillService.upsertReputation(source, reputation)
end)

pr_lib.callback.register(PR.Skills.Callbacks.deleteReputation, function(source, name)
    return ForgeCore.SkillService.deleteReputation(source, name)
end)

pr_lib.callback.register(PR.Skills.Callbacks.fetchPlayer, function(source)
    return ForgeCore.SkillService.fetchPlayer(source)
end)

pr_lib.callback.register(PR.Skills.Callbacks.addXp, function(source, name, amount)
    return ForgeCore.SkillService.addXp(source, name, amount)
end)
