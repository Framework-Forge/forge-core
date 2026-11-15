local T=dofile('tests/kernel_native_domains_config_harness.lua');local r=T.new();local original=r.original();local a=r.mount();local count=0
local function same(x,y,path)
    assert(type(x)==type(y),path)
    if type(x)=='function'then return end
    if type(x)~='table'then assert(x==y,path);return end
    for k,v in pairs(y)do same(x[k],v,path..'.'..tostring(k))end
    for k in pairs(x)do assert(y[k]~=nil,path..': extra '..tostring(k))end
end
same(a.Config,original,'config')
for _,v in pairs(a.Config)do if type(v)=='table'then count=count+1 end end
assert(a.Config.NotifyPos=='center-left'and a.Config.ImagePath=='images/custom/')
assert(a.Config.CharacterSlots.previewStorage=='data/character_previews.json')
assert(a.Config.Npcs.AnimationPresets and a.Config.Npcs.PedModelTypes)
assert(a.Config.Stores.Defaults.stockModelVersion==4 and a.Config.Inventory.Storage.items=='data/items.json')
assert(a.Translate('menu.test')=='t:menu.test');assert(count>=26)
print('PASS141 complete installed base/domain configurations,all keys/values compared;no persisted IO;Npcs enrichments and custom paths preserved')
