local f=assert(io.open('../../../../.planning/migration/staging/277/qbx_core/compat/main.lua','rb'));local text=f:read('*a');f:close()
for _,side in ipairs({'server','client'})do
 local stage,now,thread=0,0;local caller='test-consumer';local published={};local hits=0;local stop
 local namesFile=assert(io.open('../../../../.planning/migration/staging/277/qbx_core/compat/export_names.lua','rb'));local namesSource=namesFile:read('*a');namesFile:close()
 local names=assert(load(namesSource))()[side]
 local proxy={ForgeRuntimeStatus=function()return{generation='test277',stage=stage,ingressOpen=stage==6}end,
 ForgeQbxCompatDescribe=function()return{protocol='forge-qbx-compat/1',authority='forge-core',side=side,generation='test277',names=names}end,
 ForgeQbxCompatQBDescribe=function()return{protocol='forge-qbx-qb/1',side=side,generation='test277',setField=side=='server'}end,
 ForgeQbxCompatCall=function(_,g,n,c,...)hits=hits+1;assert(g=='test277'and c==caller);return n,... end}
 local env=setmetatable({GetCurrentResourceName=function()return'qbx_core'end,IsDuplicityVersion=function()return side=='server'end,
 GetInvokingResource=function()return caller end,LoadResourceFile=function()return namesSource end,
 GetConvarInt=function()return 1000 end,GetConvar=function()return'true'end,GetGameTimer=function()return now end,
 Wait=function()now=now+25;coroutine.yield()end,
 CreateThread=function(fn)thread=coroutine.create(fn)end,AddEventHandler=function(_,fn)stop=fn;return 1 end,
 exports=setmetatable({['forge-core']=proxy},{__call=function(_,name,fn)assert(not published[name]);published[name]=fn end})},{__index=_G})
 assert(load(text,'@@qbx_core/compat/main.lua','t',env))()
 assert(type(published.GetJobs)=='function'and hits==0)
 assert(coroutine.resume(thread));assert(coroutine.status(thread)=='suspended')
 stage=4;assert(coroutine.resume(thread));assert(coroutine.status(thread)=='dead')
 assert(published.GetJobs()=='GetJobs'and hits==1)
 local method=side=='server'and'GetPlayer'or'GetPlayerData'
 local pending=coroutine.create(function()return published[method](12)end);assert(coroutine.resume(pending));assert(hits==1)
 stage=6;local ok,name,id=coroutine.resume(pending);assert(ok and name==method and id==12 and hits==2)
 stop('forge-core');assert(not pcall(published.GetJobs))
end
print('PASS277 early QBX exports105/24;exact gateway contract;captured caller;common calls wait commit;stop revokes')
