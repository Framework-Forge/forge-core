local H=dofile('tests/kernel_harness.lua');local C=dofile('tests/kernel_client_domains_harness.lua');local S=dofile('tests/kernel_domains_harness.lua')
local factory=H.load('kernel/entry/native_domain_ports.lua',H.environment())
for _,side in ipairs({'server','client'})do
 local r=side=='server'and S.new()or C.new();local input=r.ports;local libraries={}
 for name,p in pairs(input.domains)do libraries[name]=p.library or r.central.library end
 local f={Side=side,IsCurrent=function()return true end,EngineInputs={Describe=function()return{}end,Select=function()return{}end},
 Seed={IO={Codec=side=='server'and r.central.codec or r.central.ports.character.json}}}
 local out,audit=factory(f,{domains=input.domains,libraries=libraries});assert(audit.domains==(side=='server'and 18 or 23))
 for name,p in pairs(out)do assert(p~=input.domains[name]and p.library==libraries[name])end
 local prior=input.domains.Skills;input.domains.Skills=nil;assert(not pcall(factory,f,{domains=input.domains,libraries=libraries}));input.domains.Skills=prior
 prior.config={};assert(not pcall(factory,f,{domains=input.domains,libraries=libraries}));prior.config=nil
 local p={};for k,v in pairs(input)do p[k]=v end;p.domains=out
 if side=='server'then
  local graph=r.factory(r.central.base,p);assert(graph.State=='prepared-inactive'and graph.PlayerCore==r.central.base.PlayerCore)
 else
  local graph=r.factory(r.central.state,p);assert(graph.IsCanonical()and graph.Core.PlayerData==r.central.state.PlayerData)
 end
end
print('PASS187 all18 server/23 client domain views construct actual assemblies;owned fields refused;unmapped explicit providers reported')
