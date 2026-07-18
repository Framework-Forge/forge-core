PR = PR or {}
PR.Billboards = PR.Billboards or {}

PR.Billboards.Storage = {
    file = 'data/billboards.json',
}

PR.Billboards.Defaults = {
    enabled = true,
    renderDistance = 120.0,
    editDistance = 10.0,
    width = 1920,
    height = 1080,
    url = 'https://i.imgur.com/5ZQZ5Qp.jpeg',
}

PR.Billboards.Callbacks = {
    getAll = 'forge-core:server:billboards:getAll',
    createGroup = 'forge-core:server:billboards:createGroup',
    renameGroup = 'forge-core:server:billboards:renameGroup',
    deleteGroup = 'forge-core:server:billboards:deleteGroup',
    createBillboard = 'forge-core:server:billboards:createBillboard',
    updateBillboard = 'forge-core:server:billboards:updateBillboard',
    deleteBillboard = 'forge-core:server:billboards:deleteBillboard',
}
