-- Real positional/kernel and named/domain translators. No framework selection or public registration.
return function(ports)
 local io,library,public=assert(ports.io),assert(ports.library),assert(ports.public)
 local loadPR,current=assert(ports.loadPR),assert(ports.isCurrent)
 local closed,pending=false,0;local api={OperationalReady=false}
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 local function guard(fn)return function(...)
  assert(live(),'native locale ports closed');pending=pending+1
  local out=table.pack(pcall(fn,...));pending=pending-1
  if not out[1]then error(out[2],0)end
  assert(live(),'native locale ports closed during call');return table.unpack(out,2,out.n)
 end end
 local function key()
  local record=assert(public.settings).get('locale')
  return type(record)=='table'and type(record.name)=='string'and record.name~=''and record.name or library.getLocaleKey()
 end
 local env={};for k,v in pairs(assert(ports.environment))do env[k]=v end
 env.PRBridgeLocale,env.Locale=nil,nil;env._G=env
 env.Bridge={settings=assert(public.settings)}
 env.LoadResourceFile=guard(assert(io.Files.LoadResourceFile))
 env.PRCore={loadJson=guard(assert(io.JSON.loadJson))}
 env.GetCurrentResourceName=guard(function()return'forge-core'end)
 env.GetInvokingResource=guard(function()return nil end)
 env.GetConvar=guard(assert(ports.getConvar));env.warn=guard(assert(library.print.warn))
 loadPR('@pr_bridge/bridge/locale',env)
 local domain=assert(env.Locale,'installed PR locale class required')
 local create=assert(loadPR('@pr_bridge/bridge/delivery/forge_locale'))
 api.DomainLocale=guard(function()return domain.init('forge-core')end)
 api.Ports={readFile=guard(io.Files.LoadResourceFile),decode=guard(assert(io.Codec.decode)),warn=env.warn,
  merge=guard(assert(library.table.merge)),wipe=guard(function(target)for k in pairs(target)do target[k]=nil end end),
  getLocaleKey=guard(key),pullLocale=guard(assert(ports.pullLocale)),running=assert(ports.running),isCurrent=live}
 api.CreateLocale=guard(function(input)
  local p={};for k,v in pairs(input)do p[k]=v end
  local owner=assert(p.isCurrent);p.isCurrent=function()return live()and owner()==true end
  return create(p)
 end)
 function api.IsCurrent()return live()end
 function api.Close()closed=true;return pending==0 end
 function api.Progress()return{closed=closed,pending=pending,complete=closed and pending==0,operationalReady=false}end
 return api
end
