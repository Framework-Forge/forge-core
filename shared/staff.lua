PR = PR or {}
PR.Staff = PR.Staff or {}

PR.Staff.Metadata = 'staff'

PR.Staff.Callbacks = {
    openMenu = 'forge-core:client:staff:open',
    getAll = 'forge-core:server:staff:getAll',
    getPlayers = 'forge-core:server:staff:getPlayers',
    catalog = 'forge-core:server:staff:catalog',
    add = 'forge-core:server:staff:add',
    remove = 'forge-core:server:staff:remove',
}

PR.Staff.Commands = {
    menu = 'forgestaff',
    direct = 'staff',
}

PR.Staff.Roles = {
    { value = 'admin', label = 'Admin' },
    { value = 'mod', label = 'Moderador' },
    { value = 'staff', label = 'Staff' },
    { value = 'support', label = 'Suporte' },
}

PR.Staff.PermissionFiles = {
    'server.cfg',
    'permissions.cfg',
}

PR.Staff.PermissionCatalog = {
    { value = 'group.admin', label = 'Admin', description = 'Grupo administrativo completo.', kind = 'principal' },
    { value = 'group.mod', label = 'Moderador', description = 'Grupo de moderação.', kind = 'principal' },
    { value = 'group.staff', label = 'Staff', description = 'Grupo base da equipe.', kind = 'principal' },
    { value = 'group.support', label = 'Suporte', description = 'Grupo de suporte.', kind = 'principal' },
    { value = PR.AdminAce or 'forge-core.admin', label = 'Forge Core Admin', description = 'Acesso administrativo ao Forge Core.', kind = 'ace' },
    { value = 'pr_bridge.developer', label = 'PR Bridge Developer', description = 'Ferramentas e testes de desenvolvimento do PR Bridge.', kind = 'ace' },
    { value = 'forgechat.stickers.admin', label = 'Forge Chat Stickers Admin', description = 'Administração dos stickers do Forge Chat.', kind = 'ace' },
}

PR.Staff.HiddenPermissions = {
    command = true,
    ['command.add_ace'] = true,
    ['command.remove_ace'] = true,
    ['command.add_principal'] = true,
    ['command.remove_principal'] = true,
}

PR.Staff.RolePermissions = {
    admin = {
        principals = {
            'group.admin',
            'group.mod',
            'group.staff',
            'admin',
            'mod',
            'staff',
        },
        aces = {
            PR.AdminAce or 'forge-core.admin',
            'admin',
            'mod',
            'staff',
            'group.admin',
            'group.mod',
            'group.staff',
            'qbadmin.join',
            'command.tp',
            'command.tpm',
            'command.togglepvp',
            'command.addpermission',
            'command.removepermission',
            'command.openserver',
            'command.closeserver',
            'command.optin',
            'command.car',
            'command.dv',
            'command.givemoney',
            'command.setmoney',
            'command.setjob',
            'command.changejob',
            'command.addjob',
            'command.removejob',
            'command.setgang',
            'command.logout',
            'command.deletechar',
            'command.admin',
            'command.noclip',
            'command.names',
            'command.blips',
            'command.admincar',
            'command.setmodel',
            'command.vec2',
            'command.vec3',
            'command.vec4',
            'command.heading',
        },
        optin = true,
    },
    mod = {
        principals = {
            'group.mod',
            'group.staff',
            'mod',
            'staff',
        },
        aces = {
            'mod',
            'staff',
            'group.mod',
            'group.staff',
            'command.admin',
            'command.noclip',
            'command.names',
            'command.blips',
        },
        optin = true,
    },
    staff = {
        principals = {
            'group.staff',
            'staff',
        },
        aces = {
            'staff',
            'group.staff',
            'support',
            'group.support',
        },
        optin = false,
    },
    support = {
        principals = {
            'group.support',
            'support',
        },
        aces = {
            'support',
            'group.support',
        },
        optin = false,
    },
}
