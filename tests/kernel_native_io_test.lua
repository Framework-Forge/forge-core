local T=dofile('tests/kernel_native_io_harness.lua');local r=T.new();r.allocate();assert(#r.writes==0)
assert(r.api.JSON.loadJson==r.api.JSON.readJson and r.api.JSON.saveJson==r.api.JSON.writeJson)
local actual=r.api.JSON.loadJson('@forge-core/data/character_previews.json');assert(type(actual)=='table'and #r.writes==0)
local locale=r.api.Files.LoadResourceFile('forge-core','kernel/locales/pt-br.json');assert(type(r.api.Codec.decode(locale))=='table'and #r.writes==0)
r.files['forge-core/data/virtual127.json']='{"value":1}'
assert(r.api.JSON.saveJsonRecovery('@forge-core/data/virtual127.json',{value=2}))
assert(r.files['forge-core/data/virtual127.json']=='{"value":2}'and r.files['forge-core/data/virtual127.json.bak']=='{"value":1}')
r.saveResult=false;assert(not r.api.JSON.saveJsonRecovery('@forge-core/data/virtual127.json',{value=3}))
assert(r.files['forge-core/data/virtual127.json']=='{"value":2}')
local held=r.api.JSON.loadJson;assert(r.api.Close()and not pcall(held,'@forge-core/data/character_previews.json'))
for _,w in ipairs(r.writes)do assert(w[2]:find('virtual127',1,true))end
print('PASS lot127 real read-only previews/locale,installed PR JSON recovery/aliases/BOOL1/refusal;all write calls virtual and confined to fixture;closed IO inert')
