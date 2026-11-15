local M=dofile('tests/kernel_client_media_harness.lua');local cases=0
for _,mode in ipairs({'front','entity','coords','localCoords','returnId','stopped','error','bank'})do
    local a,b=M.provider(),M.provider();b.mount();assert(b.api.Open())
    for _,r in ipairs({a,b})do r.exists[99]=true;r.positions[99]=M.V.vector(0,0,0);if mode=='stopped'then r.state='stopped'end;if mode=='error'then r.audioError=true end end
    local x,y=M.helper(false,a),M.helper(true,b);local p={audioName='test',audioRef='HUD'}
    if mode=='entity'then p.entity=99 elseif mode=='coords'or mode=='localCoords'then p.coords={x=0,y=0,z=0};p.shared=mode~='localCoords'
    elseif mode=='returnId'then p.returnSoundId=true elseif mode=='bank'then p.audioBank='bank'end
    M.H.same(table.pack(x.api.playAudio(p)),table.pack(y.api.playAudio(p)),'whole lib audio returns')
    M.H.same(x.trace,y.trace,'lib audio native fallback');M.H.same(a.trace,b.trace,'installed sound body');cases=cases+1
end
assert(cases==8)
local r=M.provider();r.mount();assert(#r.trace==0 and r.api.Open()and #r.trace==0,'client media construction and Open inert')
local calls=0
for _,kind in ipairs({'requestModel','requestAnimDict','createObject','createPed','createVehicle','deleteEntity','releaseModel','releaseAnimDict'})do
    local a,b=M.provider(),M.provider();b.mount();assert(b.api.Open());local args
    if kind:find('create',1,true)then args=table.pack('model',M.V.vector(1,2,3),0,{})
        if kind=='createObject'then args=table.pack('model',M.V.vector(1,2,3),{})end
    else args=table.pack(kind=='deleteEntity'and 7 or'asset',5);a.exists[7]=true;b.exists[7]=true end
    M.H.same(table.pack(a.streaming[kind](table.unpack(args,1,args.n))),table.pack(b.api.Streaming[kind](table.unpack(args,1,args.n))),'PR streaming tuple '..kind)
    M.H.same(a.trace,b.trace,'PR streaming native trace '..kind);calls=calls+1
end
assert(calls==8)
r.loaded=false;local ok,hash=r.api.Streaming.requestModel('timeout',3);assert(ok==false and hash==107 and r.now==3,'installed request timeout returns false plus hash')
r.valid=false;ok,hash=r.api.Streaming.requestModel('invalid');assert(ok==false and hash==107)
r.anim=false;r.animValid=false;assert(r.api.Streaming.requestAnimDict('absent')==false)
print('PASS lot69 client provider:8 whole-QBX-lib audio comparisons,8 installed PR streaming comparisons,timeout/invalid tuples,whole native_sound,virtual natives only')
