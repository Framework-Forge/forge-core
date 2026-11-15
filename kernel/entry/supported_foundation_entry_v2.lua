--189 with concrete198 common providers. Raw125 and179 remain the only service/seed owners.
local createEntry=require 'kernel.entry.native_foundation_entry'
local createSupport=require 'kernel.entry.native_context_support_v2'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(raw,ports)
 local delegate,support;local api={OperationalReady=false}
 local input=copy(ports);local build=assert(ports.buildProviders,'central/domain provider builder required')
 input.buildProviders=function(foundation,services)
  local close=foundation.Close
  -- Install the finalizer before any provider construction;an accepted HTTP keeps the seed alive.
  foundation.Close=function()
   if support and not support.Close()then return false,'context_support_not_drained'end
   return close()
  end
  local sp=copy(assert(ports.support,'concrete context support ports required'))
  sp.prCore,sp.services=ports.prCore,services
  support=createSupport(foundation,sp);api.Support=support
  local built=build(foundation,services,support)
  assert(type(built)=='table','native provider bundle required')
  local bundle=copy(built)
  bundle.context=support.Context(assert(bundle.context,'remaining context control ports required'))
  return bundle
 end
 delegate=createEntry(raw,input);api.Entry=delegate
 function api.Prepare(...)
  local result=table.pack(delegate.Prepare(...))
  api.Foundation,api.Profile,api.Bootstrap=delegate.Foundation,delegate.Profile,delegate.Bootstrap
  return table.unpack(result,1,result.n)
 end
 function api.Install()
  local result=table.pack(delegate.Install());if result[1]~=true then return table.unpack(result,1,result.n)end
  local ok,value,reason=pcall(support.Open)
  if not ok or value~=true then delegate.Stop();return false,ok and reason or value end
  return table.unpack(result,1,result.n)
 end
 function api.Start()return delegate.Start()end
 function api.Stop()return delegate.Stop()end
 function api.Poll()return delegate.Poll()end
 function api.IsCurrent()return delegate.IsCurrent()end
 function api.Progress()return{entry=delegate.Progress(),support=support and support.Progress(),
  complete=delegate.Progress().complete,operationalReady=false}end
 return api
end
