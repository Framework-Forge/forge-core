local K=dofile('tests/kernel_keybind_harness.lua');local H=K.H;local r=K.new(true)
local callbacks,removed={},{};local current=true;local resolved=0
local f={Side='client',IsCurrent=function()return current end,Base={ClientAssembly={IsCanonical=function()return true end,
 Parts={Helpers={Lib={getEntityAndNetIdFromBagName=function(name)resolved=resolved+1;return name,42 end}}}}}}
local n={AddStateBagChangeHandler=function(key,filter,fn)local cookie=#callbacks+1;callbacks[cookie]={key=key,filter=filter,fn=fn};return cookie end,
 RemoveStateBagChangeHandler=function(cookie)removed[cookie]=true end}
local a=H.load('../pr_bridge/bridge/delivery/forge_state_input_ports.lua',H.environment())({prCore=r.core,foundation=f,native=n})
assert(#callbacks==0);assert(a.Ports.availableKey('input196'))
a.Ports.keybind({name='input196',defaultKey='e',onPressed=function()resolved=resolved+10 end})
assert(not a.Ports.availableKey('input196'));r.fire('+input196');assert(resolved==10)
local calls=0;local token=a.Ports.addBag('managed',nil,function(value)calls=calls+value end)
callbacks[1].fn(3);assert(calls==3 and callbacks[1].key=='managed')
local entity,net=a.Ports.resolveEntity('entity:42');assert(entity=='entity:42'and net==42 and resolved==11)
assert(not a.Ports.removeBag({}));assert(a.Ports.removeBag(token)and removed[1])
assert(a.Close()and r.core.forgeKeybindScope==r.api);callbacks[1].fn(4);assert(calls==3)
assert(not pcall(a.Ports.keybind.get,'input196'));assert(r.api.Close())
print('PASS196 real owned keybind borrowed;statebag cookies/foreign removal/late callbacks and canonical local resolver;no second key service')
