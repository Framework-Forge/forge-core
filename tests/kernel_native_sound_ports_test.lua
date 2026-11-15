local S=dofile('tests/kernel_media_harness.lua');local C=dofile('tests/kernel_client_media_harness.lua');local H=S.H
local factory=H.load('../pr_bridge/bridge/delivery/forge_sound_ports.lua',H.environment())
for _,side in ipairs({'server','client'})do
 local r=side=='server'and S.provider()or C.provider()
 local n=side=='server'and{GetResourceState=r.ports.resourceState,TriggerClientEvent=r.ports.sendClient}or r.native
 local f={Side=side,IsCurrent=function()return r.current end}
 local a=factory({foundation=f,native=n,external={pr_3dsound=r.raw}})
 local p={};for k,v in pairs(a.Ports)do p[k]=v end
 if side=='client'then p.streaming=r.streaming;p.running=coroutine.running end
 local media=r.factory(p);assert(media.Open())
 if side=='server'then
  r.override=table.pack(nil,false,7)
  local out=table.pack(media.Audio.PlayNativeSound('test',2));assert(out.n==3 and out[2]==false and out[3]==7)
  media.ChatMessage(2,{args={'test'}});assert(r.events[#r.events].name=='chat:addMessage')
 else
  media.Audio.PlayLocalNativeSound({audioName='SELECT',audioRef='HUD_FRONTEND_DEFAULT_SOUNDSET'})
  assert(#r.trace>0)
 end
 a.Close();local method=side=='server'and'PlayNativeSound'or'PlayLocalNativeSound'
 assert(not pcall(a.Raw[method],a.Raw,'closed'));media.Close()
end
print('PASS194 installed server/client native_sound through PR ports;Cfx receiver,nil/false returns,legacy chat and revocation')
