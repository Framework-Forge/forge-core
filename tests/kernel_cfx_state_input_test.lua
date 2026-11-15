local H=dofile('tests/kernel_harness.lua');local create=dofile('tests/kernel_cfx_player_fixture.lua')
local inspect=H.load('kernel/entry/owned_boot_input_contract_v2.lua',H.environment()).Inspect
local cases={cfx=create().LocalPlayer,plain={state={}},absent={},throwing=setmetatable({},{__index=function()error('state unavailable')end})}
for name,player in pairs(cases)do
 local output=inspect({profile={progress={localPlayer=player}}},'client',function()return{source='@@cfx/test-native'}end)
 local refused=false
 for _,issue in ipairs(output.issues)do if issue.path=='options.profile.progress.localPlayer.state'then refused=true end end
 assert(refused==(name=='absent'or name=='throwing'),'real Cfx state bag must pass the leaf check: '..name)
end
local accesses=0;local fake=setmetatable({},{__index=function()accesses=accesses+1;return{localPlayer={state={}}}end})
inspect({profile=fake},'client',function()return{source='@@cfx/test-native'}end)
assert(accesses==0,'do not relax raw structural checks for option tables')
local cfx=create();inspect({profile={progress={localPlayer=cfx.LocalPlayer}}},'client',function()return{source='@@cfx/test-native'}end)
assert(#cfx.Writes==0,'input inspection must not write or replace the native state bag')
cfx.LocalPlayer.state:set('test',true,false);assert(cfx.LocalPlayer.state.test==true and #cfx.Writes==1)
print('PASS installed Cfx Player state getter in input inspection; missing/throwing state denied; raw structure retained; no invented state or writes')
