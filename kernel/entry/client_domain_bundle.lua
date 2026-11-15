-- Complete23-domain input; assembly50 owns Menu/session/world/groups and all state.
local names={'Jobs','Zones','Administration','Work','MultiJob','Staff','Skills','SkillMenus','AutoMedic','Access','Settings','World',
 'Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
return function(f,s,library,integrations,p)
 assert(f.Side=='client'and f.IsCurrent(),'client domain foundation required')
 local out,libraries={},{};local codec=f.Seed.IO.Codec
 for _,name in ipairs(names)do out[name]={native={},library=library,translate=assert(p.translate),json=codec};libraries[name]=library end
 out.Jobs.wait=f.Seed.Execution.Native.Wait
 out.Zones.integrations=assert(integrations.Zones)
 out.Work.integrations=assert(integrations.Work)
 out.Skills.progression=assert(integrations.Progression)
 out.Access.characterIntegration=assert(integrations.Access)
 out.Settings.panelIntegration=assert(integrations.Panel)
 out.World.weatherAdminIntegration=assert(integrations.Weather)
 out.Npcs.integration=assert(integrations.Npcs)
 out.Vehicles.random=assert(s.Utilities.Random)
 out.Farms.math=assert(library.math)
 out.Starterpack.print=assert(p.environment.print)
 return{domains=out,libraries=libraries}
end
