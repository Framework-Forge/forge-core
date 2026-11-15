local T=dofile('tests/kernel_state_input_harness.lua')
local r=T.new()
local menu=r.graph.Parts.Work.Menu
local admin,player=0,0
menu.openMain=function()admin=admin+1 end
menu.openPlayerMenu=function()player=player+1 end
r.prepare();assert(r.api.Install())
local a=r.provider.get('forge_core_open_menu')
local p=r.provider.get('forge_core_open_player_menu')
assert(a and p)
assert(a.combos[1].keys[1]=='LMENU' and a.combos[1].keys[2]=='7')
assert(p.combos[1].keys[1]=='F9')
a.onPressed();p.onPressed();assert(admin==1 and player==1)
local stale=a.onPressed
assert(r.api.Dispose());stale();assert(admin==1)
assert(r.provider.get('forge_core_open_menu')==nil)
assert(r.provider.get('forge_core_open_player_menu')==nil)
print('PASS menu bindings: configured combinations, canonical menu dispatch, disposal and stale callback refusal')
