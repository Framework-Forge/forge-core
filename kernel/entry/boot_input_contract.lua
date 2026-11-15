-- Inspect native candidate inputs without invoking providers or reading game/player state.
local required={'base','bootstrap','public','nativeCache','events','domainLocale','locale','inventoryBridgeProbe','isCurrent','onError'}
local tables={base=true,bootstrap=true,public=true,nativeCache=true,events=true,barrier=true}
local api={OperationalReady=false}
function api.Describe(side)
 assert(side=='server'or side=='client','explicit boot side required')
 local out={};for i,k in ipairs(required)do out[i]={name=k,kind=tables[k]and'table'or'function'}end
 if side=='server'then out[#out+1]={name='barrier',kind='table'}end;return out
end
function api.Inspect(options,side,info)
 assert(type(info)=='function','function provenance inspector required');local schema=api.Describe(side)
 local issues,fixtures,functions,seen={},0,0,{}
 local function issue(path,reason,source)issues[#issues+1]={path=path,reason=reason,source=source}end
 if type(options)~='table'then issue('options','table_required');options={}end
 for _,s in ipairs(schema)do if type(rawget(options,s.name))~=s.kind then issue('options.'..s.name,s.kind..'_required')end end
 local function fn(t,key,path)if type(t)~='table'or type(rawget(t,key))~='function'then issue(path..'.'..key,'function_required')end end
 local b=rawget(options,'bootstrap')
 if type(b)=='table'then
  if type(rawget(b,'context'))~='table'then issue('options.bootstrap.context','table_required')end
  if type(rawget(b,'registration'))~='table'then issue('options.bootstrap.registration','table_required')end
  fn(b,'isCurrent','options.bootstrap');fn(b,'isReady','options.bootstrap')
 end
 local events=rawget(options,'events');for _,key in ipairs({'listen','remove','source','markNetwork'})do fn(events,key,'options.events')end
 local cache=rawget(options,'nativeCache');if type(cache)=='table'and rawget(cache,'resource')~='forge-core'then issue('options.nativeCache.resource','forge_resource_required')end
 if side=='server'then for _,k in ipairs({'WrapIngress','IsIngressOpen'})do fn(rawget(options,'barrier'),k,'options.barrier')end end
 local function visit(value,path)
  if type(value)=='function'then
   functions=functions+1;local ok,origin=pcall(info,value)
   local source=ok and type(origin)=='table'and origin.source
   if type(source)~='string'or source==''then issue(path,'function_origin_unknown')
   else
    source=source:gsub('\\','/'):gsub('^@+','');if source:find('/tests/',1,true)or source:sub(1,6)=='tests/'or source:find('harness',1,true)then fixtures=fixtures+1;issue(path,'test_provider',source)end
   end
  elseif type(value)=='table'and not seen[value]then
   seen[value]=true;for k,v in next,value do if type(k)=='string'or type(k)=='number'then visit(v,path..'.'..tostring(k))end end
  end
 end
 visit(options,'options');table.sort(issues,function(a,b)return a.path==b.path and a.reason<b.reason or a.path<b.path end)
 return{side=side,required=#schema,functions=functions,fixtures=fixtures,issues=issues,accepted=#issues==0,operationalReady=false,semanticReadinessProven=false}
end
return api
