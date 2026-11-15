-- Compose native leaf builders into complete structural100/101 input. Never import a test scaffold.
local clientTree=require 'kernel.entry.native_client_context_tree'
local serverTree=require 'kernel.entry.native_server_context_tree'
local clientCentral=require 'kernel.entry.native_client_central_ports'
local serverCentral=require 'kernel.entry.native_server_central_ports'
local domains=require 'kernel.entry.native_domain_ports'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(foundation,ports)
 assert(foundation.IsCurrent(),'prepared foundation required for bootstrap builder')
 local config=assert(ports.config,'native domain config required');assert(type(config)=='table','native domain config table required')
 local input=copy(assert(ports.context,'native context providers required'))
 local d=copy(assert(ports.domain,'native domain providers required'))
 local views,audit=domains(foundation,d)
 if foundation.Side=='client'then
  local c=copy(assert(ports.central));c.config=copy(c.config);c.config.Inventory=config.Inventory
  assert(c.config.Client==nil,'client70 must own Client configuration')
  input.central=clientCentral(foundation,c)
  input.domains={client={},config=config,domains=views}
  return clientTree(foundation,input),audit
 end
 assert(foundation.Side=='server','native bootstrap side required')
 local c=serverCentral(foundation,assert(ports.central))
 local helpers=copy(assert(ports.helpers,'native server helpers required'))
 for _,name in ipairs({'isServer','shared','functions'})do assert(helpers[name]==nil,'assembly owns helper '..name)end
 input.graph={config=config,central=c,domains=views,helpers=helpers,isReady=assert(input.isReady)}
 return serverTree(foundation,input),audit
end
