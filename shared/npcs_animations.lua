PR = PR or {}
PR.Npcs = PR.Npcs or {}

PR.Npcs.AnimationPresets = {
    { value = 'none', label = ForgeCore.t('menu.animations.none') },
    { value = 'manual', label = ForgeCore.t('menu.animations.manual') },
    { value = 'stand_guard', label = ForgeCore.t('menu.animations.stand_guard'), scenario = 'WORLD_HUMAN_GUARD_STAND' },
    { value = 'stand_impatient', label = ForgeCore.t('menu.animations.stand_impatient'), scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { value = 'clipboard', label = ForgeCore.t('menu.animations.clipboard'), scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { value = 'security', label = ForgeCore.t('menu.animations.security'), scenario = 'WORLD_HUMAN_SECURITY_SHINE_TORCH' },
    { value = 'smoke', label = ForgeCore.t('menu.animations.smoke'), scenario = 'WORLD_HUMAN_SMOKING' },
    { value = 'coffee', label = ForgeCore.t('menu.animations.coffee'), scenario = 'WORLD_HUMAN_AA_COFFEE' },
    { value = 'phone', label = ForgeCore.t('menu.animations.phone'), scenario = 'WORLD_HUMAN_STAND_MOBILE' },
    { value = 'lean', label = ForgeCore.t('menu.animations.lean'), scenario = 'WORLD_HUMAN_LEANING' },
    { value = 'cheer', label = ForgeCore.t('menu.animations.cheer'), scenario = 'WORLD_HUMAN_CHEERING' },
    { value = 'welding', label = ForgeCore.t('menu.animations.welding'), scenario = 'WORLD_HUMAN_WELDING' },
    { value = 'cop_idle', label = ForgeCore.t('menu.animations.cop_idle'), animDict = 'amb@world_human_cop_idles@male@idle_b', animName = 'idle_e' },
    { value = 'arms_crossed', label = ForgeCore.t('menu.animations.arms_crossed'), animDict = 'amb@world_human_hang_out_street@female_arms_crossed@idle_a', animName = 'idle_a' },
}
