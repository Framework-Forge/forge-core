-- Registration/RPC and startup control;actual readiness is supplied by the coordinator,never inferred true.
return function(f,s,v,library,ports)
 assert(f.Side=='server'and f.IsCurrent(),'server context control required')
 local rpc=assert(ports.rpc);assert(rpc.Side=='server','server RPC owner required')
 local ready,owner=assert(ports.isReady),assert(ports.isCurrent)
 assert(type(ready)=='function'and type(owner)=='function','explicit coordinator readiness required')
 local reg=assert(f.RegistrationInput);local raw=assert(ports.services)
 local public={available=reg.available,publishExport=reg.native.publishExport,nativeCommand=reg.native.RegisterCommand,
  prCommand=reg.prCommand,oxCommand=reg.oxCommand,rpc=rpc.Owners.ox}
 local function current()return f.IsCurrent()and s.IsCurrent()and owner()==true end
 local function isReady()return current()and ready()==true and raw.Progress().phase=='open'and v.Database.IsReady()==true end
 local native=f.EngineInputs.Select({'wait','setTimeout','CreateThread'})
 return {public=public,callbacks={native=rpc.Owners.native,ox=rpc.Owners.ox,securityLibrary=library},
  bootstrap={library=library,native=native,debugEnabled=assert(ports.config).Debug},
  isCurrent=current,isReady=isReady,databaseReady=v.Database.IsReady,resourceState=f.Seed.Execution.Bind({'GetResourceState'}).GetResourceState,
  running=assert(ports.running),onError=assert(ports.onError)}
end
