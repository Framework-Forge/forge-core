return function(ports)
    local PR={Farms={}}
    local vec3,translate=assert(ports.vec3),assert(ports.translate)

PR.Farms.Storage = {
    file = 'data/farms.json',
}

PR.Farms.Defaults = {
    enabled = true,
    targetDistance = 2.0,
    targetSize = vec3(0.8, 0.8, 1.4),
    collectTime = 7000,
}

PR.Farms.AnimationPresets = {
    { value = 'pickup', label = translate('menu.farms.anim_pickup'), animDict = 'pickup_object', animName = 'pickup_low' },
    { value = 'garden', label = translate('menu.farms.anim_garden'), animDict = 'amb@world_human_gardener_plant@male@base', animName = 'base' },
    { value = 'weld', label = translate('menu.farms.anim_weld'), scenario = 'WORLD_HUMAN_WELDING' },
    { value = 'hammer', label = translate('menu.farms.anim_hammer'), scenario = 'WORLD_HUMAN_HAMMERING' },
    { value = 'clipboard', label = translate('menu.farms.anim_clipboard'), scenario = 'WORLD_HUMAN_CLIPBOARD' },
    { value = 'mechanic', label = translate('menu.farms.anim_mechanic'), scenario = 'WORLD_HUMAN_VEHICLE_MECHANIC' },
    { value = 'construction', label = translate('menu.farms.anim_construction'), scenario = 'WORLD_HUMAN_CONST_DRILL' },
    { value = 'electrician', label = translate('menu.farms.anim_electrician'), animDict = 'amb@world_human_welding@male@base', animName = 'base' },
    { value = 'janitor', label = translate('menu.farms.anim_janitor'), scenario = 'WORLD_HUMAN_JANITOR' },
    { value = 'maid', label = translate('menu.farms.anim_maid'), scenario = 'WORLD_HUMAN_MAID_CLEAN' },
    { value = 'binoculars', label = translate('menu.farms.anim_inspect'), scenario = 'WORLD_HUMAN_BINOCULARS' },
    { value = 'drilling', label = translate('menu.farms.anim_drilling'), animDict = 'anim@heists@fleeca_bank@drilling', animName = 'drill_straight_idle' },
    { value = 'mechanic2', label = translate('menu.farms.anim_mechanic_low'), animDict = 'mini@repair', animName = 'fixing_a_ped' },
    { value = 'manual', label = translate('menu.animations.manual') },
}

PR.Farms.Callbacks = {
    getAll = 'forge-core:server:farms:getAll',
    saveSettings = 'forge-core:server:farms:saveSettings',
    createFarm = 'forge-core:server:farms:createFarm',
    updateFarm = 'forge-core:server:farms:updateFarm',
    deleteFarm = 'forge-core:server:farms:deleteFarm',
    startRoute = 'forge-core:server:farms:startRoute',
    finishRoute = 'forge-core:server:farms:finishRoute',
    collect = 'forge-core:server:farms:collect',
    getGroups = 'forge-core:server:farms:getGroups',
    getItems = 'forge-core:server:farms:getItems',
    getVehicles = 'forge-core:server:farms:getVehicles',
}
    return PR.Farms
end
