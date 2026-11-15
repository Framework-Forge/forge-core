local T=dofile('tests/kernel_keybind_entry167_harness.lua');local r=T.client();local H=T.H
local contract=H.load('kernel/entry/boot_input_contract.lua',H.environment());local factory=H.load('kernel/entry/boot_preparation.lua',H.environment())
local builds=0;local rawCalls=0
local provider=function()builds=builds+1;return r.options167 end
local inspect=function(fn)if fn==provider then return{source='@native/options.lua'}end;return debug.getinfo(fn,'S')end
local p=factory({side='client',contract=contract,inspectFunction=inspect,providers={constructionApproved=true,buildInput=provider},
 createRaw=function()rawCalls=rawCalls+1;error('must not run')end})
local ok,report=p.Prepare();assert(not ok and not report.accepted and builds==1 and rawCalls==0 and report.fixtures>0)
assert(p.Stop());r.finish167()
print('PASS169 real167 fixture options blocked before raw/seed/exports/SQL;no native builder fallback')
