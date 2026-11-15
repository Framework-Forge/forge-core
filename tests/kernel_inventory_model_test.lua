local I=dofile('tests/kernel_inventory_harness.lua')
local n=0
local function case(label,fn,options)n=n+1;I.case(label,fn,options)end
for _,seed in ipairs({{}, {extra='kept'}, {ItemDefaults={weight=999}}, {LegacyInteractions={custom={}}}})do
    n=n+1;I.H.same(I.config(true,seed),I.config(false,seed),'complete config/seed parity')
end
for _,data in ipairs({{name='  Burger ! '},{name='qb',unique=true,shouldClose=false,useable=true,type='item',combinable={}},
    {name='qb2',unique=false,stack=false,close=true}, {name='negative',weight=-100,active=false},
    {name='image',image='https://fixture/image.jpg?a=1'}, {name='image2',image='folder\\pic #1.png'},
    {name='image3',client={image='https://fixture/video.mp4'}}, {name='bools',stack=1,close=0,active=0,client='invalid'},
    {name='access',access={job={name=' Police ! ',grade='3.9'},gang={name='Ballas',grade=-3},vips={' GOLD ','gold','silver',1}}}})do
    case('item normalization '..data.name,function(r)local ok,item=r.api.upsertItem(1,I.H.copy(data));assert(ok and item.name~='');return item end)
end
for _,duration in ipairs({-1,0,1,249,250,5000,120001})do
    case('interaction duration '..duration,function(r)
        local ok,item=r.api.upsertItem(1,{name='consume',interaction={enabled=true,duration=duration,remove=101,effect='maconha',effectDuration=0,effectStrength=5,
            category='invalid',kind='invalid',animation={mode='full',clip='anim',props={{model='p',bone='3.9',pos={1,2,3},rot={z=4},rotOrder=4}}},
            effects={hunger={min=200,max=-200},stress={-10,-5}}}})
        assert(ok and item.interaction.effect=='weed'and item.interaction.remove==100 and item.interaction.effects.hunger.min==-100)
        assert(item.interaction.duration==(duration<=0 and 0 or math.max(250,math.min(120000,duration))))
    end)
end
for _,mode in ipairs({'free','job','gang','admin','invalid'})do
    case('access mode '..mode,function(r)local ok,item=r.api.upsertItem(1,{name='access',access={mode=mode,name=' Police ! ',grade=2}});assert(ok);return item.access end)
end
case('props capped and legacy fields removed',function(r)
    local props={};for i=1,6 do props[i]={model='p'..i}end
    local ok,item=r.api.upsertItem(1,{name='props',interaction={props=props,health={5,10},thirst={20,30}}})
    assert(ok and #item.interaction.animation.props==4 and item.interaction.props==nil and item.interaction.health==nil)
end)
for _,name in ipairs({'sandwich','coffee','beer','joint','meth'})do
    case('legacy interaction '..name,function(r)r.seedItems({[name]={label=name}});assert(r.api.reload());local item=r.api.getItem(name);assert(item.interaction.enabled and r.memory.files[r.config.Storage.items])end)
end
case('existing interaction not replaced',function(r)r.seedItems({sandwich={name='sandwich',interaction={enabled=false,duration=999}}});assert(r.api.reload());assert(r.api.getItem('sandwich').interaction.enabled==false)end)
for _,value in ipairs({'bad',false,17})do case('invalid item type',function(r)local ok,err=r.api.upsertItem(1,value);assert(not ok and err=='invalid_item')end)end
case('missing item name',function(r)local ok,err=r.api.upsertItem(1,{});assert(not ok and err=='missing_name')end)
local snippets={
    {'item',"return { name='water', label='Water',weight=50 }"},
    {'item',"{ name='water',label='Water' }"},
    {'item',"['water']={label='Water'},['bread']={label='Bread'}"},
    {'animation',"dict='d',clip='c',props={model=`prop_cs_burger_01`}"},
    {'ammo',"name='ammo-9',label='9mm'"},{'component',"name='COMP_SCOPE',label='Scope'"},
    {'weapon',"name='custom',weight=3"},{'weapon',"['one']={label='One'},['two']={label='Two'}"},
    {'item',"name='root',client={image='pic.png'}"}, -- inherited named-entry heuristic treats nested table as entry
    {'unknown',"name='item'"},{'animation',"dict='missing_anim'"},{'item',''},{'item','return true'},
    {'item','return os.execute("forbidden")'},{'item','return load("forbidden")()'},{'item','return {'}}
for i,snippet in ipairs(snippets)do case('snippet '..i,function(r)return r.api.parseDefinition(1,snippet[1],snippet[2])end)end
case('live item getter reference preserved',function(r)local a=r.api.getItem(' BURGER ');a.active=false;assert(r.api.getItem('burger')==a and not r.api.canUseItem(1,'burger'))end)
print('PASS '..n..' inventory model/config differential cases; complete defaults, schema/interaction/images/access/legacy/parser and inherited heuristic; no runtime files written')
