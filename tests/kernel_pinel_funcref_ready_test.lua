local H=dofile('tests/kernel_harness.lua')
local f=assert(io.open('../../../[Scripts-para-remover]/pinel-admin/server/main.lua','rb'));local source=f:read('*a');f:close()
local prefix=assert(source:match('^(.-)Citizen%.CreateThread'))
for _,kind in ipairs({'function','cfx','missing','plain','fake-callable'})do
 local calls,now,waits=0,0,0
 local callback=kind=='function'and function()calls=calls+1 end or kind=='cfx'and setmetatable({__cfx_functionReference='virtual:ref'},
  {__call=function()calls=calls+1 end,__index=function()error('Cannot index a funcref')end})or kind=='plain'and{}or
  kind=='fake-callable'and setmetatable({},{__call=function()calls=calls+1 end})or nil
 local env=H.environment({Compat={CreateCallback=callback},GetConvarInt=function()return 50 end,
  GetGameTimer=function()return now end,Wait=function()waits=waits+1;now=now+25 end})
 env.lib={waitFor=H.load('../pr_bridge/bridge/utils/waitFor.lua',env)}
 local ok,why=pcall(assert(load(prefix,'@@pinel-admin/server/main.lua','t',env)))
 if kind=='function'or kind=='cfx'then assert(ok,tostring(why));assert(waits==0)
 else assert(not ok and waits==2 and tostring(why):find('compatibilidade',1,true))end
 assert(calls==0 and type(env.AdminPanel)=='table','readiness must not call a callback or defer AdminPanel allocation')
end
print('PASS Pinel ready for actual Cfx funcref tables and Lua functions; invalid/missing values time out; readiness passive')
