local T=dofile('tests/kernel_transport_harness.lua')
local n=0
local function case(label,action,options)n=n+1;T.case('compat',label,action,options)end
local function input()return{name='taxi',label='Changed',grades={{grade=1,name='Senior',salary=90}}}end
case('seven exports',function(r)local count=0;for _ in pairs(r.exports)do count=count+1 end;assert(count==7)end)
for _,caller in ipairs({'pr_bridge','allowed','denied',''})do
    for _,name in ipairs({'CompatCreateJob','CompatRefreshJobs','CompatRefreshJob','CompatAddItems','CompatRefreshItems','CompatIsPaycheckEnabled','CompatTogglePaycheck'})do
        case('caller '..caller..' '..name,function(r)
            r.caller=caller;r.principal=caller=='allowed'
            local args=({CompatCreateJob={input()},CompatRefreshJobs={},CompatRefreshJob={'taxi'},CompatAddItems={{{name='water'}}},
                CompatRefreshItems={},CompatIsPaycheckEnabled={1},CompatTogglePaycheck={1,true}})[name]
            local ok,err=pcall(r.exports[name],table.unpack(args));assert(ok==(caller=='pr_bridge'or caller=='allowed'));if not ok then return T.message(err)end
        end)
    end
end
case('no invoking resource refused',function(r)r.caller=nil;local ok,err=pcall(r.exports.CompatRefreshJobs);assert(not ok);return T.message(err)end)
case('merge preserves native and administrative data',function(r)
    local ok=r.exports.CompatCreateJob(input());assert(ok);assert(r.jobs.taxi.label=='Taxi'and r.jobs.taxi.grades['0'].payment==50 and r.jobs.taxi.grades['1'].payment==90)
    assert(r.registry.jobs.taxi.owner=='A'and r.registry.jobs.taxi.stashes[1].password=='kept')
end)
case('existing grade refused',function(r)local data=input();data.grades[1].grade=0;local ok,err=r.exports.CompatCreateJob(data);assert(not ok and err=='job_or_grades_exist')end)
case('upsert failure',function(r)r.save=false;local ok=r.exports.CompatCreateJob(input());assert(not ok)end)
case('missing live sync',function(r)r.jobs={};r.sync=false;local ok,err=r.exports.CompatCreateJob(input());assert(not ok and err=='core_sync_failed')end)
case('missing grade sync',function(r)r.sync=false;local ok,err=r.exports.CompatCreateJob(input());assert(not ok and err=='core_grade_sync_failed')end)
for _,data in ipairs({{name='bad name',label='Bad',grades={}}, {name='valid',label='',grades={}}, {name='valid',label='Valid',grades={{grade=-1,name='x'}}}})do
    case('invalid job helper',function(r)local ok,err=pcall(r.exports.CompatCreateJob,data);assert(not ok);return T.message(err)end)
end
for _,name in ipairs({'CompatRefreshJobs','CompatRefreshJob'})do case(name..' reload false',function(r)r.reload=false;local ok,err=r.exports[name]('taxi');assert(not ok and err=='reload_failed')end)end
case('refresh items count',function(r)assert(r.exports.CompatRefreshItems()==2)end)
case('refresh items failed',function(r)r.results.reloadItems=table.pack(false);local ok,err=r.exports.CompatRefreshItems();assert(not ok and err=='reload_failed')end)
case('bad item definitions refused',function(r)local ok,err=pcall(r.exports.CompatAddItems,'bad');assert(not ok);return T.message(err)end)
case('custom add items error returned',function(r)r.results.addCompatibilityItems=table.pack(false,'runtime_sync_failed:burger');local ok,err=r.exports.CompatAddItems({});assert(not ok and err=='runtime_sync_failed:burger')end)
for _,enabled in ipairs({true,false})do case('paycheck state '..tostring(enabled),function(r)assert(r.exports.CompatTogglePaycheck('1',enabled));assert(r.exports.CompatIsPaycheckEnabled(1)==enabled)end)end
case('paycheck ignores save false inherited',function(r)r.results.Save=table.pack(false);assert(r.exports.CompatTogglePaycheck(1,false));assert(r.player.PlayerData.metadata.prCompatPaycheckEnabled==false)end)
case('invalid paycheck input',function(r)local ok,err=pcall(r.exports.CompatTogglePaycheck,1,1);assert(not ok);return T.message(err)end)
case('invalid player',function(r)local ok,err=pcall(r.exports.CompatIsPaycheckEnabled,999);assert(not ok);return T.message(err)end)
print('PASS '..n..' Forge facade differential cases; caller/ACE trust, full job merge/refresh, custom inventory dependency and Player paycheck metadata; no public exports installed')
