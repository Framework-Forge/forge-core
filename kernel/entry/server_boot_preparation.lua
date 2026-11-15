-- Reuse169 approval/lifecycle gates with server208 options;no second seed167.
local create=require 'kernel.entry.boot_preparation'
local contract=require 'kernel.entry.server_boot_input_contract'
local createEntry=require 'kernel.entry.server_supported_entry'
return function(ports)
 assert(ports.side=='server','server preparation required')
 return create({side='server',contract=contract,inspectFunction=assert(ports.inspectFunction),providers=ports.providers,
  createRaw=assert(ports.createRaw),createEntry=function(raw,options)return createEntry(raw,options)end})
end
