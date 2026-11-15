local T=dofile('tests/kernel_qb_shared_harness.lua');local H=T.H;local n=0
for _,starter in ipairs({false,{},{{name='id',amount=1},{name='phone',amount=2},{name='id',amount=3}}})do
    local a,b=T.shared(false,starter),T.shared(true,starter)
    for _,r in ipairs({a,b})do
        assert(r.shared.Vehicles==r.canonical.Vehicles and r.shared.Weapons==r.canonical.Weapons)
        assert(r.shared.MaleNoGloves==r.helpers.armsWithoutGloves.male)
        assert(r.shared.ChangeVehicleExtra==r.helpers.setVehicleExtras and r.shared.Round==r.helpers.math.round)
    end
    assert(b.shared~=b.canonical and b.canonical.Items==nil and b.canonical.RandomStr==nil)
    H.same(a.shared.StarterItems,b.shared.StarterItems);n=n+1
    for _,name in ipairs({'Trim','FirstToUpper'})do
        for _,args in ipairs({table.pack(nil),table.pack(' abc ')})do
            H.same(table.pack(a.shared[name](table.unpack(args,1,args.n))),table.pack(b.shared[name](table.unpack(args,1,args.n))));n=n+1
        end
    end
    for _,name in ipairs({'RandomStr','RandomInt'})do for _,v in ipairs({-1,0,1,5})do assert(a.shared[name](v)==b.shared[name](v));n=n+1 end end
    H.same(a.shared.SplitStr('a:b',':'),b.shared.SplitStr('a:b',':'));n=n+1
    assert(a.shared.CommaValue(123)==b.shared.CommaValue(123));n=n+1
end
print('PASS lot87 QB shared whole-file parity:'..n..' comparisons;canonical catalog references retained,compatibility namespace isolated')
