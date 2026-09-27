PR = PR or {}

PR.CharacterSlots = {
    item = 'new_slot',
    previewStorage = 'data/character_previews.json',
    previewModel = 'mp_m_freemode_01',
    previewAnimations = {
        { id = 'stand', label = 'Em pé' },
        { id = 'arms_crossed', label = 'Braços cruzados', animDict = 'amb@world_human_hang_out_street@female_arms_crossed@idle_a', animName = 'idle_a', flag = 1 },
        { id = 'sit_sofa', label = 'Sentado no sofá', scenario = 'PROP_HUMAN_SEAT_ARMCHAIR' },
        { id = 'sit_chair', label = 'Sentado em cadeira', scenario = 'PROP_HUMAN_SEAT_CHAIR' },
        { id = 'sit_bench', label = 'Sentado em banco', scenario = 'PROP_HUMAN_SEAT_BENCH' },
        { id = 'sit_ledge', label = 'Sentado em degrau', scenario = 'WORLD_HUMAN_SEAT_LEDGE' },
        { id = 'sit_wall', label = 'Sentado junto à parede', scenario = 'WORLD_HUMAN_SEAT_WALL' },
        { id = 'lean_wall', label = 'Encostado na parede', scenario = 'WORLD_HUMAN_LEANING' },
        { id = 'stand_impatient', label = 'Em pé, impaciente', scenario = 'WORLD_HUMAN_STAND_IMPATIENT' },
        { id = 'phone', label = 'Usando o celular', scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        { id = 'coffee', label = 'Tomando café', scenario = 'WORLD_HUMAN_AA_COFFEE' },
        { id = 'clipboard', label = 'Com prancheta', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        { id = 'guard', label = 'Postura de segurança', scenario = 'WORLD_HUMAN_GUARD_STAND' },
    },
    playerCallbacks = {
        getCharacters = 'forge-core:server:characterSlots:ownCharacters',
        logout = 'forge-core:server:characterSlots:logout',
    },
    callbacks = {
        getSettings = 'forge-core:server:characterSlots:getSettings',
        saveSettings = 'forge-core:server:characterSlots:saveSettings',
        getPlayer = 'forge-core:server:characterSlots:getPlayer',
        setPlayerSlot = 'forge-core:server:characterSlots:setPlayerSlot',
        savePreview = 'forge-core:server:characterSlots:savePreview',
        deletePreview = 'forge-core:server:characterSlots:deletePreview',
    },
}
