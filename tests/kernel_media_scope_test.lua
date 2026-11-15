local M=dofile('tests/kernel_media_harness.lua')
for _,kind in ipairs({'audio','chat','state'})do
    local r=M.provider();r.mount();assert(r.api.Open());local result
    if kind=='audio'then r.onExport=function()coroutine.yield('accepted audio')end
    elseif kind=='chat'then r.onSend=function()coroutine.yield('accepted chat')end
    else local state=r.ports.resourceState;r.ports.resourceState=function(...)coroutine.yield('accepted state');return state(...)end
        r.api=r.factory(r.ports);assert(r.api.Open())end
    local co=coroutine.create(function()
        if kind=='audio'then result=r.api.Audio.PlayNativeSound(2,{audioName='a'})
        elseif kind=='chat'then r.api.ChatMessage(2,{args={'a'}});result=true
        else result=r.api.ResourceState('pr_3dsound')end
    end)
    assert(coroutine.resume(co));r.api.Close();assert(r.api.Progress().pending==1 and not r.api.Progress().complete)
    assert(coroutine.resume(co));assert(result and r.api.Progress().complete,'accepted media call can finish after Close without rollback')
    local calls,events=#r.calls,#r.events
    assert(r.api.Audio.PlayNativeSound(2,{})==nil and r.api.ChatMessage(2,{})==nil and r.api.ResourceState('pr_3dsound')==nil)
    assert(#r.calls==calls and #r.events==events and not r.api.Open(),'closed media cannot send or reopen')
end
local stale=M.provider();stale.mount();assert(stale.api.Open());stale.current=false
assert(stale.api.Audio.PlayNativeSound(2,{})==nil and stale.api.ChatMessage(2,{})==nil and stale.api.ResourceState('pr_3dsound')==nil)
stale.api.Close();assert(stale.api.Progress().complete and stale.api.Progress().DeliveryAcknowledged==false)
print('PASS lot68 owned media:accepted audio/chat/state calls drain after Close,new ingress/stale owner/reopen refused,no delivery ack or cancellation claim')
