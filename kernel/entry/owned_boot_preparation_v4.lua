-- Bind169 to208/225 and expose the same prepared identities to the trusted A-F coordinator.
local prepare=require 'kernel.entry.boot_preparation'
local contract=require 'kernel.entry.owned_boot_input_contract'
local server=require 'kernel.entry.server_supported_entry'
local client=require 'kernel.entry.client_owned_entry_v3'
local bindOrigin=require 'kernel.entry.origin_bound_entry'
return function(p)
 assert(p.side=='server'or p.side=='client','explicit boot side required')
 local origin=assert(p.originOwner,'pre-graph origin owner required')
 local raw,entry,barrier
 local api=prepare({side=p.side,contract=contract,inspectFunction=assert(p.inspectFunction),providers=p.providers,
  createRaw=function(options)raw=assert(p.createRaw)(options);return raw end,
  createEntry=function(r,options)
   assert(r==raw,'prepared raw identity changed')
   assert(origin.Owns(options),'prepared options do not own canonical origin')
   barrier=options.profile.barrier;entry=(p.side=='server'and server or client)(r,options)
   return bindOrigin(entry,origin)
  end})
 local stop=api.Stop
 function api.Stop()local done=stop();if not done then return false end;return origin.Close()end
 local progress,poll=api.Progress,api.Poll
 function api.Progress()
  local out=progress();out.origin=origin.Progress()
  if out.phase=='closed'and not out.origin.complete then out.phase='closing'end
  out.complete=out.complete==true and out.origin.complete==true;return out
 end
 function api.Poll()
  local phase=api.Progress().phase
  if phase~='closing'and phase~='closed'then return false,'candidate_not_stopping'end
  if poll()~=true then return false end;return origin.Close()
 end
 api.OriginOwner=origin
 local function prepared()local phase=api.Progress().phase;return phase=='prepared'or phase=='installed'or phase=='running'end
 function api.GetPreparedEntry()if not prepared()then return nil,'candidate_not_prepared'end;return entry end
 function api.GetPreparedRaw()if not prepared()then return nil,'candidate_not_prepared'end;return raw end
 function api.GetPreparedBarrier()if not prepared()then return nil,'candidate_not_prepared'end;return barrier end
 return api
end
