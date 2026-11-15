-- Assemble installed domain defaults locally before either graph;no persisted data is read here.
return function(ports)
    local requireLocal=assert(ports.requireLocal);local current=assert(ports.isCurrent)
    local function valid()local ok,v=pcall(current);return ok and v==true end
    assert(valid(),'domain configuration unavailable')
    local getConvar,vec3=assert(ports.getConvar),assert(ports.vec3)
    local config,translate=requireLocal('kernel.config.forge_base')({getConvar=getConvar,locale=assert(ports.locale)})
    assert(valid(),'domain configuration changed while loading')
    local function make(name,...)
        assert(valid(),'domain configuration unavailable')
        local result=requireLocal('kernel.config.forge_'..name)(...)
        assert(valid(),'domain configuration changed while loading');return result
    end
    config.Job=make('jobs',{translate=translate,getConvar=getConvar,vec3=vec3,command=config.Command,adminAce=config.AdminAce})
    local entries={{'Player','player'},{'Afk','afk'},{'Password','password'},{'Weather','weather'},{'Whitelist','whitelist'},
        {'Density','density'},{'Weapons','weapons'},{'Inventory','inventory'},{'Vehicles','vehicles'},{'Skills','skills'},
        {'MultiJob','multijob'},{'Objects','objects'},{'Spotlights','spotlights'},{'Billboards','billboards'},
        {'Starterpack','starterpack'},{'DatabaseBackup','database_backup'},{'AutoMedic','automedic'},{'Vip','vip'},
        {'PlayerManagement','player_management'},{'CharacterSlots','character_slots'}}
    for _,entry in ipairs(entries)do config[entry[1]]=make(entry[2])end
    config.Staff=make('staff',config.AdminAce)
    config.Vinewood=make('vinewood',{vector3=vec3})
    config.Stores=make('stores',{vec3=vec3});config.Farms=make('farms',{vec3=vec3,translate=translate})
    -- These three installed files intentionally enrich the SAME Npcs table,in manifest order.
    make('npcs',config,translate);make('npcs_animations',config,translate);make('npcs_peds',config,translate)
    return {Config=config,Translate=translate,OperationalReady=false}
end
