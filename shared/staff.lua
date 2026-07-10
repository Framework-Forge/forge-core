PR = PR or {}
PR.Staff = PR.Staff or {}

PR.Staff.Metadata = 'staff'

PR.Staff.Callbacks = {
    openMenu = 'forge-core:client:staff:open',
    getAll = 'forge-core:server:staff:getAll',
    getPlayers = 'forge-core:server:staff:getPlayers',
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
            'command',
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
