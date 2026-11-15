--241: one caller scope injected before graph construction;borrowed by compatibility after Prepare.
local createOrigin=require 'kernel.compat.qbx.call_origin'
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(p)
 local closed=false;local bound={};local api={OperationalReady=false}
 local origin=createOrigin({running=assert(p.running),getInvokingResource=assert(p.getInvokingResource),
  isCurrent=function()return not closed and p.isCurrent()==true end})
 api.Origin=origin
 function api.Bind(options)
  assert(not closed and p.isCurrent()==true,'activation origin unavailable')
  assert(not options.ActivationOrigin,'origin already supplied')
  local input=assert(options.foundation.native)
  assert(input.GetInvokingResource==p.getInvokingResource,'native caller source mismatch')
  assert(options.support.native==input and options.providers.native==input,'native input ownership mismatch')
  local native=copy(input);native.GetInvokingResource=origin.GetInvokingResource
  local out=copy(options);out.foundation=copy(options.foundation);out.support=copy(options.support);out.providers=copy(options.providers)
  out.foundation.native,out.support.native,out.providers.native=native,native,native
  -- The marker is consumed by the entry wrapper,not part of the old closed input contract.
  bound[out]=true;return out
 end
 function api.Owns(options)
  return not closed and bound[options]==true and options.foundation.native.GetInvokingResource==origin.GetInvokingResource
   and options.support.native==options.foundation.native and options.providers.native==options.foundation.native
 end
 function api.IsCurrent()return not closed and origin.IsCurrent()end
 function api.Close()closed=true;return origin.Close()end
 function api.Progress()return origin.Progress()end
 return api
end
