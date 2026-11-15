-- Test-only slots/storage/calendar/native/codec doubles. No SQL or resource effects.
local P = dofile('tests/kernel_player_harness.lua')
local H = P.H
local C = {P=P,H=H}
function C.slots(ported,configure)
    local r={trace={},ready={},exports={},characters={},purchased={},blocked={},terms={},users={L2=7,L1=7},
        txResult=true,insertResult=1,updateResult=1,logoutResult=true,players={},encoded=nil,codec={},encodeIndex=0}
    function r.record(kind,...) r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))} end
    r.config={characters={defaultNumberOfCharacters=3}}
    r.starterItems={{name='water',amount=2},{name='phone',amount=1}}
    r.today={year=2026,month=10,day=19,hour=12,min=0,sec=0}
    local calendar={date=function(format,stamp) r.record('date',format,stamp);return os.date(format,stamp or os.time(H.copy(r.today))) end,
        time=function(value) r.record('time',value);return os.time(value) end}
    local json={}
    json.decode=function(text) r.record('decode',text);if text=='bad' then error('invalid json',0) end;return H.copy(r.codec[text]) end
    json.encode=function(value) r.encodeIndex=r.encodeIndex+1;local key='encoded'..r.encodeIndex;r.record('encode',value);r.codec[key]=H.copy(value);return key end
    local function apply(sql,params)
        local user,slot=params and params[1],params and params[2]
        if sql:find('INSERT IGNORE INTO qbx_character_slot_blocks',1,true) then r.blocked[user]=r.blocked[user] or {};r.blocked[user][slot]=true
        elseif sql:find('DELETE FROM qbx_character_slot_blocks',1,true) then if r.blocked[user] then r.blocked[user][slot]=nil end
        elseif sql:find('INSERT IGNORE INTO qbx_character_slots',1,true) then r.purchased[user]=r.purchased[user] or {};r.purchased[user][slot]=true
        elseif sql:find('DELETE FROM qbx_character_slots',1,true) then if r.purchased[user] then r.purchased[user][slot]=nil end
        elseif sql:find('qbx_character_terms_acceptance',1,true) then r.terms[user]=r.terms[user] or {};r.terms[user][slot]=true
        elseif sql:find('INSERT INTO qbx_character_slot_settings',1,true) then r.encoded=params[1]
        else error('Unexpected simulated SQL '..sql) end
    end
    local db={}
    db.query={await=function(sql,params)
        r.record('query',sql,params)
        if sql:find('CREATE TABLE',1,true) then if r.ddlError then error('ddl failed',0) end;return true end
        local rows={}
        local records=sql:find('FROM qbx_character_slot_blocks',1,true) and r.blocked or r.purchased
        for slot,enabled in pairs(records[params[1]] or {}) do if enabled then rows[#rows+1]={slot_id=slot} end end
        table.sort(rows,function(a,b) return tonumber(a.slot_id)<tonumber(b.slot_id) end)
        if r.queryHook then return r.queryHook(sql,params,rows) end
        return rows
    end}
    db.scalar={await=function(sql) r.record('scalar',sql);return r.encoded end}
    db.insert={await=function(sql,params) r.record('insert',sql,params);if r.insertResult then apply(sql,params) end;return r.insertResult end}
    db.update={await=function(sql,params) r.record('update',sql,params);if r.updateResult then apply(sql,params) end;return r.updateResult end}
    db.transaction={await=function(queries)
        r.record('transaction',queries);if r.txHook then r.txHook(queries) end
        if r.txError then error('transaction failed',0) end
        if r.txResult then for _,query in ipairs(queries) do apply(query.query,query.values) end end
        return r.txResult
    end}
    local storage={
        fetchUserByIdentifier=function(id) r.record('user',id);return r.users[id] end,
        fetchAllPlayerEntities=function(...) r.record('characters',...);return H.copy(r.characters) end}
    local native={GetPlayerIdentifierByType=function(source,kind) r.record('identifier',source,kind);if r.noIdentifiers then return nil end;return kind=='license2' and 'L2' or 'L1' end,
        DropPlayer=function(...) r.record('drop',...) end}
    local getPlayer=function(source) r.record('getPlayer',source);return r.players[source] end
    local logout=function(source) r.record('logout',source);return r.logoutResult end
    r.service={}
    r.bindings={config=r.config,starterItems=r.starterItems,storage=storage,db=db,json=json,calendar=calendar,native=native,
        getPlayer=getPlayer,logout=logout,service=r.service}
    if configure then configure(r) end
    local env=H.environment()
    if ported then
        r.module=H.load('kernel/server/character_slots.lua',env)(r.bindings)
        r.api,r.ready,r.exports=r.module.Service,r.module.Ready,r.module.Exports
        assert(r.api==r.service and #r.trace==0 and #r.ready==1)
    else
        env.require=function(name) if name=='config.server' then return r.config elseif name=='config.shared' then return {starterItems=r.starterItems} elseif name=='server.storage.main' then return storage end;error(name) end
        env.MySQL,env.json,env.os=db,json,calendar
        env.GetPlayerIdentifierByType,env.DropPlayer,env.GetPlayer,env.Logout=native.GetPlayerIdentifierByType,native.DropPlayer,getPlayer,logout
        env.QBXCharacterSlots=r.service
        env.exports=function(name,fn) r.exports[name]=fn end
        db.ready=function(fn) r.ready[#r.ready+1]=fn end
        P.loadOrigin('server/character_slots.lua',env);r.api=env.QBXCharacterSlots
        assert(#r.trace==0 and #r.ready==1)
    end
    function r.settings(value) r.codec.settings=H.copy(value);r.encoded='settings' end
    r.env=env
    return r
end
function C.compareSlots(name,action)
    local a,b=C.slots(false),C.slots(true)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name..': returns')
    H.same(b.trace,a.trace,name..': effects')
    local function inputSnapshot(value)
        -- NaN intentionally appears in the invalid JSON-input fixture; NaN ~= NaN in Lua.
        -- Only normalize its representation in the fixture store, not returned settings/effects.
        if type(value)=='number' and value~=value then return '<invalid NaN fixture>' end
        if type(value)~='table' then return value end
        local result={};for key,item in pairs(value) do result[key]=inputSnapshot(item) end;return result
    end
    for _,key in ipairs({'purchased','blocked','terms','encoded','codec'}) do H.same(inputSnapshot(b[key]),inputSnapshot(a[key]),name..': '..key) end
end
function C.documents(ported)
    local r={trace={},state='started',ready=true,items={passport=true,ignored=false},files={},codec={}}
    function r.record(kind,...) r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))} end
    local state=function() r.record('documentState');return r.state end
    local get=function() r.record('documentCatalog');if r.apiError then error('catalog unavailable',0) end;return r.ready,r.items end
    local read=function(path) r.record('readDocumentConfig',path);return r.files[path] end
    local json={decode=function(text) r.record('decode',text);if text=='bad' then error('invalid json',0) end;return H.copy(r.codec[text]) end}
    r.bindings={documentState=state,getDocumentItems=get,readDocumentConfig=read,json=json}
    local env=H.environment()
    if ported then r.api=H.load('kernel/server/document_items.lua',env)(r.bindings)
    else
        env.GetResourceState=function(resource) assert(resource=='forge-dk');return state() end
        env.LoadResourceFile=function(resource,path) assert(resource=='forge-dk');return read(path) end
        env.exports={['forge-dk']={GetDocumentItems=function() return get() end}};env.json=json
        r.api=P.loadOrigin('server/document_items.lua',env)
    end
    assert(#r.trace==0);return r
end
function C.character(ported)
    local r={trace={},callbacks={},events={},inventoryState='started',previewState='started',
        previews={{x=1,y=2,z=3,heading=45,animation='stand',scenario='WORLD_HUMAN_STAND_IMPATIENT'}},
        loginResult=true,loginReason=nil,deleteResult=true,allowed=true,termsResult=true,inventoryReadyAfter=1,inventoryChecks=0,
        configured={{name='water',amount=2},{name='id_card',amount=1}},stateError='account_not_found',documentSet={id_card=true},
        skins={A={skin='skin data',model='mp_m_freemode_01'}},identifiers={discord='D',ip='I',license2='L2',license='L1'}}
    function r.record(kind,...) r.trace[#r.trace+1]={kind=kind,args=P.snapshot(table.pack(...))} end
    local function effect(kind) return function(...) r.record(kind,...) end end
    r.settings={starterItems=r.configured,maxSlots=3}
    r.state={characters={{citizenid='A'}},displaySlots=3,settings=r.settings,unlocked={[1]=true},blocked={[2]=true}}
    local slots={
        getSettings=function() r.record('slotSettings');return r.settings end,
        getState=function(source) r.record('slotState',source);return r.state,r.stateError end,
        canCreate=function(...) r.record('canCreate',...);return r.allowed,r.allowReason or 'slot_locked' end,
        recordTermsAcceptance=function(source) r.record('terms',source);return r.termsResult end}
    local storage={fetchPlayerSkin=function(id) r.record('skin',id);return r.skins[id] end}
    local native={
        GetResourceState=function(resource) assert(resource=='ox_inventory');r.record('inventoryState');return r.inventoryState end,
        Wait=function(ms) r.record('wait',ms);if r.yieldWait then coroutine.yield(ms) end end,
        GetPlayerName=function(source) r.record('name',source);return 'Player '..source end,
        GetPlayerIdentifierByType=function(source,kind) r.record('identifier',source,kind);return r.identifiers[kind] end,
        joaat=function(model) r.record('hash',model);return 42 end}
    local inventory={
        GetInventory=function(source) r.record('getInventory',source);r.inventoryChecks=r.inventoryChecks+1;return r.inventoryChecks>=r.inventoryReadyAfter and {} or nil end,
        AddItem=function(...) r.record('AddItem',...);return r.addResult end}
    local starterItems={{name='water',amount=1,metadata={quality=100}}}
    local documentItems={get=function() r.record('documents');return r.documentSet end}
    local ready=function() r.record('previewReady');return r.previewState=='started' end
    local previews=function() r.record('previews');if r.previewError then error('preview unavailable',0) end;return r.previews end
    local login=function(source,citizenId,data) r.record('Login',source,citizenId,data);if r.loginHook then return r.loginHook(source,citizenId,data) end;return r.loginResult,r.loginReason end
    local delete=function(...) r.record('ownedDelete',...);return r.deleteResult end
    local notify=effect('notify')
    local locale=function(key) return key end
    local library={print={info=effect('info'),error=effect('error')}}
    r.bindings={config={logging={webhook={joinleave='mock'}}},logger={log=effect('log')},storage=storage,starterItems=starterItems,
        documentItems=documentItems,slots=slots,inventory=inventory,native=native,library=library,previewsReady=ready,
        getPreviews=previews,login=login,deleteCharacter=delete,notify=notify,locale=locale}
    local env=H.environment()
    if ported then
        r.module=H.load('kernel/server/character.lua',env)(r.bindings);r.callbacks=r.module.Callbacks
        for _,e in ipairs(r.module.Events) do r.events[e.name]=e.handler end
    else
        env.require=function(name)
            if name=='config.server' then return r.bindings.config elseif name=='config.shared' then return {starterItems=starterItems}
            elseif name=='server.storage.main' then return storage elseif name=='modules.logger' then return r.bindings.logger
            elseif name=='server.document_items' then return documentItems end;error(name)
        end
        for name,fn in pairs(native) do env[name]=fn end
        env.GetResourceState=function(resource) if resource=='forge-core' then ready();return r.previewState end;return native.GetResourceState(resource) end
        env.exports={ox_inventory={GetInventory=function(_,...) return inventory.GetInventory(...) end,AddItem=function(_,...) return inventory.AddItem(...) end},
            ['forge-core']={GetCharacterPreviews=function() return previews() end}}
        env.QBXCharacterSlots=slots;env.Login,env.DeleteCharacter,env.Notify,env.locale=login,delete,notify,locale
        env.RegisterNetEvent=function(name,fn) r.events[name]=function(source,...) env.source=source;return fn(...) end end
        library.callback={register=function(name,fn) r.callbacks[name]=fn end};env.lib=library
        P.loadOrigin('server/character.lua',env)
    end
    assert(#r.trace==0);r.env=env;return r
end
function C.compare(kind,name,action)
    local a,b=C[kind](false),C[kind](true)
    H.same(P.snapshot(table.pack(action(b))),P.snapshot(table.pack(action(a))),name..': returns')
    H.same(b.trace,a.trace,name..': effects')
end
return C

