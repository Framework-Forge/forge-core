-- Core owns its graph;the PR consumer init must never run in this resource.
fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author 'Forge Devs - PierreMoraes'
description 'Forge Core;single authoritative kernel'
version '1.1.4'
forge_kernel_bootstrap 'owned/1'
shared_script 'kernel/entry/core_bootstrap_entry.lua'
server_script 'kernel/entry/boot_runtime_entry.lua'
client_script 'kernel/entry/boot_runtime_entry.lua'
dependency 'pr_bridge'
files {
 'kernel/**/*.lua',
 'kernel/**/*.json',
 'data/*.json',
 'locale/*.lua',
}

server_script 'server/version.lua'
