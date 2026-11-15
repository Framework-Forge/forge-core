-- Inactive installed NPC configuration; mutates only the explicit local config.
return function(PR,translate)
    PR=PR or {};PR.Npcs=PR.Npcs or{}

PR.Npcs.AnimationPresets = {
    { value = 'none', label = translate('menu.animations.none') },
    { value = 'manual', label = translate('menu.animations.manual') },
    { value = 'stand_guard', label = translate('menu.animations.stand_guard'), scenario = 'WORLD_HUMAN_GUARD_STAND' },
    { value = 'stand_impatient', label = translate('menu.animations.stand_impatient'), scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { value = 'clipboard', label = translate('menu.animations.clipboard'), scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { value = 'security', label = translate('menu.animations.security'), scenario = 'WORLD_HUMAN_SECURITY_SHINE_TORCH' },
    { value = 'smoke', label = translate('menu.animations.smoke'), scenario = 'WORLD_HUMAN_SMOKING' },
    { value = 'coffee', label = translate('menu.animations.coffee'), scenario = 'WORLD_HUMAN_AA_COFFEE' },
    { value = 'phone', label = translate('menu.animations.phone'), scenario = 'WORLD_HUMAN_STAND_MOBILE' },
    { value = 'lean', label = translate('menu.animations.lean'), scenario = 'WORLD_HUMAN_LEANING' },
    { value = 'cheer', label = translate('menu.animations.cheer'), scenario = 'WORLD_HUMAN_CHEERING' },
    { value = 'welding', label = translate('menu.animations.welding'), scenario = 'WORLD_HUMAN_WELDING' },
    { value = 'cop_idle', label = translate('menu.animations.cop_idle'), animDict = 'amb@world_human_cop_idles@male@idle_b', animName = 'idle_e' },
    { value = 'arms_crossed', label = translate('menu.animations.arms_crossed'), animDict = 'amb@world_human_hang_out_street@female_arms_crossed@idle_a', animName = 'idle_a' },
}
    return PR.Npcs
end
