--254: fail before registration if a required compatibility leaf is unavailable.
local required={server={"table.merge","math.groupdigits","string.random","print.debug","print.error","print.info","print.warn","addCommand"},client={"table.merge","math.groupdigits","string.random","print.debug","print.warn","print.verbose","showTextUI","hideTextUI","requestModel","requestAnimDict","requestAnimSet","requestNamedPtfxAsset","playAnim","progressBar","getClosestPlayer","getNearbyPlayers","getNearbyVehicles","getVehicleProperties"}}
return function(library,side)
 local names=assert(required[side]);local count=0
 for _,path in ipairs(names)do
  local value=library;for key in path:gmatch('[^.]+')do value=type(value)=='table'and value[key]or nil end
  assert(type(value)=='function','compatibility library method missing:'..path);count=count+1
 end
 return count
end
