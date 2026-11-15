local T=dofile('tests/kernel_native_foundation_harness.lua');local req=T.loader();local f=req('kernel.entry.native_import_cache')
local r=T.basePorts(false);local n=r.native;local now,ped,vehicle,seat,reads=1,20,30,0,0
n.GetGameName=function()return'fivem'end;n.GetGameTimer=function()return now end
n.PlayerId=function()return 5 end;n.PlayerPedId=function()reads=reads+1;return ped end;n.GetPlayerServerId=function()return 7 end
n.GetVehiclePedIsIn=function()return vehicle end;n.GetVehicleMaxNumberOfPassengers=function()return 3 end
n.GetPedInVehicleSeat=function(_,i)return i==seat and ped or 0 end
n.GetCurrentPedWeapon=function()return true,123 end;n.GetEntityCoords=function()return{x=1,y=2,z=3}end;n.GetInteriorFromEntity=function()return 9 end
local a=f(r.ports);assert(a.Cache.game=='fivem'and a.Cache.ped==20 and a.Cache.vehicle==30 and a.Cache.seat==0 and a.Cache.weapon==123)
assert(reads==1 and a.Cache.playerId==5 and a.Cache.serverId==7)
now=2;ped=0;assert(a.Cache.ped==20 and a.Cache.vehicle==30)
now=3;ped=40;vehicle=0;n.GetCurrentPedWeapon=function()return false,0 end
assert(a.Cache.ped==40 and a.Cache.vehicle==false and a.Cache.seat==false and a.Cache.weapon==false)
assert(not pcall(function()a.Cache.ped=99 end));local s=a.Refresh();s.ped=88;assert(a.Cache.ped==40)
assert(#r.events==0 and #r.writes==0 and a.Progress().collector==false)
a.Close();assert(not pcall(function()return a.Cache.ped end))
local server=T.basePorts(true);server.native.GetGameName=function()return'fxserver'end
local b=f(server.ports);assert(b.Cache.game=='fxserver'and b.Cache.ped==nil);b.Close()
local c=f(r.ports);now=4;n.GetEntityCoords=function()c.Close();return{}end;assert(not pcall(function()return c.Cache.ped end))
print('PASS174 native read cache;single sample per tick,ped=0 transition,seat/weapon,false values,server isolation and close-during-read')
