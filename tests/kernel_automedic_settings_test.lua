local A=dofile('tests/kernel_automedic_harness.lua')
local n=0
local function case(label,fn,opt)A.case(label,fn,opt);n=n+1 end
case('config whole body',function(r)
    A.H.same(A.config(true),A.config(false));local seed={extra=true}
    assert(A.H.load('kernel/config/forge_automedic.lua',A.env())(seed)==seed)
    return r.config
end)
case('construction/start/clone',function(r)
    assert(not r.api.started and next(r.api.settings)==nil and #r.trace==0)
    r.start();local copy=r.api.getSettings();copy.enabled=false
    assert(r.api.settings.enabled);assert(r.api.start()==nil)
    return copy
end)
for _,raw in ipairs({{},false,'bad',{enabled='sim',hospitalFallback='yes',cooldown=0,bandageHealPercent=0},
    {enabled='false',cooldown=9000,treatmentPrice=1e12,reviveHealthPercent=-10,loseInventory={gunshot='no',other='1',collapse='yes'}},
    {cooldown=-1,treatmentPrice=-50,bandageHealPercent=101,reviveHealthPercent=101,beds=false}})do
    case('normalization',function(r)r.start();return r.api.save(0,raw)end)
end
case('deny admin',function(r)r.start();r.manage=false;return r.api.save(1,{})end)
case('save rejected preserves settings ref',function(r)
    r.start();local before=r.api.settings;r.m.onWrite=function()return false end
    local ok,err=r.api.save(0,{});assert(not ok and err=='save_failed'and r.api.settings==before);return true
end)
case('corrupt initial JSON/start sticky',function(r)
    r.m.files[r.config.Storage.file]='broken'
    local ok=pcall(r.api.start);assert(not ok and r.api.started);return r.api.start()
end)
case('missing initial file defaults',function(r)r.m.files={};r.start();return r.api.getSettings()end)
for _,field in ipairs({'coords','exit','heading','exitHeading','id','model'})do
    case('invalid bed field '..field,function(r)
        r.start();local bed=A.bed('bad',0);bed[field]=false;return r.api.saveBed(0,bed)
    end)
end
for _,x in ipairs({0/0,math.huge,-math.huge,100000})do
    case('invalid coordinate '..tostring(x),function(r)
        r.start();local bed=A.bed('bad',0);bed.coords.x=x;return r.api.saveBed(0,bed)
    end)
end
case('invalid bed id/distance',function(r)
    r.start();local bed=A.bed('../bad',0);local ok,e=r.api.saveBed(0,bed);assert(not ok and e=='invalid_bed')
    bed.id='good';bed.exit.x=100;return r.api.saveBed(0,bed)
end)
case('bed replace heading wrapping',function(r)
    r.start();local b=A.bed('near',1);b.heading=-90;b.exitHeading=450;b.label=string.rep('x',100)
    assert(r.api.saveBed(0,b));assert(#r.api.settings.beds==2 and r.api.settings.beds[1].heading==270)
    return r.api.getSettings()
end)
case('bed duplicate IDs dedup',function(r)
    r.start();return r.api.save(0,{beds={A.bed('same',0),A.bed('same',5),A.bed('new',10)}})
end)
case('bed denial/delete/notfound',function(r)
    r.start();r.manage=false;local ok,e=r.api.deleteBed(1,'near');assert(not ok and e=='no_permission')
    r.manage=true;assert(r.api.deleteBed(1,'near'));return r.api.deleteBed(1,'missing')
end)
case('settings save throws',function(r)
    r.start();r.m.onWrite=function()error('simulated-write',0)end;return r.api.save(0,{})
end)
print('PASS AutoMedic settings differentials '..n)

