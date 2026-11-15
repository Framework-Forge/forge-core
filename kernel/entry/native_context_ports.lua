-- Pure input bindings for100/101. Domain/platform ports not listed here remain caller-owned.
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
local function branch(root,path)local out=root;for _,key in ipairs(path)do out[key]=copy(out[key]);out=out[key]end;return out end
local function databaseLibrary(source,db)
    local out=copy(source)
    if source.database then out.database=db end
    if source.db then out.db=db end
    return out
end
local function dbFunctions(scope)
    local db={isReady=scope.IsReady}
    for _,name in ipairs({'query','execute','insert','update','scalar','single','transaction','prepare','rawExecute'})do
        local f=assert(scope.Database[name]);db[name]=function(...)return f(...)end
    end
    return db
end
local uiNames={RegisterContext='registerContext',ShowContext='showContext',HideContext='hideContext',GetOpenContextMenu='getOpenContextMenu',
    RegisterMenu='registerMenu',ShowMenu='showMenu',HideMenu='hideMenu',GetOpenMenu='getOpenMenu',InputDialog='inputDialog',AlertDialog='alertDialog',
    Notify='notify',ShowTextUI='showTextUI',HideTextUI='hideTextUI',IsTextUIOpen='isTextUIOpen'}
local function uiLibrary(source,ui)
    local out=copy(source);local menu=copy(source.menus or{})
    for upper,lower in pairs(uiNames)do local fn=assert(ui.Library[lower]);out[upper],out[lower]=fn,fn;menu[upper],menu[lower]=fn,fn end
    out.menus,out.menu=menu,menu
    return out
end
local api={OperationalReady=false}
function api.Server(input,configuration,database)
    assert(configuration.Shared and configuration.Configuration and configuration.CreateConfiguration,'server configuration assembly required')
    assert(database.Database and database.IsReady,'PR awaited database required')
    local root=copy(input);local config=branch(root,{'deliveryContext','mediaContext','supportContext','configurationContext'})
    config.shared,config.configuration,config.createConfiguration=configuration.Shared,configuration.Configuration,configuration.CreateConfiguration
    local startup=branch(config,{'vehicleContext','bankingContext','operationsContext','inventoryContext','startup'})
    startup.databaseReady=database.IsReady;startup.lifecycle=copy(startup.lifecycle);local life=startup.lifecycle
    life.worker=copy(life.worker);local w=life.worker;w.graph=copy(w.graph);local g=w.graph
    g.central=copy(g.central);local c=g.central
    c.session=copy(c.session);c.session.player=copy(c.session.player);c.session.player.db=database.Database
    c.slots=copy(c.slots);c.slots.db=database.Database;c.lifecycle=copy(c.lifecycle);c.lifecycle.querySchema=database.Database.query.await
    local functions=dbFunctions(database);g.domains=copy(g.domains)
    for name,part in pairs(g.domains)do if part.library then local p=copy(part);p.library=databaseLibrary(part.library,functions);g.domains[name]=p end end
    local old=assert(life.callbacks.securityLibrary);local library=databaseLibrary(old,functions)
    life.callbacks=copy(life.callbacks);life.callbacks.securityLibrary=library
    for name,part in pairs(c)do
        if part==old then c[name]=library elseif type(part)=='table'and part.library==old then local p=copy(part);p.library=library;c[name]=p end
    end
    if g.helpers.library==old then g.helpers=copy(g.helpers);g.helpers.library=library end
    w.bootstrap=copy(w.bootstrap);if w.bootstrap.library==old then w.bootstrap.library=library end
    return root,{Configuration=configuration,Database=database,Remaining='domain configs/platform/logging/media/publication are supplied separately'}
end
function api.Client(input,configuration,ui)
    assert(configuration.Configuration and configuration.CreateConfiguration,'client configuration assembly required')
    assert(ui.Library and ui.Streaming,'client native UI assembly required')
    local root=copy(input);local config=branch(root,{'runtimeContext','deliveryContext','configurationContext'})
    config.configuration,config.createConfiguration=configuration.Configuration,configuration.CreateConfiguration
    config.mediaContext=copy(config.mediaContext);local media=config.mediaContext
    media.media=copy(media.media);local streaming={}
    for _,name in ipairs({'requestModel','requestAnimDict','createObject','createPed','createVehicle','deleteEntity','releaseModel','releaseAnimDict'})do
        streaming[name]=function(...)return assert(ui.Streaming[name],'UI streaming not open:'..name)(...)end
    end
    media.media.streaming=streaming;media.worker=copy(media.worker);local w=media.worker
    w.central=copy(w.central);w.central.library=uiLibrary(w.central.library,ui)
    w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
    for name,part in pairs(w.domains.domains)do if part.library then local p=copy(part);p.library=uiLibrary(part.library,ui);w.domains.domains[name]=p end end
    return root,{Configuration=configuration,UI=ui,Remaining='domain configs/platform/native cache and non-UI PR providers are supplied separately'}
end
return api
