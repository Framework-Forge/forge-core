local H=dofile('tests/cache_harness.lua')
local specs={
    {'objects','ObjectsService','objects'},{'npcs','NpcsService','npcs'},
    {'spotlights','SpotlightsService','spotlights'},{'billboards','BillboardsService','billboards'},
    {'stores','StoresService','stores'},{'farms','FarmsService','farms'},
    {'starterpack','StarterpackService','starterpack'},{'density','DensityService','density'},
    {'vinewood','VinewoodService','vinewood'},{'character_slots','CharacterSlotService','characterPreviews','start'},
}
local function vector(x,y,z,w) return {x=x,y=y,z=z,w=w} end
for _,spec in ipairs(specs) do
    local r=H.new(true);local e=r.env
    e.vector3=vector;e.vector4=vector;e.vec3=vector;e.vec4=vector;e.joaat=function() return 1 end
    e.ForgeCore.t=function(key) return key end
    r.load('shared/cache.lua');r.load('shared/'..spec[1]..'.lua');r.load('server/'..spec[1]..'/service.lua')
    local service=assert(e.ForgeCore[spec[2]],spec[1]);assert(service[spec[4] or 'load'])()
    local record=assert(e.ForgeCore.State.getRecord(spec[3]),'Missing initial '..spec[3])
    assert(type(record.data)=='table')
    -- Publication must happen after persistence, and never on a failed write.
    if spec[1]~='character_slots' and spec[1]~='starterpack' then
        local first=record.revision;r.advance(1)
        local success
        if spec[1]=='density' or spec[1]=='vinewood' then success=service.save(0,service.getSettings()) else success=service.save() end
        assert(success,spec[1]..' save');assert(e.ForgeCore.State.getRecord(spec[3]).revision>first)
        local latest=e.ForgeCore.State.getRecord(spec[3]).revision
        e.pr_lib.saveJson=function() return false end;e.SaveResourceFile=function() return false end;r.advance(1)
        if spec[1]=='density' or spec[1]=='vinewood' then success=service.save(0,service.getSettings()) else success=service.save() end
        assert(not success,spec[1]..' must report persistence failure')
        assert(e.ForgeCore.State.getRecord(spec[3]).revision==latest,spec[1]..' cannot publish an unsaved change')
    elseif spec[1]=='starterpack' then
        local settings=H.copy(service.state.settings);settings.enabled=not settings.enabled
        e.SaveResourceFile=function() return false end
        assert(not service.saveSettings(0,settings))
        assert(e.ForgeCore.State.getRecord('starterpack').revision==record.revision)
        e.SaveResourceFile=function() return true end
        assert(service.saveSettings(0,settings));assert(e.ForgeCore.State.get('starterpack').settings.enabled==settings.enabled)
    else
        e.pr_lib.loadJson=function() return {{x=1,y=2,z=3,heading=45,animation='sit_chair'}} end
        service.loaded=false;service.start()
        assert(e.ForgeCore.State.get('characterPreviews')[1].scenario=='PROP_HUMAN_SEAT_CHAIR')
    end
    print('PASS world service: '..spec[1])
end
