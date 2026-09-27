PR = PR or {}
PR.Vehicles = PR.Vehicles or {}

PR.Vehicles.Storage = 'data/vehicles.json'

PR.Vehicles.Callbacks = {
    getAll = 'forge-core:server:vehicles:getAll',
    save = 'forge-core:server:vehicles:save',
    remove = 'forge-core:server:vehicles:remove',
    setActive = 'forge-core:server:vehicles:setActive',
    reload = 'forge-core:server:vehicles:reload',
    importDefinition = 'forge-core:server:vehicles:importDefinition',
    spawn = 'forge-core:server:vehicles:spawn',
    adminCar = 'forge-core:server:vehicles:adminCar',
    adminCarCurrent = 'forge-core:server:vehicles:adminCarCurrent',
    getCurrentVehicle = 'forge-core:client:vehicles:getCurrentVehicle',
}

PR.Vehicles.Types = {
    'automobile',
    'bike',
    'boat',
    'heli',
    'plane',
    'submarine',
    'trailer',
    'train',
}

PR.Vehicles.Categories = {
    'compacts', 'sedans', 'suvs', 'coupes', 'muscle', 'sportsclassics',
    'sports', 'super', 'motorcycles', 'offroad', 'industrial', 'utility',
    'vans', 'cycles', 'boats', 'helicopters', 'planes', 'service',
    'emergency', 'military', 'commercial', 'openwheel',
}

PR.Vehicles.Classes = {
    'S+',
    'S',
    'A',
    'B',
    'C',
    'D',
    'E',
}

PR.Vehicles.Defaults = {
    name = '',
    brand = '',
    model = '',
    price = 0,
    category = 'compacts',
    class = 'C',
    type = 'automobile',
    hash = '',
    stock = 0,
    store = nil,
    active = true,
}