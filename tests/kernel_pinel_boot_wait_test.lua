local H=dofile('tests/kernel_harness.lua')
local file=assert(io.open('../../../[Scripts-para-remover]/pinel-admin/server/main.lua','rb'))
local source=file:read('*a');file:close()
local prefix=assert(source:match('^(.-)Citizen%.CreateThread'))
for _,ready in ipairs({true,false})do
 local now,waits=0,0
 local env=H.environment({GetConvarInt=function(key,default)assert(key=='forge:activationTimeout');return 50 end,
  GetGameTimer=function()return now end})
 getmetatable(env).__index=function(_,key)if key=='Compat'then return nil end;error('unexpected boundary: '..key)end
 env.Wait=function()now=now+25;waits=waits+1;if ready and waits==2 then env.Compat={CreateCallback=function()end}end end
 env.lib={waitFor=H.load('../pr_bridge/bridge/utils/waitFor.lua',env)}
 local ok,why=pcall(assert(load(prefix,'@@pinel-admin/server/main.lua','t',env)))
 assert(type(env.AdminPanel)=='table'and waits==2,'publish table before bounded readiness wait')
 if ready then assert(ok)else assert(not ok and tostring(why):find('compatibilidade',1,true))end
end
print('PASS Pinel boot: real PR wait pauses until actual Compat, publishes AdminPanel early and refuses bounded timeout')
