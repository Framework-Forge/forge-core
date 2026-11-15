-- Cfx ClientDeferral: exactly one non-string argument rejects with "Unknown error".
local L=dofile('tests/kernel_lifecycle_harness.lua');local checks=0
local function scenario(mode,queue)
 local r=L.new(true);r.loadFunctions()
 if queue then r.loadQueue()end
 if mode=='closed'or mode=='closed-no-reason'then r.serverConfig.closed=true end
 if mode=='closed-no-reason'then r.serverConfig.closedReason=nil end
 if mode=='no-license'then r.ids[1]={}end
 if mode=='duplicate'then r.serverConfig.checkDuplicateLicense=true end
 if mode=='banned'then r.bans['license2:L1']={expire=2000,reason='Denied'}end
 if mode=='whitelist'then r.serverConfig.whitelist=true end
 if mode=='ban-query-error'then r.functions.IsPlayerBanned=function()error('simulated ban query failure')end end
 if mode=='ban-no-reason'then r.functions.IsPlayerBanned=function()return true,nil end end
 if mode=='ban-false-reason'then r.functions.IsPlayerBanned=function()return true,false end end
 r.loadEvents();if mode=='duplicate'then r.dispatch('playerJoining',1)end
 local calls={};r.deferrals=function()
  return{defer=function()end,presentCard=function()end,done=function(...)
   local args=table.pack(...);calls[#calls+1]=args
   local reason=args.n==1 and(type(args[1])=='string'and args[1]or'Unknown error')or nil
   args.rejected=args.n==1;args.reason=reason
  end}
 end
 local ok,err=r.connect(mode,1);assert(ok,tostring(err));r.pump(12)
 assert(#calls==1,'exactly one terminal result: '..mode)
 if mode=='accepted'then
  assert(not calls[1].rejected,'Cfx rejected accepted player: '..tostring(calls[1].reason))
  assert(calls[1].n==0,'successful deferral must have zero arguments')
 elseif mode=='closed-no-reason'or mode=='ban-no-reason'or mode=='ban-false-reason'then
  assert(calls[1].n==1 and calls[1].rejected and calls[1].reason=='Unknown error','malformed denial must not turn into admission: '..mode)
 else
  assert(calls[1].n==1 and type(calls[1][1])=='string','refusal must retain reason: '..mode)
  assert(calls[1].reason~='Unknown error','no non-string denial: '..mode)
 end
 checks=checks+1
end
for _,queue in ipairs({false,true})do
 for _,mode in ipairs({'accepted','closed','no-license','duplicate','banned','whitelist','ban-query-error',
  'closed-no-reason','ban-no-reason','ban-false-reason'})do scenario(mode,queue)end
end
print('PASS Cfx deferral arity: '..checks..' real connection/finalization cases; acceptance zero arguments, refusals terminal with reason; SQL/clock virtual')
