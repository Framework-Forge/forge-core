-- Unified219 preparation:both sides use one179 foundation through208/218;never167.
local create=require 'kernel.entry.boot_preparation'
local contract=require 'kernel.entry.foundation_boot_input_contract'
local server=require 'kernel.entry.server_supported_entry'
local client=require 'kernel.entry.client_supported_entry'
return function(p)
 assert(p.side=='server'or p.side=='client','explicit boot side required')
 return create({side=p.side,contract=contract,inspectFunction=assert(p.inspectFunction),providers=p.providers,
  createRaw=assert(p.createRaw),createEntry=p.side=='server'and server or client})
end
