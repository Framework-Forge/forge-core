-- Fresh client state. Framework data arrives only through the existing owned session producer.
local createShared=require 'kernel.shared.main'
local weapons=require 'kernel.shared.weapons'
local locations=require 'kernel.shared.locations'
local function clone(value)
 if type(value)~='table'then return value end
 local out={};for k,v in pairs(value)do out[k]=clone(v)end;return out
end
return function(ports)
 local n,current=assert(ports.native),assert(ports.isCurrent)
 assert(n.GetCurrentResourceName()=='forge-core'and (not not n.IsDuplicityVersion())==false,'native client base required')
 local closed=false
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 assert(live(),'native client base unavailable')
 local state={PlayerData={},Shared=createShared({weapons=clone(weapons),locations=clone(locations)}),IsLoggedIn=false}
 local api={Base=state,OperationalReady=false}
 function api.IsCurrent()return live()end
 function api.Close()closed=true;return true end
 return api
end
