local S=dofile('tests/kernel_qb_server_harness.lua');local H=S.H;local n=0
local cases={{'SaveInventory',2},{'SaveOfflineInventory',{}},{'GetTotalWeight',{}},{'GetSlotsByItem',{},'bread'},{'GetFirstSlotByItem',{},'bread'},
    {'Login',2,'QB88',{}},{'GetOfflinePlayer','QB88'},{'CheckPlayerData'},{'Logout',2},{'CreatePlayer',{},false},{'Save',2},
    {'SaveOffline',{}},{'DeleteCharacter',2,'QB88'},{'ForceDeleteCharacter','QB88'},{'GenerateUniqueIdentifier','PhoneNumber'},{'CreateCitizenId'}}
local covered={}
for _,c in ipairs(cases)do for _,state in ipairs({'missing','started'})do
    local a,b=S.new(false),S.new(true);a.resourceState=state;b.resourceState=state
    H.same(a.capture(a.Player[c[1]],table.unpack(c,2)),b.capture(b.Player[c[1]],table.unpack(c,2)),c[1]);H.same(a.trace,b.trace);n=n+1;covered[c[1]]=true
end end
local a,b=S.new(false),S.new(true);for name in pairs(a.Player)do assert(covered[name],name)end
for _,r in ipairs({a,b})do assert(r.decorate(nil)==nil and r.decorate(r.player)==r.player and r.Functions.GetPlayer(2)==r.player)
    for _,name in ipairs({'GetCardSlot','AddField','AddMethod'})do assert(not pcall(r.player.Functions[name]))end end
for _,permission in ipairs({false,'user','admin'})do for _,required in ipairs({false,true})do for _,args in ipairs({{'a','b'},{first='a',second='b'}})do
    local a,b=S.new(false),S.new(true)
    for _,r in ipairs({a,b})do
        r.Commands.Add('cmd','Help',{{name='first',help='First',type='string'},{name='second',optional=true}},required,function(...)r.rec('callback',...)end,permission)
        r.commands.cmd.fn(2,args,'raw command');r.Commands.Refresh(2)
    end
    H.same(a.trace,b.trace);n=n+1
end end end
print('PASS lot88 Player/commands whole-file parity:'..n..' cases;return arity/decorated identities/inventory guards,ACL/optional/named-positional arguments preserved')
