fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Forge Devs - PierreMoraes'
description 'Core System for dedicated qbx'
version '1.1.0'

shared_scripts {
    '@pr_bridge/init.lua',
    'shared/config.lua',
    'shared/job.lua',
    'shared/player.lua',
    'shared/afk.lua',
    'shared/password.lua',
    'shared/weather.lua',
    'shared/whitelist.lua',
    'shared/density.lua',
    'shared/weapons.lua',
    'shared/skills.lua',
    'shared/staff.lua',
}

client_scripts {
    'client/job/state.lua',
    'client/menu/menu.lua',
    'client/menu/menu_job.lua',
    'client/menu/menu_mei.lua',
    'client/menu/menu_skills.lua',
    'client/menu/menu_staff.lua',
    'client/menu/menu_server.lua',
    'client/menu/menu_weather.lua',
    'client/menu/menu_whitelist.lua',
    'client/menu/menu_density.lua',
    'client/menu/menu_weapons.lua',
    'client/menu/menu_player.lua',
    'client/menu/menu_bindings.lua',
    'client/whitelist/main.lua',
    'client/density/main.lua',
    'client/job/creator.lua',
    'client/job/main.lua',
    'client/main.lua',
}

server_scripts {
    'server/job/storage.lua',
    'server/job/registry.lua',
    'server/job/qbx_sync.lua',
    'server/job/service.lua',
    'server/job/payments.lua',
    'server/job/callbacks.lua',
    'server/job/commands.lua',
    'server/player/callbacks.lua',
    'server/weapon/storage.lua',
    'server/weapon/registry.lua',
    'server/weapon/qbx_sync.lua',
    'server/weapon/ox_sync.lua',
    'server/weapon/service.lua',
    'server/weapon/callbacks.lua',
    'server/weapon/commands.lua',
    'server/skill/storage.lua',
    'server/skill/registry.lua',
    'server/skill/service.lua',
    'server/skill/callbacks.lua',
    'server/skill/commands.lua',
    'server/staff/service.lua',
    'server/staff/callbacks.lua',
    'server/staff/commands.lua',
    'server/afk/service.lua',
    'server/afk/callbacks.lua',
    'server/password/service.lua',
    'server/password/callbacks.lua',
    'server/weather/callbacks.lua',
    'server/whitelist/service.lua',
    'server/whitelist/callbacks.lua',
    'server/density/service.lua',
    'server/density/callbacks.lua',
    'server/plugins.lua',
    'server/menu.lua',
    'server/main.lua',
}

files {
    'data/*.json',
    'locale/*.lua',
}

dependencies {
    'pr_bridge',
    'qbx_core',
    'ox_inventory',
}
