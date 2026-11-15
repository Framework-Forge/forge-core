local T=dofile('tests/kernel_native_raw_entry_harness.lua')
for _,side in ipairs({'server','client'})do local r=T.raw(side);r.enter();assert(r.wire[side].active()==0)
    assert(r.entry.Prepare());assert(r.wire[side].active()==(side=='server'and 8 or 6))
    assert(r.entry.Services.Public.framework==nil and r.entry.Services.Progress().phase=='prepared')
    assert(r.entry.Close()and r.entry.Progress().complete and r.wire[side].active()==0 and r.wire.prs[side].forgeRawEntry==nil);r.finish()
end
local r=T.consumer();assert(r.admission.ObservePrepared());r.publish();assert(r.control.Install())
assert(r.entry.Attach()and r.policy.Advance(5));assert(r.pr.forgeNormalizedFacade.GetIdentifier(2)=='LATE114')
assert(r.policy.Progress().consumers[r.boundResource]=='committed'and r.admission.IsAllowed(r.boundResource,'call'))
local held=r.descriptorSurface.ForgePrConsumerDescribe;assert(r.entry.Close()and held()==nil);r.finish()
local p=test_decode_json(T.read('package.json'));local count=0
for _,f in ipairs(p.files)do if f.path:match('%.lua$')then assert(load(T.read(f.path),'@@package125/'..f.path,'t',{}));count=count+1 end end
assert(count==33 and not p.operationalReady)
print('PASS lot125 native raw PR both sides,owned122/123,physical125 descriptor/118/124 handshake/commit same Player;33 Lua compiled;no operational activation')
