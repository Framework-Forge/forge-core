local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('../pr_bridge/bridge/frameworks/forge/activation_namespace.lua',H.environment())
local calls=0;local foreign=false;local fail=false;local a
local function publish(name,fn)calls=calls+1;if fail then error('publication uncertain')end;return 'receipt'end
a=create{isCurrent=function()return true end,available=function(kind,name)
 if name=='reenter'then assert(a.Registration.publishExport('other',function()end)=='receipt')end
 return not foreign end,publishExport=publish,prCommand=function(n,p,f)return publish(n,f)end,oxCommand=function(n,p,f)return publish(n,f)end}
assert(a.Registration.publishExport('reenter',function()end)=='receipt'and calls==2)
assert(not a.Registration.publishExport('reenter',function()end))
foreign=true;assert(not a.Registration.available('export','foreign'));foreign=false
assert(a.Registration.prCommand('Admin',{},function()end)=='receipt')
assert(not a.Registration.oxCommand('admin',{},function()end))
assert(a.Registration.prCommand({'aliasA','aliasB'},{help='kept'},function()end)=='receipt')
assert(not a.Registration.available('command','aliasB'))
fail=true;assert(not pcall(a.Registration.publishExport,'uncertain',function()end));fail=false
assert(not a.Registration.available('export','uncertain'))
assert(a.Progress().uncertain==1 and a.Close()and a.Progress().complete)
assert(not a.Registration.available('export','new'))
print('PASS263 shared namespace prevents duplicates/case collision/uncertain reuse and honors external availability;no physical removal claim')
