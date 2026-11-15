--275: one server-generated epoch,replicated to all consumer contexts.
return function(e)
 local pr=assert(e.PRCore)
 if e.IsDuplicityVersion()and e.GetCurrentResourceName()=='forge-core'and not pr.forgeOperationalGeneration then
  local epoch=('forge:%s:%s'):format(e.os.time(),e.GetGameTimer())
  e.SetConvarReplicated('forge:bootGeneration',epoch);pr.forgeOperationalGeneration=epoch
 end
 local generation=e.GetConvar('forge:bootGeneration','')
 assert(generation~='','Forge activation generation missing')
 local data=pr.load('@forge-core/kernel/pr_integration/operational_profile_data',e)
 data.generation=generation;data.qbEnabled=e.GetConvar('qbx:enablebridge','true')=='true'
 local profile=pr.load('@forge-core/kernel/pr_integration/activation_profile',e)(data)
 if e.GetCurrentResourceName()=='forge-core'then
  -- The character flow supports native loading without this optional UI.
  -- Freeze this core-side boot set; never omit a missing mandatory provider.
  local side=e.IsDuplicityVersion()and'server'or'client'
  local consumers=profile.Consumers;local selected
  local inactive={missing=true,stopped=true,stopping=true}
  profile.Consumers=function(which)
   if which~=side then return consumers(which)end
   -- Reading profile/configuration alone must remain passive; select only on the core's explicit request.
   if not selected then
    selected={}
    for _,spec in ipairs(consumers(side))do
     if spec.name~='forge-loadscreen'or not inactive[e.GetResourceState(spec.name)]then selected[#selected+1]=spec end
    end
   end
   local out={};for i,spec in ipairs(selected)do local row={};for k,v in pairs(spec)do row[k]=v end;out[i]=row end
   return out
  end
 end
 return profile
end
