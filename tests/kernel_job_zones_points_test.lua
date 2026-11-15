local Z=dofile('tests/kernel_job_zones_harness.lua')
local total=0
local function scenario(options,body)local p=Z.pair('points',options);body(p);total=total+p.count end
scenario(nil,function(p)
    p.run('full job/gang stash/duty',function(r)r.refresh();assert(#r.api.zones==3)end)
    p.run('live permissions',function(r)
        assert(r.option('forge_core_stash_job').canInteract());r.data.job={name='taxi',grade=0}
        assert(not r.option('forge_core_stash_job').canInteract());return r.option('forge_core_stash_gang').canInteract()
    end)
    p.run('old selection still requests server after group lost',function(r)
        r.inputs={{'secret'}};return r.select('forge_core_stash_job')
    end)
    p.run('replacement refresh',function(r)r.data.job={name='police',grade=4};r.refresh();return #r.api.zones end)
    p.run('stash success',function(r)r.inputs={{'pw'}};return r.select('forge_core_stash_job')end)
    p.run('stash cancel',function(r)return r.select('forge_core_stash_job')end)
    p.run('stash refusal',function(r)r.inputs={{'bad'}};r.results[r.config.Callbacks.openStash]=table.pack(false,'bad_password');return r.select('forge_core_stash_job')end)
    p.run('duty true',function(r)r.results[r.config.Callbacks.toggleDuty]=table.pack(true,true);return r.select('forge_core_duty')end)
    p.run('duty false',function(r)r.results[r.config.Callbacks.toggleDuty]=table.pack(true,false);return r.select('forge_core_duty')end)
    p.run('duty refused',function(r)r.results[r.config.Callbacks.toggleDuty]=table.pack(false,'refused');return r.select('forge_core_duty')end)
end)
for _,variant in ipairs({'low-grade','other-group','upper-case','scalar-grade','grade-grade','grade-value','missing-job','missing-gang',
    'disabled-point','stash-disabled','duty-disabled','no-coords','invalid-coords','vector-input','coords-fallback','blank-title',
    'custom-label','custom-rotation','normal-id','gang-only','empty','default-size','custom-size','debug','no-target','no-add',
    'zero-id','false-id','data-false','get-data-missing','fallback-job','no-access','negative-grade','disabled-string'})do
    scenario(function(r)
        local point=r.payload.jobs[1].stashes[1]
        if variant=='low-grade'then r.data.job.grade=0
        elseif variant=='other-group'then r.data.job.name='taxi'
        elseif variant=='upper-case'then r.data.job.name='POLICE';r.payload.jobs[1].name='Police'
        elseif variant=='scalar-grade'then r.data.job.grade='4'
        elseif variant=='grade-grade'then r.data.job.grade={grade='4'}
        elseif variant=='grade-value'then r.data.job.grade={value='4'}
        elseif variant=='missing-job'then r.data.job=nil
        elseif variant=='missing-gang'then r.data.gang=nil
        elseif variant=='disabled-point'then point.enabled=false
        elseif variant=='stash-disabled'then point.stash.enabled=false
        elseif variant=='duty-disabled'then point.duty.enabled=false
        elseif variant=='no-coords'then point.coords=nil;point.duty.coords=nil
        elseif variant=='invalid-coords'then point.coords='bad';point.duty.coords={x='bad'}
        elseif variant=='vector-input'then point.coords=Z.B.vector(1,2,3)
        elseif variant=='coords-fallback'then point.stash.coords={4,5,6}
        elseif variant=='blank-title'then point.title=' '
        elseif variant=='custom-label'then point.stash.label='Custom';point.duty.label='Duty'
        elseif variant=='custom-rotation'then point.rotation='90';point.stash.rotation=0;point.duty.rotation='180'
        elseif variant=='normal-id'then point.id='  Main @@ Desk--  '
        elseif variant=='gang-only'then r.payload.jobs={}
        elseif variant=='empty'then r.payload={}
        elseif variant=='default-size'then r.config.Points.targetSize=nil;r.config.Points.targetDistance=nil
        elseif variant=='custom-size'then r.config.Points.targetSize=Z.B.vector(2,3,4)
        elseif variant=='debug'then r.debugEnabled=true;r.notifyPosition='bottom'
        elseif variant=='no-target'then r.library.target=nil
        elseif variant=='no-add'then r.library.target.addBoxZone=nil
        elseif variant=='zero-id'then r.addHook=function()return 0 end
        elseif variant=='false-id'then r.addHook=function()return false end
        elseif variant=='data-false'then r.data=false
        elseif variant=='get-data-missing'then r.access.GetPlayerData=nil
        elseif variant=='fallback-job'then r.access.GetPlayerData=function()return false end;r.jobInfo={jobName='police',grade='4'}
        elseif variant=='no-access'then r.access.GetPlayerData=nil;r.access.GetJobInfo=nil
        elseif variant=='negative-grade'then point.stash.minGrade=-1;r.data.job.grade=-1
        elseif variant=='disabled-string'then point.enabled='false' end
    end,function(p)p.run(variant,function(r)r.refresh();return #r.api.zones end)end)
end
scenario(function(r)r.payload.jobs[1].stashes[1].stash.password=' 'end,function(p)
    p.run('blank password bypasses input',function(r)r.refresh();return r.select('forge_core_stash_job')end)
    p.run('missing callback reports unavailable',function(r)r.library.callback=nil;return r.select('forge_core_stash_job')end)
    p.run('missing notify is silent',function(r)r.library.Notify=nil;return r.select('forge_core_stash_job')end)
end)
scenario(nil,function(p)
    p.run('missing input cancels',function(r)r.refresh();r.library.menus=nil;return r.select('forge_core_stash_job')end)
    p.run('provider exception propagates',function(r)r.awaitError=true;r.library.menus={InputDialog=function()return {'pw'}end};return pcall(r.select,'forge_core_stash_job')end)
end)
print('PASS '..total..' client Points differential cases; full zones/access/IDs/config, password/stash/duty/PR messages, fallback/returns/errors')

