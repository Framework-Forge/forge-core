local T=dofile('tests/kernel_qb_shared_harness.lua');local H=T.H;local n=0
local cases={
    {},{water={label='Water'}},{x=42,weapon_pistol={label='Gun'},pistol_ammo={label='Ammo'},tint_red={}},
    {food={label='Food',shouldClose=false,unique=true,description='A "meal"',weight=12,hunger=20,thirst=0,stress=-2,image='food.png'}},
    {existing={label='Existing'},x={name='existing',label='Alias'}},
    {a={name='same',label='Same'},b={name='same',label='Same'}},
    {food={label='Food',shouldClose=true,unique=false,description=false}},
}
for _,items in ipairs(cases)do
    for _,opts in ipairs({{}, {writeResult=false},{readError=true},{writeError=true}})do
        local a,b=T.converter(false,items,{existing={label='Old'}},opts),T.converter(true,items,{existing={label='Old'}},opts)
        a.run();b.run();a.flush();b.flush()
        assert(a.ok==b.ok and a.err==b.err);H.same(a.items,b.items);H.same(a.list,b.list);H.same(a.trace,b.trace);n=n+1
    end
end
local r=T.converter(true,{bread={label='Bread'}},nil,{writeResult=false});assert(r.run()and r.list.bread==r.items.bread)
assert(#r.tasks==1);r.flush();assert(r.trace[#r.trace][2][1]:match('MUST restart'))
print('PASS lot87 converter whole-file parity:'..n..' cases;mutations/filtering/Lua text/errors/false-write-success preserved,PR IO memory only')
