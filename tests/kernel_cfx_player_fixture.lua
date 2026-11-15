-- Execute the installed Cfx Player/StateBag source; only native storage/codec are virtual.
return function()
 local file=assert(io.open('tests/fixtures/cfx_player_state_20261029.lua','rb'));local source=file:read('*a');file:close()
 local values,writes={},{}
 local env=setmetatable({msgpack={extend=function(mt)return mt end},GetPlayerServerId=function()return 7 end,PlayerId=function()return 2 end,
  GetStateBagValue=function(bag,key)return values[bag]and values[bag][key]end,
  SetStateBagValue=function(bag,key,payload,length,replicate)
   values[bag]=values[bag]or{};values[bag][key]=payload.value;writes[#writes+1]={bag=bag,key=key,value=payload.value,replicate=replicate}
  end},{__index=_G})
 local prefix="local EXT_ENTITY,EXT_PLAYER=41,42;local isDuplicityVersion=false;local function msgpack_pack(v)return{value=v,len=function()return 1 end}end\n"
 assert(load(prefix..source,'@citizen:/scripting/lua/scheduler.lua:player-state','t',env))()
 assert(type(env.LocalPlayer)=='table'and rawget(env.LocalPlayer,'state')==nil and type(env.LocalPlayer.state.set)=='function')
 assert(env.LocalPlayer.state~=env.LocalPlayer.state,'Cfx produces a new proxy on each access')
 return{LocalPlayer=env.LocalPlayer,GlobalState=env.GlobalState,Environment=env,Values=values,Writes=writes}
end
