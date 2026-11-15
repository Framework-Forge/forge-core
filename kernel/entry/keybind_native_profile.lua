-- Attach installed keybinds to160 before Install;the same99 transport owns commands.
return function(base,ports)
 local seed=assert(ports.seed);assert(seed.IsCurrent(),'prepared seed required')
 if ports.side=='server'then return seed.Registry.Require('kernel.entry.progress_fenced_shutdown_profile')(base,ports)end
 assert(ports.side=='client','explicit keybind profile side required')
 local phase='allocating';local delegate,keys;local api={OperationalReady=false,Seed=seed}
 local function current()
  if phase=='closed'or not seed.IsCurrent()then return false end
  if delegate then local p=delegate.Progress().phase;if p=='closing'or p=='closed'then return false end end;return true
 end
 local function finish()if delegate and not delegate.Progress().complete then return false end
 if keys and not keys.Close()then return false end;phase='closed';return true end
 function api.Stop()if phase=='closed'then return true end;phase='closing'
 if keys then keys.CloseIngress()end;if delegate then delegate.Stop()end;return finish()end
 function api.Poll()
  if phase=='closed'then return true end
  if phase~='closing'and(not delegate or delegate.Progress().phase~='closing')then return false,'keybind_profile_not_stopping'end
  return api.Stop()
 end
 local ok,err=pcall(function()
  local p={};for k,v in pairs(ports)do p[k]=v end;p.bootstrap={};for k,v in pairs(assert(ports.bootstrap))do p.bootstrap[k]=v end
  local env={};for k,v in pairs(assert(ports.environment))do env[k]=v end
  local names={'RegisterKeyMapping','IsPauseMenuActive','GetControlInstructionalButton','joaat','Wait','SetTimeout','TriggerEvent'}
  for k,v in pairs(seed.Execution.Bind(names))do env[k]=v end
  local loadPR=assert(ports.loadPR)
  keys=loadPR('@pr_bridge/bridge/delivery/forge_client_keybinds_cleanup')({prCore=ports.prCore,environment=env,isCurrent=current,
   isCleanupCurrent=function()return phase~='closed'and seed.IsCurrent()end,
   public={nativeCommand=function(...)return assert(delegate,'profile not constructed').Bootstrap.Transport.Public.nativeCommand(...)end},
   running=assert(ports.running),onError=assert(ports.onError),load=loadPR,
   createTasks=loadPR('@pr_bridge/bridge/runtime/owned_tasks')});api.KeybindScope=keys
  p.bootstrap.context=seed.Registry.Require('kernel.entry.keybind_context_ports')(p.bootstrap.context,keys)
  delegate=seed.Registry.Require('kernel.entry.progress_fenced_shutdown_profile')(base,p)
  api.Delegate,api.Bootstrap,api.ProgressScope,api.DomainConfiguration=delegate,delegate.Bootstrap,delegate.ProgressScope,delegate.DomainConfiguration
 end)
 if not ok then api.Stop();error(err,0)end;phase='allocated'
 local function run(name,expected,nextPhase,...)
  if phase~=expected or not current()then return false,'keybind_profile_unavailable'end
  phase=name:lower()..'ing';local working=phase
  if name=='Install'then local opened,why=keys.Open();if not opened then api.Stop();return false,why end end
  local out=table.pack(pcall(delegate[name],...));if not out[1]then api.Stop();error(out[2],0)end
  if out[2]~=true or phase~=working or not current()then
   api.Stop()
   if out[2]~=true and out[3]~=nil then return table.unpack(out,2,out.n)end
   return false,'keybind_profile_cancelled'
  end
  phase=nextPhase;return table.unpack(out,2,out.n)
 end
 function api.Prepare(...)return run('Prepare','allocated','prepared',...)end
 function api.Install()return run('Install','prepared','installed')end
 function api.Start()return run('Start','installed','running')end
 function api.IsCurrent()return current()and delegate.IsCurrent()end
 function api.Progress()return{phase=phase,profile=delegate and delegate.Progress(),keys=keys and keys.Progress(),complete=phase=='closed',operationalReady=false}end
 return api
end
