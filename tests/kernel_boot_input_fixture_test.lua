local T=dofile('tests/kernel_keybind_entry167_harness.lua');local r=T.client()
local contract=T.H.load('kernel/entry/boot_input_contract.lua',T.H.environment())
local result=contract.Inspect(r.options167,'client',function(fn)return debug.getinfo(fn,'S')end)
assert(not result.accepted and result.fixtures>0 and result.functions>100)
local bootstrap=0;for _,i in ipairs(result.issues)do if i.reason=='test_provider'and i.path:find('options.bootstrap',1,true)then bootstrap=bootstrap+1 end end
assert(bootstrap>0);r.finish167()
print('PASS168 physical167 input audit refuses actual fixtures: functions='..result.functions..' test providers='..result.fixtures..' bootstrap='..bootstrap)
