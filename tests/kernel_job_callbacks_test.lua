local T=dofile('tests/kernel_transport_harness.lua')
local n=0
local function case(label,action,options)n=n+1;T.case('callbacks',label,action,options)end
case('all 23 descriptors',function(r)assert(#r.callbacks==23);local names={};for _,v in ipairs(r.callbacks)do assert(not names[v.name]);names[v.name]=true end end)
for _,started in ipairs({false,true})do
    case('getAll startup '..tostring(started),function(r)r.services.JobService.started=started;r.allow=false;local data,allowed=r.callback('getAll',1);assert(data.jobs[1].stashes[1].password=='fixture-secret'and allowed==false)end)
end
case('getAll ignores start false',function(r)r.results.start=table.pack(false);local payload=r.callback('getAll',1);assert(payload.revision==1)end)
local forwarding={openStash={1,'job','police','station','pw'},toggleDuty={1,'police','station'},
    getRegisterBalance={1,'job','police','station','cash'},registerAction={1,'job','police','station','cash','withdraw',5,'pw'},
    robRegister={1,'job','police','station','cash',5},openShop={1,'job','police','station','shop'},getSupplyItems={1,'job','police','station','shop'},
    supplyShop={1,'job','police','station','shop','burger',3,7},sendAlarm={1,'job','police','station','alarm'},
    submitApplication={1,'job','police','station','apply',{'yes',2}},getApplications={1,'job','police','station','apply'},
    reviewApplication={1,'job','police','station','apply','A_1','accepted'},getEmployees={1,'job','police'},
    hirePlayer={1,'job','police','A',2},fireEmployee={1,'job','police','A'},setEmployeeGrade={1,'job','police','A',3}}
local ordered={};for name in pairs(forwarding)do ordered[#ordered+1]=name end;table.sort(ordered)
for _,name in ipairs(ordered)do
    for _,variant in ipairs({'success','false','nil'})do
        case(name..' '..variant,function(r)
            if variant=='false'then r.results[name]=table.pack(false,'denied',nil,7)elseif variant=='nil'then r.results[name]=table.pack(nil,nil,'last')end
            local values=table.pack(r.callback(name,table.unpack(forwarding[name])))
            assert(values.n==(variant=='nil'and 3 or 4),'forwarding must not truncate tail nil slots')
            if variant=='false'then assert(values[1]==false and values[4]==7)end
        end)
    end
end
for _,key in ipairs({'savePaymentSettings','forcePayment','saveMeiSettings','createMei'})do
    local method=({savePaymentSettings='update',forcePayment='force',saveMeiSettings='updateMei',createMei='createMei'})[key]
    for _,ok in ipairs({true,false,1})do
        case(key..' side effects '..tostring(ok),function(r)r.results[method]=table.pack(ok,'result',nil,4);local success,result=r.callback(key,1,{enabled=true});assert(success==ok and result=='result')end)
    end
end
case('save forwards forced gang',function(r)local ok=r.callback('saveGroup',1,{name='ballas',type='gang',grades={}});assert(ok)end)
case('save forwards nil input',function(r)r.save=false;local ok=r.callback('saveGroup',1,nil);assert(not ok)end)
case('delete forwards type/name',function(r)assert(r.callback('deleteGroup',1,'gang','ballas'))end)
case('late result has no callback-layer recheck',function(r)
    r.services.JobPoints.toggleDuty=function(src)r.record('before-yield',src);coroutine.yield('wait');r.record('after-yield',src);return true end
    local co=coroutine.create(function()return r.callback('toggleDuty',1,'police','station')end);assert(coroutine.resume(co));assert(coroutine.resume(co))
end)
print('PASS '..n..' job callback differential cases; 23 complete descriptors, arguments/multiple returns/broadcasts/start and inherited unfiltered payload; no public registrations')
