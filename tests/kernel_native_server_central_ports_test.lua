local T=dofile('tests/kernel_assembly_harness.lua');local r=T.new();local H=T.H
local factory=H.load('kernel/entry/native_server_central_ports.lua',T.env())
r.library.print=r.ports.session.player.library.print
for k,v in pairs(r.ports.session.player.library)do if r.library[k]==nil then r.library[k]=v end end
r.library.callback.await=r.ports.session.player.library.callback.await
local native={};for k,v in pairs(r.native)do native[k]=v end
for _,part in pairs(r.ports)do if type(part)=='table'and type(part.native)=='table'then for k,v in pairs(part.native)do native[k]=v end end end
local f={Side='server',IsCurrent=function()return true end,Events={listen=r.native.listen,source=r.native.getSource},
 Seed={IO={Codec=r.codec}},EngineInputs={Describe=function()return{}end,Select=function()return native end}}
local p={parts=r.ports,library=r.library,database=r.db,platform=r.ports.session.player.platform}
local out=factory(f,p);assert(out~=r.ports and out.session.player~=r.ports.session.player)
assert(out.session.player.db==r.db and out.slots.db==r.db and out.session.player.json==r.codec)
assert(out.jobs.dependencies~=r.ports.jobs.dependencies and next(out.jobs.dependencies)==nil)
local create=H.load('kernel/server/assembly_core.lua',T.env());local graph=create(r.base,out)
assert(graph.PlayerCore==r.base.PlayerCore and graph.State=='prepared-inactive')
assert(graph.PlayerCore.Shared==r.base.Shared and graph.PlayerCore.Groups==r.base.Groups)
for _,name in ipairs({'session','slots','lifecycle','runtime','character','catalog','jobs','finance','business','inventory','consumption','weapons','transport'})do
 local parts={};for k,v in pairs(r.ports)do parts[k]=v end;parts[name]=nil
 assert(not pcall(factory,f,{parts=parts,library=r.library,database=r.db,platform=p.platform}),name)
end
print('PASS186 central47 native composition;one Player/Groups/DB/codec;fresh dependency holder;missing13 parts refused')
