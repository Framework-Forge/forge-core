-- Original QBX vs Forge connection -> RPC -> actual storage/slots -> character menu.
-- SQL execution/data, Cfx network scheduling, UI and rendering are virtual.
local C=dofile('tests/kernel_character_harness.lua');local H,P=C.H,C.P
local L=dofile('tests/kernel_lifecycle_harness.lua');local F=dofile('tests/kernel_character_flow_harness.lua')
local T=dofile('tests/kernel_owned_rpc_harness.lua')
local function account(ported,scenario)
 local r=C.slots(ported,function(r)
  local ids={license2='license2:account',license='license:account'}
  if scenario=='license-only'then ids.license2=nil end
  if scenario=='license2-only'then ids.license=nil end
  if scenario=='no-identifier'then ids={}end
  r.ids=ids;r.sql={};r.accounts={['license2:account']=7,['license:account']=7}
  if scenario=='fallback'then r.accounts['license2:account']=nil end
  if scenario=='no-account'or scenario=='new-account'then r.accounts={}end
  local function row(id,slot,license)
   return{citizenid=id,userId=7,license=license,name='Virtual',
    charinfo='{"cid":'..slot..',"firstname":"Hank","lastname":"Jordan","gender":0,"birthdate":"1990-01-01","nationality":"Brazilian","account":"BANK1","phone":"555"}',
    money='{"bank":500,"cash":50}',job='{"name":"taxi","label":"Taxi","grade":{"name":"Driver","level":0}}',
    gang='{"name":"none","label":"None","grade":{"name":"None","level":0}}',
    position='{"x":10,"y":20,"z":30,"w":40}',metadata='{"health":200,"armor":0,"hunger":100,"thirst":100}',lastLoggedOutUnix=1000}
  end
  r.rows={row('OWNED_A',1,ids.license2 or ids.license),row('OWNED_B',2,ids.license or ids.license2),row('OTHER',1,'license:other')}
  if scenario=='empty'or scenario=='new-account'then r.rows={r.rows[3]}end
  r.purchased[7]={[2]=true};if scenario=='blocked'then r.blocked[7]={[2]=true}end
  local scalar,query,insert=r.bindings.db.scalar.await,r.bindings.db.query.await,r.bindings.db.insert.await
  local function record(kind,sql,params)r.sql[#r.sql+1]={kind=kind,sql=sql,params=H.copy(params)}end
  r.bindings.db.scalar.await=function(sql,params)
   record('scalar',sql,params)
   if sql:find('FROM `users`',1,true)then return r.accounts[params[1]]end
   return scalar(sql,params)
  end
  r.bindings.db.query.await=function(sql,params)
   record('query',sql,params)
   if sql:find('FROM players WHERE license = ? OR license = ?',1,true)then
    local out={};for _,row in ipairs(r.rows)do if row.license and(row.license==params[1]or row.license==params[2])then out[#out+1]=H.copy(row)end end
    table.sort(out,function(a,b)return a.citizenid<b.citizenid end);return out
   end
   if sql:find('FROM player_groups WHERE citizenid',1,true)then return{}end
   return query(sql,params)
  end
  r.bindings.db.single={await=function(sql,params)
   record('single',sql,params)
   if sql:find('FROM players WHERE citizenid = ?',1,true)then for _,row in ipairs(r.rows)do if row.citizenid==params[1]then return H.copy(row)end end;return nil end
   if sql:find('FROM bans',1,true)then return nil end
   if sql:find('FROM playerskins',1,true)then return{skin='virtual skin',model='mp_m_freemode_01'}end
   error('unexpected SQL '..sql)
  end}
  r.bindings.db.insert.await=function(sql,params)
   record('insert',sql,params)
   if sql:find('INSERT INTO users',1,true)then
    if params[2]then r.accounts[params[2]]=8 end;if params[3]then r.accounts[params[3]]=8 end;return 8
   end
   return insert(sql,params)
  end
  local vector=function(x,y,z,w)return{x=x,y=y,z=z,w=w}end
  local codec={decode=assert(test_decode_json),encode=function()error('read-only test did not authorize JSON persistence')end}
  local spawn=vector(1,2,3,4);local storage
  if ported then
   storage=H.load('kernel/server/storage.lua',H.environment())({db=r.bindings.db,json=codec,vec4=vector,defaultSpawn=spawn,
    characterDataTables={},log={info=function()end,error=function()end},warn=function()end,emitServer=function()end,
    addPlayerToJob=function()end,addPlayerToGang=function()end,date=os.date,
    groups={GetJob=function()end,GetGang=function()end,GroupType={JOB='job',GANG='gang'}}})
  else
   local env=H.environment({MySQL=r.bindings.db,json=codec,vec4=vector,RegisterCommand=function()end,CreateThread=function()end,
    GetJob=function()end,GetGang=function()end,GroupType={JOB='job',GANG='gang'},os={date=os.date},
    lib={print={info=function()end,error=function()end}}})
   env.require=function(name)if name=='config.shared'then return{defaultSpawn=spawn}end;if name=='config.server'then return{characterDataTables={}}end;error(name)end
   storage=P.loadOrigin('server/storage/players.lua',env)
  end
  r.actualStorage=storage;for key,value in pairs(storage)do r.bindings.storage[key]=value end
  r.bindings.native.GetPlayerIdentifierByType=function(_,kind)return ids[kind]end
 end)
 return r
end
local checks=0
for _,scenario in ipairs({'both','license-only','license2-only','fallback','empty','new-account','no-account','no-identifier','blocked'})do
 local results,queries={},{}
 for index,ported in ipairs({false,true})do
  local a=account(ported,scenario)
  -- Verify user identification at connection with actual installed storage queries.
  if scenario~='no-account'and scenario~='no-identifier'then
   local life=L.new(ported);life.ids[2]={};for _,kind in ipairs({'license2','license'})do if a.ids[kind]then life.ids[2][#life.ids[2]+1]=a.ids[kind]end end
   for _,key in ipairs({'fetchUserByIdentifier','createUser','fetchBan'})do life.storage[key]=a.actualStorage[key]end
   life.loadFunctions();life.loadEvents();local accepted={}
   life.deferrals=function()return{defer=function()end,done=function(...)accepted[#accepted+1]=table.pack(...)end}end
   assert(life.connect('virtual account',2));life.pump(12)
   -- The inherited ban lookup needs license; license2-only gets the same refusal in both implementations.
   assert(#accepted==1,'connection must finish once: '..scenario)
   if scenario=='license2-only'then assert(accepted[1].n==1 and accepted[1][1]=='error.connecting_error')
   else assert(accepted[1].n==0,'valid account must be accepted: '..scenario..':'..tostring(ported))end
  end
  local character=C.character(ported)
  character.bindings.slots.getState=a.api.getState;character.bindings.slots.getSettings=a.api.getSettings
  character.bindings.storage.fetchPlayerSkin=a.actualStorage.fetchPlayerSkin
  local w=T.new();w.open();local owner=w.scopes.server.Owners.ox
  local lease=owner.Reserve('qbx_core:server:getCharacters');assert(owner.Bind(lease,character.callbacks['qbx_core:server:getCharacters']))
  local reply
  local request=coroutine.create(function()reply=table.pack(w.scopes.client.Ox.await('qbx_core:server:getCharacters',nil))end)
  local ok,why=coroutine.resume(request);assert(ok,tostring(why));assert(coroutine.status(request)=='dead')
  assert(reply.n==3 and type(reply[1])=='table'and type(reply[3])=='table')
  if scenario=='no-account'or scenario=='no-identifier'then assert(#reply[1]==0 and reply[2]==1)
  elseif scenario=='empty'or scenario=='new-account'then assert(#reply[1]==0 and reply[2]==3)
  else
   assert(#reply[1]==2 and reply[1][1].citizenid=='OWNED_A'and reply[1][2].citizenid=='OWNED_B','never expose another account character')
   assert(reply[1][1].position.x==10 and reply[1][1].money.bank==500 and reply[1][1].charinfo.cid==1)
   if scenario=='blocked'then assert(reply[3].blocked[2]==true)end
   local flow=F.new(ported);flow.callbackHook=function(name,...)
    assert(name=='qbx_core:server:getCharacters');return w.scopes.client.Ox.await(name,nil,...)
   end
   local task=coroutine.create(flow.api.chooseCharacter)
   for _=1,30 do local success,errorText=coroutine.resume(task);assert(success,tostring(errorText));if coroutine.status(task)=='dead'then break end end
   assert(coroutine.status(task)=='dead'and flow.shown,'actual character code must reach the menu after RPC/SQL')
  end
  results[index]=P.snapshot(reply);queries[index]=H.copy(a.sql)
  assert(owner.Release(lease));w.close()
 end
 H.same(results[2],results[1],scenario..': selection reply QBX/Forge')
 H.same(queries[2],queries[1],scenario..': actual SQL and identifiers QBX/Forge');checks=checks+1
end
-- Real Login implementations must query ownership, enforce slots and hydrate the same PlayerData.
for _,ported in ipairs({false,true})do
 for _,id in ipairs({'OTHER','OWNED_A','OWNED_B'})do
  local a=account(ported,'blocked');local player=P.new(ported)
  for _,key in ipairs({'fetchUserByIdentifier','fetchPlayerEntity','fetchPlayerGroups'})do player.storage[key]=a.actualStorage[key]end
  player.bindings.characterSlots.canLoad=a.api.canLoad
  player.bindings.platform.getIdentifier=function(_,kind)return a.ids[kind]end
  player.env.GetPlayerIdentifierByType=player.bindings.platform.getIdentifier
  local login=ported and player.api.Login or player.env.Login
  local allowed=login(2,id)
  if id=='OWNED_A'then
   assert(allowed and player.core.Players[2],'owned unlocked character must hydrate PlayerData')
   local data=player.core.Players[2].PlayerData
   assert(data.userId==7 and data.citizenid==id and data.charinfo.cid==1 and data.money.bank==500 and data.source==2)
  else assert(allowed==false and player.core.Players[2]==nil,'foreign or blocked character must not hydrate PlayerData')end
  local selected=false;for _,q in ipairs(a.sql)do if q.sql:find('FROM players WHERE citizenid = ?',1,true)and q.params[1]==id then selected=true end end
  assert(selected,'Login must query the requested character before checking its license')
 end
end
print('PASS '..checks..' QBX/Forge connection-RPC-SQL-slot/menu comparisons; owned Login hydrates real PlayerData, foreign/blocked Login denied; DB/network/rendering virtual')
