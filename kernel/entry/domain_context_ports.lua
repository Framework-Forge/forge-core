-- Bind one domain config before constructors capture it;borrow PR persistence only on server.
local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
local function branch(root,path)local o=root;for _,k in ipairs(path)do o[k]=copy(o[k]);o=o[k]end;return o end
local api={OperationalReady=false}
function api.Server(input,configuration,persistence)
    assert(configuration.Config and persistence.IsCurrent(),'local config/PR persistence required')
    local config=configuration.Config;local root=copy(input)
    local life=branch(root,{'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);local w=life.worker;w.graph=copy(w.graph);local g=w.graph
    g.config=config;g.central=copy(g.central);local c=g.central
    for _,entry in ipairs({{'catalog','config','Job'},{'finance','vipConfig','Vip'},{'inventory','config','Inventory'},{'weapons','config','Weapons'}})do
        local name,key,domain=table.unpack(entry);c[name]=copy(c[name]);c[name][key]=assert(config[domain])
    end
    c.transport=copy(c.transport);c.transport.config=config
    local views={};local function view(old)
        if not views[old]then local v=copy(old);for name,fn in pairs(persistence.Library)do v[name]=fn end;views[old]=v end
        return views[old]
    end
    for name,part in pairs(c)do if type(part)=='table'and part.library then local p=copy(part);p.library=view(part.library);c[name]=p end end
    g.domains=copy(g.domains);for name,part in pairs(g.domains)do local p=copy(part)
        if p.library then p.library=view(p.library)end
        if name=='Staff'then p.adminAce,p.notifyPosition=config.AdminAce,config.NotifyPos end
        g.domains[name]=p
    end
    g.helpers=copy(g.helpers);g.helpers.library=view(g.helpers.library)
    w.bootstrap=copy(w.bootstrap);w.bootstrap.library=view(w.bootstrap.library)
    life.callbacks=copy(life.callbacks);life.callbacks.securityLibrary=view(life.callbacks.securityLibrary)
    return root
end
function api.Client(input,configuration)
    local config=assert(configuration.Config);local root=copy(input)
    local media=branch(root,{'runtimeContext','deliveryContext','configurationContext','mediaContext'})
    media.worker=copy(media.worker);local w=media.worker;w.central=copy(w.central)
    w.central.config=copy(w.central.config);w.central.config.Inventory=assert(config.Inventory)
    w.domains=copy(w.domains);w.domains.config=config
    return root
end
return api
