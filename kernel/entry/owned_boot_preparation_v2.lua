-- Bind169 to208/225 and expose the same prepared identities to the trusted A-F coordinator.
local prepare=require 'kernel.entry.boot_preparation'
local contract=require 'kernel.entry.owned_boot_input_contract'
local server=require 'kernel.entry.server_supported_entry'
local client=require 'kernel.entry.client_owned_entry_v2'
return function(p)
 assert(p.side=='server'or p.side=='client','explicit boot side required')
 local raw,entry,barrier
 local api=prepare({side=p.side,contract=contract,inspectFunction=assert(p.inspectFunction),providers=p.providers,
  createRaw=function(options)raw=assert(p.createRaw)(options);return raw end,
  createEntry=function(r,options)
   assert(r==raw,'prepared raw identity changed')
   barrier=options.profile.barrier;entry=(p.side=='server'and server or client)(r,options);return entry
  end})
 local function prepared()local phase=api.Progress().phase;return phase=='prepared'or phase=='installed'or phase=='running'end
 function api.GetPreparedEntry()if not prepared()then return nil,'candidate_not_prepared'end;return entry end
 function api.GetPreparedRaw()if not prepared()then return nil,'candidate_not_prepared'end;return raw end
 function api.GetPreparedBarrier()if not prepared()then return nil,'candidate_not_prepared'end;return barrier end
 return api
end
