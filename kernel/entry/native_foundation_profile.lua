-- Borrow the one prepared179 foundation. Never allocate a second seed,base or RPC owner.
return function(foundation,ports)
 assert(foundation.IsCurrent(),'prepared native foundation required')
 local seed,base=assert(foundation.Seed),assert(foundation.Base)
 local side=assert(ports.side);assert(side==foundation.Side,'foundation/profile side mismatch')
 local pr=assert(ports.prCore);assert(pr.forgeNativeSeed==seed and pr.forgeNativeFoundation==foundation,'canonical foundation required')
 assert(pr.forgeOwnedCallbacks==ports.rpc,'canonical RPC owner required')
 local phase='allocating';local delegate;local api={Foundation=foundation,Seed=seed,OperationalReady=false}
 local function current()return phase~='closed'and phase~='closing'and foundation.IsCurrent()end
 local function finish()
  if delegate and not delegate.Progress().complete then return false end
  if not foundation.Close()then return false end;phase='closed';return true
 end
 function api.Stop()
  if phase=='closed'then return true end;phase='closing'
  if delegate then delegate.Stop()end;return finish()
 end
 function api.Poll()
  if phase=='closed'then return true end
  if phase~='closing'then return false,'foundation_profile_not_stopping'end
  if delegate then delegate.Poll()end;return finish()
 end
 local ok,problem=pcall(function()
  local p={};for k,v in pairs(ports)do p[k]=v end
  p.seed,p.public=seed,foundation.Public
  p.bootstrap={};for k,v in pairs(assert(ports.bootstrap))do p.bootstrap[k]=v end
  p.bootstrap.registration=foundation.RegistrationInput
  local owner=assert(p.bootstrap.isCurrent)
  p.bootstrap.isCurrent=function()return current()and owner()==true end
  p.domainConfigurationPorts={getConvar=seed.Execution.Native.GetConvar,
   vec3=seed.Execution.Bind({'vec3'}).vec3,locale=foundation.DomainLocale}
  p.nativeAdjuncts={};for k,v in pairs(assert(ports.nativeAdjuncts))do p.nativeAdjuncts[k]=v end
  p.nativeAdjuncts.locale=foundation.Locale
  delegate=seed.Registry.Require('kernel.entry.keybind_native_profile')(base,p)
  api.Delegate,api.Bootstrap=delegate,delegate.Bootstrap
  assert(foundation.BindBootstrap(delegate.Bootstrap),'foundation bootstrap binding refused')
 end)
 if not ok then api.Stop();error(problem,0)end;phase='allocated'
 local function run(name,expected,target,...)
  if phase~=expected or not current()then return false,'foundation_profile_unavailable'end
  local active=name:lower()..'ing';phase=active
  local out=table.pack(pcall(delegate[name],...))
  if not out[1]then api.Stop();error(out[2],0)end
  if out[2]~=true or phase~=active or not current()then
   local reason=out[3]or'foundation_profile_cancelled';api.Stop();return false,reason
  end
  if name=='Install'then
   local ok,value,reason=pcall(foundation.OpenObservers)
   if not ok or value~=true then api.Stop();return false,ok and reason or value end
  end
  phase=target;return table.unpack(out,2,out.n)
 end
 function api.Prepare(...)return run('Prepare','allocated','prepared',...)end
 function api.Install()return run('Install','prepared','installed')end
 function api.Start()return run('Start','installed','running')end
 function api.IsCurrent()return current()and delegate.IsCurrent()end
 function api.Progress()return{phase=phase,profile=delegate and delegate.Progress(),foundation=foundation.Progress(),complete=phase=='closed',operationalReady=false}end
 return api
end
