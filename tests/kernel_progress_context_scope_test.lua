local G=dofile('tests/kernel_engine_profile_harness.lua');local P=dofile('tests/kernel_progress_harness.lua');local r=G.new('client');local p=P.new(true)
local bind=G.H.load('kernel/entry/progress_context_ports.lua',G.H.environment());local input=r.profilePorts.bootstrap.context;local out=bind(input,p.api)
assert(bind(input,p.api)~=out);assert(input~=out)
local w=out.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
local old=input.runtimeContext.deliveryContext.configurationContext.mediaContext.worker
assert(w.central.library.callback==old.central.library.callback and w.central.library.Notify==old.central.library.Notify)
local held=w.central.library.progressBar;p.api.Close();assert(not pcall(held,{duration=1}));assert(not pcall(bind,input,p.api))
assert(not pcall(bind,{},p.api));r.finishProfile()
print('PASS152 four fresh-view/borrowed-method/retained-function/closed-scope checks;no second progress engine')
