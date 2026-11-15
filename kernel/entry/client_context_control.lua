-- Explicit lifecycle gates;never infer readiness merely from construction.
return function(f,s,p)
 assert(f.Side=='client'and f.IsCurrent(),'client context foundation required')
 local rpc,services=assert(p.rpc),assert(p.services)
 assert(rpc.Side=='client','client RPC122 required')
 local owner,ready=assert(p.isCurrent),assert(p.isReady);local reg=assert(f.RegistrationInput)
 assert(type(owner)=='function'and type(ready)=='function','coordinator readiness functions required')
 local function current()return f.IsCurrent()and s.IsCurrent()and owner()==true end
 local function isReady()return current()and ready()==true and services.Progress().phase=='open'
  and rpc.Owners.native.IsReady()==true and rpc.Owners.ox.IsReady()==true end
 return{public={available=reg.available,publishExport=reg.native.publishExport,nativeCommand=reg.native.RegisterCommand,
  prCommand=reg.prCommand,oxCommand=reg.oxCommand,rpc=rpc.Owners.ox},
  callbacks={native=rpc.Owners.native,ox=rpc.Owners.ox},isCurrent=current,isReady=isReady,
  running=assert(p.running),onError=assert(p.onError)}
end
