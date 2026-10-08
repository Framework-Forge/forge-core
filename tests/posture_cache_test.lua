local H=dofile('tests/cache_harness.lua')
local s=H.new(true);local e=s.env
s.players[1]={PlayerData={citizenid='A',metadata={}}};s.players[2]={PlayerData={citizenid='B',metadata={}}}
s.players[3]={PlayerData={citizenid='C',metadata={}}};s.buckets[3]=1
s.load('shared/cache.lua');s.load('shared/session.lua');s.load('shared/sit.lua');s.load('shared/posture.lua')
s.load('server/callback_security.lua');s.load('server/posture.lua')
local C=e.ForgeCore.PostureContract
local sit={coords={x=1,y=0,z=0},heading=450,scenario='WORLD_HUMAN_SEAT_LEDGE',inPlace=true}
local anim=C.anims.male[1].base
local lean={coords={x=0,y=0,z=0},heading=0,dict=anim.dict,anim=anim.anim,looped=true}
assert(C.normalize('sit',sit));local _,normal=C.normalize('sit',sit);assert(normal.heading==90)
local bad=H.copy(sit);bad.coords.x=0/0;assert(not C.normalize('sit',bad))
bad=H.copy(lean);bad.dict='arbitrary';assert(not C.normalize('lean',bad))
bad=H.copy(sit);bad.inPlace='yes';assert(not C.normalize('sit',bad))
local begin=s.callbacks['forge-core:posture:begin']
local pub=s.callbacks['forge-core:posture:publish']
local snap=s.callbacks['forge-core:posture:snapshot']
local a=begin(1);assert(a.character=='A');local b=begin(2)
assert(snap(1,{2,3}));local other=snap(3,{2});assert(other.records[2].visible==false)
local ok,record=pub(2,b.token,1,{sit=sit,lean=false});assert(ok and record.data.sit)
assert(s.out[#s.out].target==1,'Only nearby viewers in the same bucket receive posture')
assert(not pub(1,b.token,1,{sit=sit}),'Cannot publish as a different player')
assert(not pub(2,b.token,1,{lean=lean}),'Sequence replay must be rejected')
assert(not pub(2,b.token,2,{sit=sit,lean=lean}))
bad=H.copy(sit);bad.coords.x=100;assert(not pub(2,b.token,2,{sit=bad}))
s.players[2].PlayerData.metadata.isdead=true;assert(not pub(2,b.token,2,{sit=sit}))
assert(pub(2,b.token,2,{sit=false,lean=false}),'Dead players must still be allowed to clear posture')
s.players[2].PlayerData.metadata.isdead=nil
assert(pub(2,b.token,3,{lean=lean}))
local oldRevision=e.exports['forge-core']:GetCachedPlayerPosture(2).revision
s.fire('pr_bridge:server:OnPlayerUnloaded',nil,2)
assert(not e.ForgeCore.Session.isLoaded(2) and not begin(2))
assert(not pub(2,b.token,4,{sit=sit}))
s.players[2]={PlayerData={citizenid='D',metadata={}}};s.fire('pr_bridge:server:OnPlayerLoaded',nil,2)
local d=begin(2);assert(d.character=='D' and d.token~=b.token)
assert(pub(2,d.token,1,{sit=sit}))
assert(e.exports['forge-core']:GetCachedPlayerPosture(2).revision>oldRevision)
assert(not pub(2,b.token,99,{lean=lean}),'Old character token cannot cross to the new one')

local c=H.new(false);local ce=c.env
c.data={citizenid='A',job={name='police',grade={level=2}},gang={name='none',grade=0}}
ce.ForgeCore.State={copy=H.copy};c.load('shared/session.lua');c.load('shared/sit.lua');c.load('shared/posture.lua')
ce.PlayerId=function() return 1 end
ce.GetActivePlayers=function() return {0,1} end
ce.GetPlayerServerId=function(player) return player==0 and 2 or 1 end
ce.GetPlayerPed=function(player) return player==0 and 22 or 11 end
ce.DoesEntityExist=function() return true end
ce.pr_lib.callback.await=function(name,_,...) return assert(s.callbacks[name])(1,...) end
local changes={};ce.AddEventHandler('forge-core:posture:changed',function(id,kind,value,rev)
    changes[#changes+1]={id=id,kind=kind,value=value,rev=rev}
end)
c.load('client/posture.lua');local P=ce.ForgeCore.Posture
assert(P.set('sit',sit));c.advance(100)
assert(e.exports['forge-core']:GetCachedPlayerPosture(1).data.sit,'Early local posture must survive the initial handshake')
c.advance(900);assert(#changes>0 and changes[#changes].id==2,'Remote player index zero is valid')
local latest=e.exports['forge-core']:GetCachedPlayerPosture(2)
local older=H.copy(latest);older.revision=older.revision-1;older.data={lean=lean}
c.fire('forge-core:posture:delta',65535,2,older)
assert(ce.exports['forge-core']:GetCachedPlayerPosture(2).data.sit,'Old delta cannot revert posture')
local spoof=H.copy(latest);spoof.revision=spoof.revision+100;spoof.data={lean=lean}
c.fire('forge-core:posture:delta',2,2,spoof);assert(ce.exports['forge-core']:GetCachedPlayerPosture(2).data.sit)
local invisible={generation=latest.generation,revision=latest.revision+100,visible=false,data={}}
c.fire('forge-core:posture:delta',65535,2,invisible);assert(not ce.exports['forge-core']:GetCachedPlayerPosture(2))
c.fire('forge-core:posture:delta',65535,2,latest);assert(ce.exports['forge-core']:GetCachedPlayerPosture(2).data.sit,'Visibility may return without another player mutation')
local refreshed=begin(2);assert(refreshed.token~=d.token and not pub(2,d.token,2,{lean=lean}))
s.fire('playerDropped',2);assert(not e.exports['forge-core']:GetCachedPlayerPosture(2))
c.fire('pr_bridge:client:OnPlayerUnloaded');assert(not P.set('lean',lean))
c.advance(1000);assert(not ce.exports['forge-core']:GetCachedPlayerPosture(2))
c.fire('onResourceStop',nil,'forge-core');s.fire('onResourceStop',nil,'forge-core')
assert(not e.pr_lib.cache.get('forge-core:posture:binding:1'))
print('PASS posture: validated catalog/coordinates, source/token/sequence isolation, death cleanup, observers/buckets, index zero, stale packets, visibility, logout/drop/stop')
