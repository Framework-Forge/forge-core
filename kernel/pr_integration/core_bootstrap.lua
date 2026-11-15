--272: resource-local PR primitives only;the Forge foundation owns callbacks/cache/settings.
return function(e)
 assert(e.GetCurrentResourceName()=='forge-core','core bootstrap belongs to forge-core')
 assert(e.GetResourceState('pr_bridge')=='started','pr_bridge must start before Forge')
 assert(rawget(e,'pr_lib')==nil and rawget(e,'Bridge')==nil,'full PR consumer bootstrap already loaded')
 local existing=rawget(e,'PRCore')
 assert(existing==nil or(existing.resource=='forge-core'and existing.forgeCoreBootstrap==nil),'foreign core bootstrap')
 local function chunk(path)
  local source=assert(e.LoadResourceFile('pr_bridge',path..'.lua'),'missing PR primitive:'..path)
  return assert(e.load(source,'@@pr_bridge/'..path..'.lua','t',e))()
 end
 if not existing then chunk('bridge/core')end
 local pr=assert(rawget(e,'PRCore'));assert(pr.forgeOwnedCallbacks==nil and not(pr.callback and pr.callback._transportInstalled),'legacy callbacks already installed')
 chunk('bridge/config');chunk('bridge/locale');chunk('bridge/debug')
 local public={name='pr_bridge',resource='forge-core',context=pr.context}
 for _,name in ipairs({'load','loadFile','loadJson','readJson','saveJson','writeJson','updateJson','mergeJson','deleteJson','jsonExists','loadJsonRecovery','saveJsonRecovery','saveJsonBatch','withJsonLock','jsonDraft','wrapJsonMutations','recordJsonIncident'})do public[name]=pr[name]end
 e.pr_lib,e.Bridge=public,public
 -- The explicit raw inventory/key providers use PR's translations during load.
 -- Loading the Locale class alone does not create that provider-local instance.
 e.Lang=e.Locale.init('pr_bridge')
 local api={Public=public,OperationalReady=false};pr.forgeCoreBootstrap=api
 return api
end
