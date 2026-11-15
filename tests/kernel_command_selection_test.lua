local T=dofile('tests/kernel_public_registration_harness.lua');local H=T.H
local factory=H.load('kernel/shared/public_registration.lua',T.env());local count=0
for _,enabled in ipairs({false,true})do
 local e=T.surface('server');local predicates=0;local valid=true
 local foreign={handler=function()return'custom-chat'end};if not enabled then e.commands.me=foreign end
 local a=factory({owner={},side='server',isCurrent=function()return valid end,entries={
  {kind='command',mode='pr',owner='Runtime.Commands',name='me',properties={},handler=function()return'inherited'end,
   externalOwner='forge-chat',isEnabled=function()predicates=predicates+1;return enabled end},
  {kind='export',owner='PlayerCore',name='GetPlayer',handler=function()return'canonical'end}}},e.ports)
 assert(predicates==0 and #e.trace==0 and #a.GetDelegatedCommands()==0,'passive construction')
 e.Open();assert(a.Install());assert(predicates==1 and e.exports.GetPlayer()=='canonical')
 local decisions=a.GetDelegatedCommands()
 if enabled then assert(#decisions==0 and e.commands.me~=foreign)
 else
  assert(#decisions==1 and decisions[1].name=='me'and decisions[1].externalOwner=='forge-chat')
  assert(e.commands.me==foreign and foreign.handler()=='custom-chat','existing handler untouched')
  decisions[1].externalOwner='mutated';assert(a.GetDelegatedCommands()[1].externalOwner=='forge-chat')
 end
 assert(a.Dispose());if not enabled then assert(e.commands.me==foreign)end
 count=count+1
end
for _,mode in ipairs({'foreign','invalid','error','stale','disposed'})do
 local e=T.surface('server');local valid=true;local a
 e.commands.unrelated={handler=function()return'foreign'end}
 local entry={kind='command',mode='pr',owner='Runtime.Commands',name='me',handler=function()end,
  externalOwner='forge-chat',isEnabled=function()
   if mode=='invalid'then return nil end
   if mode=='error'then error('selection-error',0)end
   if mode=='stale'then valid=false end
   if mode=='disposed'then assert(not a.Dispose())end
   return false
  end}
 local entries={entry,{kind='export',name='GetPlayer',owner='PlayerCore',handler=function()end}}
 if mode=='foreign'then entries[#entries+1]={kind='command',mode='pr',name='unrelated',owner='Other',handler=function()end}end
 a=factory({owner={},side='server',entries=entries,isCurrent=function()return valid end},e.ports)
 e.Open();local ok,why=a.Install()
 if mode=='disposed'then
  assert(ok and e.exports.GetPlayer and #a.GetDelegatedCommands()==1,'Dispose is refused during installation; later commit remains valid')
  assert(a.Dispose())
 else
  assert(not ok,tostring(why))
  assert(e.exports.GetPlayer==nil and #e.trace==0 and #a.GetDelegatedCommands()==0,'selection failure before any publication')
 end
 if mode=='foreign'then assert(tostring(why):find('foreign public name: unrelated',1,true))end
 count=count+1
end
local R=dofile('tests/kernel_server_runtime_harness.lua');local r=R.new(true,'commands')
local me=assert(r.commands.me);local probes=0;local state='missing'
r.bindings.native.GetResourceState=function(resource)assert(resource=='forge-chat');probes=probes+1;return state end
assert(me.externalOwner=='forge-chat'and probes==0)
for _,value in ipairs({'missing','stopped','starting','started'})do state=value;assert(me.isEnabled()==(value=='missing'or value=='stopped'))end
assert(probes==4)
for name,d in pairs(r.commands)do if name~='me'then assert(d.isEnabled==nil and d.externalOwner==nil)end end
count=count+1
assert(count==8)
print('PASS eight command ownership scenarios; passive selection, standalone fallback, external handler preserved, foreign collisions/errors/stale/disposed refused')
