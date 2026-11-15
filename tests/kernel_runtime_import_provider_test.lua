local T=dofile('tests/kernel_runtime_import_harness.lua');local H,P=T.H,T.P
local a,b=T.provider(),T.provider();local n=#b.trace;b.mount();assert(#b.trace==n,'imports factory inert')
local native=0
local function compare(key)
    local x,y=table.pack(pcall(function()return a.nativeCache[key]end)),table.pack(pcall(function()return b.api.NativeCache[key]end))
    H.same(P.snapshot(y),P.snapshot(x),key);H.same(b.trace,a.trace,key..' trace');native=native+1
end
for _,key in ipairs({'resource','game','playerId','serverId','ped','vehicle','seat','weapon'})do compare(key)end
a.pollNative();b.pollNative();compare('ped');compare('weapon')
a.ped=22;b.ped=22;a.vehicle=40;b.vehicle=40;a.weapon=123;b.weapon=123
a.pollNative();b.pollNative();for _,key in ipairs({'ped','vehicle','seat','weapon'})do compare(key)end
a.ped=0;b.ped=0;a.pollNative();b.pollNative();compare('ped')
a.ped=23;b.ped=23;a.vehicle=0;b.vehicle=0;a.weapon=0;b.weapon=0;a.pollNative();b.pollNative()
for _,key in ipairs({'ped','vehicle','seat','weapon'})do compare(key)end
assert(native==19 and b.api.NativeCache.ped==23,'native cache remains live,not a copied ped')
assert(not pcall(function()b.api.NativeCache.ped=99 end)and b.nativeCache.ped==23,'native view never writes provider')
assert(b.api.Open());local locales=0
local langs={'ar','bg','cn','cs','da','de','ee','en','es','et','fa','fi','fr','ge','he','hu','in','is','it','ja','lt','lv','nl','no','pl','pt-br','pt','ro','rs','ru','sl','sv','th','tr','vn','zh-tw'}
for _,lang in ipairs(langs)do
    a.setLanguage(lang);b.setLanguage(lang)
    for _,key in ipairs({'error.not_online','info.char_male','info.play_description','missing.runtime73'})do
        local x,y=table.pack(pcall(a.ports.locale,key,'PLAYER')),table.pack(pcall(b.api.Translate,key,'PLAYER'))
        H.same(P.snapshot(y),P.snapshot(x),lang..':'..key);locales=locales+1
    end
end
assert(locales==144,'36 installed JSON languages compared')
a.setLanguage('absent');b.setLanguage('absent');H.same(b.api.Translate('error.not_online'),a.ports.locale('error.not_online'),'English fallback')
b.env.lib.getLocales()['runtime73.format']='Hello %s %d'
assert(b.api.Translate('runtime73.format','P',3)=='Hello P 3'and not pcall(b.api.Translate,'runtime73.format',{}),'positional locale and format errors retained')
local raw=T.provider();raw.ports.locale=function()return nil,false,17 end;raw.mount();local x,y,z=raw.api.Translate('tuple');assert(x==nil and y==false and z==17)
print('PASS lot73 provider:19 native cache comparisons,144 locale comparisons/36 installed languages,whole ox init/producer/table/locale,live ped/zero guard/vehicle/weapon/fallback/format/tuples;virtual only')
