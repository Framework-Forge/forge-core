local T=dofile('tests/kernel_keybind_harness.lua');local r=T.new(true);local bind=T.H.load('kernel/entry/keybind_context_ports.lua',T.H.environment())
local old=setmetatable({sentinel={},callback={},progressBar=function()return'progress'end},{__index=function(_,key)if key=='lazy'then return'lazy-provider'end end})
local worker={central={library=old,Consumer={library=old}},domains={domains={Hospital={library=old},Other={config={}}}}}
local input={runtimeContext={deliveryContext={configurationContext={mediaContext={worker=worker,shutdown={input={keybind={}}}}}}}}
local out=bind(input,r.api);local m=out.runtimeContext.deliveryContext.configurationContext.mediaContext
assert(m.worker.central.library~=old and m.worker.central.library==m.worker.domains.domains.Hospital.library)
assert(m.worker.central.library==m.worker.central.Consumer.library and m.worker.central.library.lazy=='lazy-provider')
assert(m.worker.central.library.callback==old.callback and m.worker.central.library.progressBar()== 'progress')
local called=0;local key=m.shutdown.input.keybind({name='hospital',defaultKey='e',onPressed=function()called=called+1 end})
r.fire('+hospital');assert(called==1 and m.worker.central.library.addKeybind.get('hospital')==key)
assert(worker.central.library==old and input.runtimeContext.deliveryContext.configurationContext.mediaContext.shutdown.input.keybind~=m.shutdown.input.keybind)
assert(not pcall(bind,input,{IsCurrent=function()return false end}));assert(r.api.Close())
print('PASS165 same keybind in central/domain/input;lazy provider and callbacks/progress/config preserved;source unmodified/stale refused')
