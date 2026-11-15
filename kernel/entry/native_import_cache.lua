-- Native cache read view used by imports73/74. It never collects into the passive PR cache.
return function(ports)
 local n,current=assert(ports.native),assert(ports.isCurrent)
 assert(n.GetCurrentResourceName()=='forge-core','Forge native cache required')
 local server=n.IsDuplicityVersion();local closed,pending=false,0
 local values={resource='forge-core',game=assert(n.GetGameName)()}
 local stamp
 local function live()local ok,v=pcall(current);return not closed and ok and v==true end
 local function sample()
  assert(live(),'native cache closed')
  if server then return end
  local now=assert(n.GetGameTimer)();if stamp==now then return end
  local id,ped=assert(n.PlayerId)(),assert(n.PlayerPedId)()
  local nextValues={playerId=id,serverId=assert(n.GetPlayerServerId)(id)}
  -- Preserve the installed cache rule: ped=0 during a model transition does not replace the last valid context.
  if ped~=0 then
   local vehicle=assert(n.GetVehiclePedIsIn)(ped,false);local seat=false
   if vehicle>0 then
    for i=-1,assert(n.GetVehicleMaxNumberOfPassengers)(vehicle)-1 do
     if assert(n.GetPedInVehicleSeat)(vehicle,i)==ped then seat=i;break end
    end
   end
   local hasWeapon,weapon=assert(n.GetCurrentPedWeapon)(ped,true)
   nextValues.ped,nextValues.vehicle,nextValues.seat=ped,vehicle>0 and vehicle or false,seat
   nextValues.weapon=hasWeapon and weapon~=0 and weapon or false
   nextValues.coords=assert(n.GetEntityCoords)(ped);nextValues.interior=assert(n.GetInteriorFromEntity)(ped)
  end
  assert(live(),'native cache closed while reading')
  for k,v in pairs(nextValues)do values[k]=v end;stamp=now
 end
 local function read(fn,...)
  assert(live(),'native cache closed');pending=pending+1
  local out=table.pack(pcall(fn,...));pending=pending-1
  if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
 end
 local api={OperationalReady=false}
 api.Cache=setmetatable({resource='forge-core',game=values.game},{
  __index=function(_,key)return read(function()sample();return values[key]end)end,
  __newindex=function()error('native cache is read-only',0)end,__metatable=false})
 function api.Refresh()return read(function()stamp=nil;sample();local out={};for k,v in pairs(values)do out[k]=v end;return out end)end
 function api.IsCurrent()return live()end
 function api.Close()closed=true;return pending==0 end
 function api.Progress()return{closed=closed,pending=pending,complete=closed and pending==0,collector=false,operationalReady=false}end
 return api
end
