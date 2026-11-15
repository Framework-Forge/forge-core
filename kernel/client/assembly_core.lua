-- Private central client composition. Constructors only; no bootstrap, installation or hydration.
local createMembership=require 'kernel.shared.functions'
local createHelpers=require 'kernel.helpers'
local createProducers=require 'kernel.client.session_core'
local createLegacy=require 'kernel.client.legacy_core'
local createRuntime=require 'kernel.client.runtime_core'
local createCharacter=require 'kernel.client.character_core'
local createConsumption=require 'kernel.client.inventory.consumption_core'

local function copy(value)
    assert(type(value)=='table','explicit composition ports required')
    local out={};for key,item in pairs(value)do out[key]=item end;return out
end
return function(state,ports)
    assert(type(state)=='table'and type(ports)=='table','canonical client state and ports required')
    assert(type(state.PlayerData)=='table'and type(state.Shared)=='table','existing client PlayerData/Shared required')
    for _,key in ipairs({'ClientAssembly','ProducerCore','BridgeCache','Status','Session','LegacyCore','RuntimeCore',
        'CharacterCore','CharacterRenderer','Consumption','AdministrationMenus','JobClientCore','WorldClientCore'})do
        assert(state[key]==nil,'fresh canonical client state required: '..key)
    end
    local config=assert(ports.config);assert(type(config.Client)=='table'and type(config.Inventory)=='table','complete local configs required')
    assert(type(config.Client.playerStatus)=='table'and type(config.Client.characters)=='table','client status/character config required')
    local native,library,cache=assert(ports.native),assert(ports.library),assert(ports.cache)
    assert(type(native)=='table'and type(library)=='table'and type(cache)=='table','explicit native/library/cache required')
    local bindings={}
    for _,name in ipairs({'membership','helpers','producers','legacy','runtime','character','consumption'})do bindings[name]=copy(ports[name])end
    for _,name in ipairs({'helpers','producers','legacy','runtime','character','consumption'})do
        assert(bindings[name].core==nil,'assembly owns canonical client state')
    end
    local function own(target,key,value)
        assert(target[key]==nil or target[key]==value,'foreign composition dependency: '..key);target[key]=value
    end
    for _,name in ipairs({'helpers','legacy','runtime','character','consumption'})do
        own(bindings[name],'native',native)
        if name~='character'then own(bindings[name],'library',library)end
    end
    for _,name in ipairs({'helpers','legacy','runtime','character'})do own(bindings[name],'cache',cache)end
    own(bindings.producers,'native',native);own(bindings.producers,'statusConfig',config.Client.playerStatus)
    own(bindings.helpers,'isServer',false)
    for _,key in ipairs({'shared','functions'})do assert(bindings.helpers[key]==nil,'client helpers cannot bind server services')end
    own(bindings.runtime,'config',config.Client);own(bindings.character,'config',config.Client);own(bindings.consumption,'config',config.Inventory)
    for _,key in ipairs({'helpers','membership'})do assert(bindings.legacy[key]==nil,'assembly owns legacy '..key)end
    for _,name in ipairs({'runtime','character'})do assert(bindings[name].functions==nil,'assembly owns local Notify')end
    assert(bindings.runtime.helpers==nil,'assembly owns runtime helpers')
    local api={Core=state,State='constructing',Parts={},Order={},Callbacks={},Unbound=true,Config={Client=config.Client,Inventory=config.Inventory}}
    state.ClientAssembly=api
    local function stage(name,value)api.Parts[name]=value;api.Order[#api.Order+1]=name;return value end
    local ok,problem=pcall(function()
        local membership=stage('Membership',createMembership(bindings.membership))
        local helpers=stage('Helpers',createHelpers(bindings.helpers))
        stage('Producers',createProducers(state,bindings.producers))
        bindings.legacy.helpers,bindings.legacy.membership=helpers.Lib,membership
        local legacy=stage('Legacy',createLegacy(state,bindings.legacy))
        bindings.runtime.helpers,bindings.runtime.functions=helpers.Lib,legacy.Functions
        stage('Runtime',createRuntime(state,bindings.runtime))
        bindings.character.functions=legacy.Functions
        stage('Character',createCharacter(state,bindings.character));api.RendererCore=state.CharacterRenderer
        stage('Consumption',createConsumption(state,bindings.consumption))
        local seen={}
        local function collect(owner,module)
            for name,handler in pairs(module.Callbacks or{})do
                assert(type(name)=='string'and type(handler)=='function','invalid raw client callback')
                assert(not seen[name],'duplicate raw client callback: '..name);seen[name]=true
                api.Callbacks[#api.Callbacks+1]={name=name,handler=handler,owner=owner}
            end
        end
        local p,r=api.Parts.Producers,api.Parts.Runtime
        for _,entry in ipairs({{'Cache',p.Cache},{'Status',p.Status},{'Session',p.Session},
            {'Main',r.Main},{'Events',r.Events},{'Loops',r.Loops},{'Discord',r.Discord},
            {'Character',api.Parts.Character.Flow},{'Consumption',api.Parts.Consumption}})do collect(entry[1],entry[2])end
        api.State='prepared-inactive'
    end)
    if not ok then api.State='construction-failed';error(problem,0)end
    function api.IsCanonical()
        return api.State=='prepared-inactive'and state.ClientAssembly==api and type(state.PlayerData)=='table'
            and type(state.Status)=='table'and state.CharacterRenderer==api.RendererCore
            and state.Shared==api.Shared and state.ProducerCore==api.Parts.Producers and state.LegacyCore==api.Parts.Legacy
            and state.RuntimeCore==api.Parts.Runtime and state.CharacterCore==api.Parts.Character
            and state.Consumption==api.Parts.Consumption and state.BridgeCache==api.Parts.Producers.Cache.Producer
            and state.Session==api.Parts.Producers.Session.Session
    end
    api.Shared=state.Shared
    return api
end
