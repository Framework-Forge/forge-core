--252: borrowed provider methods;asset aliases use the same owned UI streaming module.
return function(entry,side)
 local providers=assert(entry.Providers);assert(providers.IsCurrent(),'prepared provider library required')
 local source=assert(providers.Library);local library={};for k,v in pairs(source)do library[k]=v end
 if side=='client'then
  local ui=assert(entry.ClientUI,'canonical client UI required')
  for alias,name in pairs({requestAnimSet='requestAnimSet',requestNamedPtfxAsset='requestPtfxAsset'})do
   library[alias]=function(asset,timeout)
    assert(entry.IsCurrent()and providers.IsCurrent()and entry.ClientUI==ui,'compatibility library expired')
    assert(ui.Progress().phase=='open','canonical streaming not open')
    local ok,value=assert(ui.Streaming[name])(asset,timeout or 30000)
    assert(ok,'asset request failed:'..tostring(asset));return value or asset
   end
  end
 end
 return library
end
