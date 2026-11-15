-- Explicit domain views. Assemblies48/50 retain all state/config/session/group ownership.
local client={'Jobs','Zones','Administration','Work','MultiJob','Staff','Skills','SkillMenus','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
local server={'MultiJob','Staff','Skills','AutoMedic','Access','Settings','World','Vehicles','Vinewood','Objects','Npcs','Spotlights','Billboards','Stores','Farms','Starterpack','PlayerAdmin','CharacterAdmin'}
local function copy(t)local out={};for k,v in pairs(t)do out[k]=v end;return out end
return function(foundation,ports)
 assert(foundation.IsCurrent(),'native domain foundation required')
 local side=foundation.Side;assert(side=='server'or side=='client','domain side required')
 local names=side=='client'and client or server
 local selected,known={},{};for _,e in ipairs(foundation.EngineInputs.Describe())do selected[#selected+1]=e.name;known[e.name]=true end
 local native=foundation.EngineInputs.Select(selected)
 local out,audit={},{}
 for _,name in ipairs(names)do
  local source=assert(ports.domains[name],'native domain input required:'..name);assert(type(source)=='table','native domain table required:'..name)
  local owned=side=='client'and{'client','menu','config','shared','world','session','playerAccess','groups','isReady','notifyPosition','debugEnabled'}or{'config'}
  for _,key in ipairs(owned)do assert(source[key]==nil,'domain assembly owns '..name..'.'..key)end
  if side=='server'and(name=='Skills'or name=='Vehicles'or name=='Farms'or name=='CharacterAdmin')then
   for _,key in ipairs({'isReady','coreState','slotPolicy'})do assert(source[key]==nil,'domain assembly owns '..name..'.'..key)end
  end
  local p=copy(source);p.library=assert(ports.libraries[name],'native domain library required:'..name)
  assert(type(p.library)=='table','native domain library table required:'..name)
  p.native=copy(assert(source.native,'explicit native domain ports required:'..name))
  for key,value in pairs(p.native)do if type(value)=='function'and not known[key]then audit[#audit+1]={domain=name,name=key,kind='explicit-unmapped'}end end
  for key,value in pairs(native)do p.native[key]=value end
  if p.json~=nil then p.json=foundation.Seed.IO.Codec end
  out[name]=p
 end
 return out,{side=side,domains=#names,remaining=audit,operationalReady=false}
end
