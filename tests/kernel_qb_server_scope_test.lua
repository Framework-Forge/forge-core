local S=dofile('tests/kernel_qb_server_harness.lua');local H=S.H;local n=0
for _,allow in ipairs({'true','false'})do for _,quiet in ipairs({'true','false'})do for _,ids in ipairs({2,-1,{2,99},{who=2}})do
    local opts={convars={['qbx:allowmethodoverrides']=allow,['qbx:disableoverridewarning']=quiet}}
    local a,b=S.new(false,opts),S.new(true,opts)
    local handler=function()end
    for _,r in ipairs({a,b})do
        r.decorate(r.player);r.player.Functions.test=function()end
        r.Functions.AddPlayerMethod(ids,'test',handler)
        assert(r.player.Functions.test==handler or allow=='false'or type(ids)=='table')
    end
    H.same(a.trace,b.trace);H.same(a.capture(a.Functions.AddPlayerField,ids,'x',1),b.capture(b.Functions.AddPlayerField,ids,'x',1));n=n+1
end end end
for _,deferring in ipairs({false,true})do
    local a,b=S.new(false),S.new(true)
    for _,r in ipairs({a,b})do
        local reason=function(...)r.rec('reason',...)end
        local deferrals=deferring and{update=function(...)r.rec('deferral',...)end}or nil
        r.Functions.Kick(2,'Reason',reason,deferrals);r.flush()
    end
    H.same(a.trace,b.trace);n=n+1
end
-- Installed source-less Kick is nonterminating. Bound it outside production; do not change its semantics.
for _,ported in ipairs({false,true})do
    local r=S.new(ported);r.Functions.Kick(nil,'Reason')
    debug.sethook(function()error('fixture_instruction_limit')end,'',10000)
    local ok,err=pcall(r.tasks[1]);debug.sethook()
    assert(not ok and tostring(err):find('fixture_instruction_limit',1,true));n=n+1
end
for _,r in ipairs({S.new(false),S.new(true)})do
    r.missing=true;assert(r.Functions.GetPlayer(2)==nil and r.Player.GetOfflinePlayer('missing')==nil)
    assert(#r.trace==2 and #r.commands==0 and #r.tasks==0)
end
print('PASS lot88 scope:'..n..' cases;method overrides/quiet flags/player fields,known Kick nontermination characterized under test instruction budget;no live handlers/threads')
