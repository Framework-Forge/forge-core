-- Pure226 input inspection for208/225. No base/cache/seed may be supplied for adoption.
local api={OperationalReady=false}
function api.Inspect(options,side,info)
 local issues,seen={},{};local functions,fixtures=0,0
 local function issue(path,reason,source)issues[#issues+1]={path=path,reason=reason,source=source}end
 if side~='server'and side~='client'then issue('side','invalid_side')end
 if type(options)~='table'then options={};issue('options','table_required')end
 local function at(path)
  local value=options;for key in path:gmatch('[^.]+')do value=type(value)=='table'and rawget(value,key)or nil end;return value
 end
 local fields={prCore='table',isCurrent='function',foundation='table',support='table',profile='table',providers='table',
  ['foundation.native']='table',['foundation.environment']='table',['foundation.registration']='table',
  ['foundation.registration.available']='function',['foundation.compile']='function',['foundation.json']='table',
  ['foundation.public']='table',['foundation.loadPR']='function',['foundation.pullLocale']='function',
  ['foundation.inventoryBridgeProbe']='function',['foundation.adjuncts']='table',['foundation.running']='function',
  ['support.native']='table',['support.environment']='table',['support.external']='table',['support.loadPR']='function',
  ['support.running']='function',['support.onError']='function',['providers.native']='table',['providers.environment']='table',
  ['providers.external']='table',['providers.loadPR']='function',['providers.isCurrent']='function',
  ['providers.isReady']='function',['providers.running']='function',['providers.onError']='function',
  ['profile.environment']='table',['profile.external']='table',['profile.loadPR']='function',['profile.barrier']='table',
  ['profile.barrier.WrapIngress']='function',['profile.barrier.IsIngressOpen']='function',
  ['profile.nativeAdjuncts']='table',['profile.running']='function',['profile.onError']='function',
  ['bootstrap.registration.available']='function'}
 for name,kind in pairs(fields)do if type(at(name))~=kind then issue('options.'..name,kind..'_required')end end
 if at('foundation.side')~=side then issue('options.foundation.side','side_mismatch')end
 for _,name in ipairs({'base','seed','nativeCache','events','bootstrap.context','buildProviders'})do
  if at(name)~=nil then issue('options.'..name,'legacy_or_duplicate_foundation_input')end
 end
 if at('foundation.registration.available')~=at('bootstrap.registration.available')then issue('options.bootstrap.registration.available','raw_namespace_identity_mismatch')end
 for _,name in ipairs({'support','providers'})do
  for _,key in ipairs({'native','environment','loadPR'})do
   if at(name..'.'..key)~=at('foundation.'..key)then issue('options.'..name..'.'..key,'foundation_provider_identity_mismatch')end
  end
 end
 if side=='client'then
  if at('providers.prCore')~=at('prCore')then issue('options.providers.prCore','PR_owner_identity_mismatch')end
  if at('providers.targetSelection')~='native'then issue('options.providers.targetSelection','explicit_native_target_required')end
  if at('providers.capabilities')~=nil then issue('options.providers.capabilities','capabilities_owned_by_entry225')end
  for path,kind in pairs({['profile.progress']='table',['profile.progress.localPlayer']='table',
   ['profile.progress.settings']='table',['profile.progress.settings.get']='function',['providers.native.ExecuteCommand']='function'})do
   if type(at(path))~=kind then issue('options.'..path,kind..'_required')end
  end
  if at('profile.progress.localPlayer.state')==nil then issue('options.profile.progress.localPlayer.state','existing_state_required')end
  if at('profile.progress.settings')~=at('foundation.public.settings')then issue('options.profile.progress.settings','settings_identity_mismatch')end
 end
 local function visit(value,path)
  if type(value)=='function'then
   functions=functions+1;local ok,origin=pcall(info,value);local source=ok and type(origin)=='table'and origin.source
   if type(source)~='string'or source==''then issue(path,'function_origin_unknown')
   else source=source:gsub('\\','/'):gsub('^@+','')
    if source:sub(1,6)=='tests/'or source:find('/tests/',1,true)or source:find('harness',1,true)then
     fixtures=fixtures+1;issue(path,'test_provider',source)
    end
   end
  elseif type(value)=='table'and not seen[value]then seen[value]=true
   for k,v in next,value do if type(k)=='string'or type(k)=='number'then visit(v,path..'.'..tostring(k))end end
  end
 end
 visit(options,'options');table.sort(issues,function(a,b)return a.path==b.path and a.reason<b.reason or a.path<b.path end)
 return{side=side,functions=functions,fixtures=fixtures,issues=issues,accepted=#issues==0,operationalReady=false,semanticReadinessProven=false}
end
return api
