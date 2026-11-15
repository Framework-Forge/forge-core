local T=dofile('tests/kernel_client_domains_harness.lua');local N=dofile('tests/kernel_native_foundation_harness.lua')
local req=N.loader();local r=T.new();local src=r.ports.domains
local f={Side='client',IsCurrent=function()return true end,Seed={IO={Codec=src.Administration.json},Execution={Native={Wait=src.Jobs.wait}}}}
local int={Zones=src.Zones.integrations,Work=src.Work.integrations,Progression=src.Skills.progression,Access=src.Access.characterIntegration,
 Panel=src.Settings.panelIntegration,Weather=src.World.weatherAdminIntegration,Npcs=src.Npcs.integration}
local lib={};for k,v in pairs(src.Work.library)do lib[k]=v end
local inv={};for k,v in pairs(lib.inventory or{})do inv[k]=v end;lib.inventory=inv
for _,p in pairs(src)do for k,v in pairs(p.library)do if lib[k]==nil then lib[k]=v end end
 for k,v in pairs(p.library.inventory or{})do if inv[k]==nil then inv[k]=v end end
end
local bundle=req('kernel.entry.client_domain_bundle')(f,{Utilities={Random=src.Vehicles.random}},lib,int,{translate=src.Work.translate,environment={print=function()end}})
local count=0
for name,p in pairs(bundle.domains)do count=count+1;assert(p.library==lib and p.config==nil and p.client==nil)
 -- Test-only native endpoint virtualizations; production187 selects foundation177.
 p.native=src[name].native
end
assert(count==23);r.ports.domains=bundle.domains
local graph=r.mount();assert(graph.IsCanonical()and graph.Client==r.client and #graph.Order==23)
assert(graph.Parts.Npcs.Session==graph.Parts.AutoMedic.Session.Session)
assert(graph.Parts.Settings.Menu==graph.Parts.Work.Menu)
print('PASS215 all23 real client domains constructed; canonical parent Menu/session/world; PR integration leaves explicit')
