local T=dofile('tests/kernel_native_foundation_harness.lua');local req=T.loader();local f=req('kernel.entry.native_boot_foundation')
local S=dofile('tests/kernel_native_seed_harness.lua');local R=dofile('tests/kernel_native_registration_harness.lua')
for _,side in ipairs({'server','client'})do
 local r=S.unit(side);local p=r.seedPorts;local reg=R.new(side);local env=p.environment
 env.table.type=T.H.tableType;env.GetResourceKvpString=function()return nil end;env.load=load
 local convars,removed={},0
 env.AddConvarChangeListener=function(pattern,fn)local token={pattern=pattern,fn=fn};convars[#convars+1]=token;return token end
 local refuseRemoval=false
 env.RemoveConvarChangeListener=function()if refuseRemoval then return false end;removed=removed+1 end
 p.native.GetGameName=function()return side=='server'and'fxserver'or'fivem'end
 for _,name in ipairs({'AddEventHandler','RemoveEventHandler','RegisterNetEvent','RegisterCommand'})do p.native[name]=reg.native[name]end
 p.native.TriggerEvent=function()error('no event should emit during foundation construction')end
 p.native.TriggerClientEvent=p.native.TriggerEvent
 p.native.LoadResourceFile=function(resource,path)
  assert(resource=='forge-core');local file=io.open(path,'rb');if not file then return nil end;local s=file:read('*a');file:close();return s
 end
 p.side=side;p.registration={running=coroutine.running,getSource=reg.native.source,publishExport=reg.native.publishExport,
 available=reg.ports.available,prCommand=reg.ports.prCommand,oxCommand=reg.ports.oxCommand}
 p.pullLocale=function(resource,key)return resource..':'..key end
 p.adjuncts={time=os.time,date=os.date,newPromise=function()return{}end,awaitPromise=function(value)return value end}
 local a=f(p);assert(a.IsCurrent()and a.Base.Shared and a.Seed.Library.Cache~=a.NativeCache.Cache)
 assert(r.wire.prs[side].forgeNativeFoundation==a and r.wire.prs[side].forgeOwnedCallbacks==p.rpc)
 assert(reg.calls==0 and #convars==0 and a.Progress().bootstrapGraphBuilt==false)
 assert(a.Progress().convarQueued==1 and a.OpenObservers()==false)
 if side=='server'then assert(a.Base.Groups.Callbacks['qbx_core:server:getGroups']().jobs.unemployed)else assert(next(a.Base.PlayerData)==nil)end
 assert(a.DomainLocale():t('automedic.beds_title')~='automedic.beds_title')
 assert(not pcall(a.Locale,'error.not_online'));assert(not pcall(f,p))
 local input={};for k,v in pairs(a.Locales.Ports)do input[k]=v end;input.resource,input.path='forge-core','kernel/locales'
 local locale=a.Locales.CreateLocale(input);locale.Initialize('en')
 local transport=reg.factory(reg.spec,a.RegistrationInput)
 local complete=false;local boot={Side=side,Transport=transport,Context={Locale=locale},Progress=function()return{complete=complete}end}
 assert(a.BindBootstrap(boot));assert(a.Locale('error.not_online')=='Player not online');assert(a.Close()==false and a.IsCurrent())
 assert(transport.Open());assert(a.OpenObservers());assert(a.OpenObservers()and #convars==1)
 assert(transport.Close());locale.Close();complete=true
 refuseRemoval=true;assert(a.Close()==false and a.Progress().convarActive==1 and not a.IsCurrent())
 assert(r.wire.prs[side].forgeNativeSeed==a.Seed,'seed must remain owned until observer removal')
 refuseRemoval=false;assert(a.Poll());assert(a.Progress().complete and not a.IsCurrent())
 assert(r.wire.prs[side].forgeNativeFoundation==nil and r.wire.prs[side].forgeNativeSeed==nil and removed==1)
 assert(r.wire.prs[side].forgeOwnedCallbacks==p.rpc,'borrowed raw callback owner closed')
 r.finishSeed()
end
print('PASS179 native foundation integrates real130/171-178 on both sides;canonical locale/event binding;drain before dependency release;raw RPC borrowed')
