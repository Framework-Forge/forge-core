local H=dofile('tests/cache_harness.lua')
local r=H.new(false);local e=r.env
e.ForgeCore.Client={Menu={},MenuShared={}}
e.ForgeCore.t=function(key) return key end
e.PlayerPedId=function() return 11 end;e.GetEntityCoords=function() return {x=1,y=2,z=3} end;e.GetEntityHeading=function() return 90 end
r.load('shared/automedic.lua')
local Shared=e.ForgeCore.Client.MenuShared
local context,settings,saved,editor= nil,{beds={},hospitalFallback=true},nil,nil
Shared.showContext=function(data) context=data;return true end
Shared.notify=function() end;Shared.notifyFailure=function(_,reason) error(reason) end
Shared.alertDialog=function() return 'confirm' end
Shared.inputDialog=function(_,rows)
    assert(rows[1].type=='input' and rows[2].type=='select','No manual coordinate/number inputs for beds')
    return {'Hospital','v_med_bed2'}
end
Shared.awaitServer=function(name,bed)
    if name==e.PR.AutoMedic.Callbacks.getSettings then return true,H.copy(settings) end
    if name==e.PR.AutoMedic.Callbacks.saveBed then saved=bed;settings.beds={H.copy(bed)};return true,H.copy(settings) end
    if name==e.PR.AutoMedic.Callbacks.deleteBed then settings.beds={};return true,H.copy(settings) end
    error('Unexpected callback '..name)
end
e.pr_lib.fivem={blips={getPropImageUrl=function(model) return model..'.jpg' end},devtools={placeAnimatedPed=function(model,slots,animations,cb)
    assert(model=='mp_m_freemode_01' and slots==1)
    assert(animations[1].animDict=='anim@gangops@morgue@table@' and animations[1].animName=='body_search')
    editor=true;cb({x=2,y=2,z=3,heading=180});return true
end}}
r.load('client/menu/menu_automedic.lua')
local Menu=e.ForgeCore.Client.Menu
Menu.openAutoMedicBeds();assert(context.menu=='forge_core_automedic')
context.options[1].onSelect()
assert(editor and saved and saved.model=='v_med_bed2' and saved.exit.x==1 and saved.heading==180)
assert(context.options[2].image=='v_med_bed2.jpg')
context.options[2].onSelect();assert(context.menu=='forge_core_automedic_beds')
context.options[3].onSelect();assert(saved.prison==true)
print('PASS AutoMedic menu: animated editor API, bed model image, saved safe exit, prison flag and parent menu')
