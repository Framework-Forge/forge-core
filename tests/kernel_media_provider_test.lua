local M=dofile('tests/kernel_media_harness.lua');local H=M.H;local cases=0
local payloads={{audioName='front',audioRef='HUD'},
    {audioName={'one','two'},soundSet='HUD',entity=99,radius=15,delayBetweenSounds=30},
    {audioName='coord',coords={x=0,y=0,z=0},range=15,occlusion=true,occludedAudioRef='wall'}}
for _,target in ipairs({2,-1,{1,2},'2'})do for _,payload in ipairs(payloads)do
    local a,b=M.provider(),M.provider();b.mount();assert(b.api.Open())
    local original,ported=M.helper(false,a),M.helper(true,b)
    H.same(table.pack(original.api.playAudio(target,payload)),table.pack(ported.api.playAudio(target,payload)),'installed lib audio returns')
    H.same(original.trace,ported.trace,'installed lib audio trace');H.same(a.calls,b.calls,'installed provider export');H.same(a.events,b.events,'installed provider targets')
    cases=cases+1
end end
for _,mode in ipairs({'stopped','starting','bad','single'})do
    local a,b=M.provider(),M.provider();a.states.pr_3dsound=mode;b.states.pr_3dsound=mode;b.mount();assert(b.api.Open())
    if mode=='single'or mode=='bad'then a.states.pr_3dsound='started';b.states.pr_3dsound='started'end
    local original,ported=M.helper(false,a),M.helper(true,b);local p=mode=='bad'and'bad'or payloads[1]
    local function call(h)if mode=='single'then return h.api.playAudio(p)end;return h.api.playAudio(2,p)end
    H.same(table.pack(call(original)),table.pack(call(ported)),'audio overload/readiness');H.same(a.events,b.events,'audio state effects');cases=cases+1
end
assert(cases==16)
local r=M.provider();r.mount();assert(r.api.Open());assert(#r.events==0 and #r.calls==0 and r.statesRead==nil,'construction and Open inert')
assert(r.api.Audio.PlayNativeSoundFromEntity(-1,{entity=0,audioName='bad'})==false)
assert(r.api.Audio.PlayNativeSoundFromCoords(-1,{coords={x=1000,y=0,z=0},range=1,audioName='empty'})==true and #r.events==0,'empty audience true is not playback acknowledgement')
r.override=table.pack(nil,'raw',7);H.same(table.pack(r.api.Audio.PlayNativeSound(2,{})),r.override,'raw export tuples')
r.override=table.pack(false);assert(M.helper(true,r).api.playAudio(2,payloads[1])==false)
r.override=nil;r.fail=true;assert(M.helper(true,r).api.playAudio(2,payloads[1])==false,'legacy pcall translates export error to false')
assert(not pcall(r.api.Audio.PlayNativeSound,2,{}),'raw provider error propagates before lib pcall');r.fail=false
local message={color={0,0,255},multiline=true,args={'OOC | Virtual','hello'}};r.sendResult=table.pack(nil,'sent',3)
H.same(table.pack(r.api.ChatMessage(2,message)),r.sendResult,'chat transport tuples')
assert(r.nui[1].type=='ON_MESSAGE'and r.nui[1].message==message,'whole installed chat legacy handler preserves payload reference')
print('PASS lot68 media provider:16 installed lib comparisons,whole native_sound and chat bodies,Cfx receiver/tuples/readiness/empty audience/pcall;virtual only')
