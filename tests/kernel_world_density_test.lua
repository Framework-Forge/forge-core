local R=dofile('tests/kernel_world_harness.lua')
local H,n=R.H,0
local function case(name,fn)R.case(name,fn);n=n+1 end
case('defaults and detached reads',function(r)local v=r.d.getSettings();assert(v.values.parked==0.8);v.values.parked=99;assert(r.d.getSettings().values.parked==0.8)end)
case('load publishes',function(r)r.d.load();assert(r.state.get('density').values.peds==0.8)end)
case('start idempotent',function(r)assert(r.d.start());local rev=r.state.getRecord('density').revision;assert(r.d.start());assert(r.state.getRecord('density').revision==rev)end)
case('revision fresh each read',function(r)local a=r.d.getSettings().revision;r.now=r.now+1;assert(r.d.getSettings().revision==a+1)end)
case('permission refusal',function(r)r.jobResult=false;local ok,e=r.d.save(2,{});assert(not ok and e=='no_permission')end)
case('permission raw truthy',function(r)r.jobResult=1;return r.d.save(2,{})end)
case('Job policy error',function(r)r.jobError=true;return r.d.canManage(2)end)
case('console fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.d.canManage(0));assert(not r.d.canManage(2))end)
case('saving before start',function(r)return r.d.save(2,{enabled=false})end)
for _,v in ipairs({-3,0,0.04,0.05,0.34,0.35,0.99,1,15,'bad'})do
    case('density '..v,function(r)return r.d.save(2,{values={parked=v,vehicle=v,multiplier=v,peds=v,scenario=v}})end)
end
for _,v in ipairs({-1,0,2.9,3,99,'bad'})do
    case('population '..v,function(r)return r.d.save(2,{pedPopulationBudget=v,vehiclePopulationBudget=v})end)
end
case('bools aliases',function(r)return r.d.save(2,{enabled='sim',disableAll='yes',disableDispatchServices='0',blacklist={enabled='false'}})end)
case('lists merge by index',function(r)local ok,v=r.d.save(2,{blacklist={models={'custom'}}});assert(ok and v.blacklist.models[1]=='custom'and v.blacklist.models[2]=='LUXOR')end)
case('empty list retains defaults',function(r)local ok,v=r.d.save(2,{blacklist={models={}}});assert(ok and #v.blacklist.models>1)end)
case('bad list drops empty entries',function(r)return r.d.save(2,{blacklist={models={'',false,123},scenarioTypes=false,scenarioGroups=false}})end)
case('areas filter and coords',function(r)return r.d.save(2,{generatorAreas={{distance=0},{distance=-1},{distance='3.5',coords={x='8',y='bad'}},false}})end)
case('failed write no publication',function(r)r.d.start();r.m.onWrite=function()return false end;local rev=r.state.getRecord('density').revision;local ok,e=r.d.save(2,{enabled=false});assert(not ok and e=='save_failed');assert(r.state.getRecord('density').revision==rev)end)
case('failed load starts flag first',function(r)r.library.loadJsonRecovery=function()error('fixture-read',0)end;return r.d.start()end)
case('publish error after save',function(r)r.state.publish=function()error('fixture-publish',0)end;return r.d.save(2,{})end)
case('unstarted entity ignored',function(r)r.models={[1]=r.native.joaat('RHINO')};r.fire('entityCreating',nil,1)end)
case('blocked entity cancelled',function(r)r.d.start();r.models={[1]=r.native.joaat('rhino')};r.fire('entityCreating',nil,1)end)
case('unknown entity accepted',function(r)r.d.start();r.models={[1]=r.native.joaat('random')};r.fire('entityCreating',nil,1)end)
case('disabled ignores blacklist',function(r)r.d.start();r.d.save(2,{enabled=false});r.models={[1]=r.native.joaat('RHINO')};r.fire('entityCreating',nil,1)end)
case('disabled blacklist accepted',function(r)r.d.start();r.d.save(2,{blacklist={enabled=false}});r.models={[1]=r.native.joaat('RHINO')};r.fire('entityCreating',nil,1)end)
case('read callback denial',function(r)r.jobResult=false;return r.callbacks[r.config.Density.Callbacks.getSettings](2)end)
case('save callback local',function(r)return r.callbacks[r.config.Density.Callbacks.saveSettings](2,{values={peds=0.5}})end)
print('PASS world density differentials '..n)
