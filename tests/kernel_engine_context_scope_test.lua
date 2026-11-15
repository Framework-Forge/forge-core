local T=dofile('tests/kernel_engine_context_harness.lua');local r=T.new('server');local original=T.graph(r,r.original148)
assert(not pcall(T.bind.Client,r.original148,r.engine146,r.engineSchema))
assert(not pcall(T.bind.Server,r.original148,r.engine146,nil))
local schema={};for k,v in pairs(r.engineSchema)do schema[k]=v end;schema.emit='UnknownEngine148'
assert(not pcall(T.bind.Server,r.original148,r.engine146,schema));assert(T.graph(r,r.original148)==original)
local old=original.central.jobs.native;old.extra148=function()return'caller-only'end;old.flag148=37
local next,audit=T.bind.Server(r.original148,r.engine146,r.engineSchema);local view=T.graph(r,next).central.jobs.native
assert(view.extra148==old.extra148 and view.flag148==37)
local found=false;for _,v in ipairs(audit.remaining)do if v.name=='extra148'then found=true end end;assert(found)
r.engine146.Close();assert(not pcall(T.bind.Server,r.original148,r.engine146,r.engineSchema));r.finishProfile()
print('PASS148 five side/schema/missing-native/explicit-unknown/closed-owner checks;no fallback or input mutation by failed binding')
