local R=dofile('tests/kernel_automedic_client_harness.lua')
local n=0
local function case(name,fn)R.case(name,fn);n=n+1 end
case('construct',function(r)return r.fn('isDead')()end)
case('native-health',function(r)r.dead=false;r.data.metadata={};r.health=100;assert(r.fn('isDead')())end)
case('native-fatal',function(r)r.dead=false;r.data.metadata={};r.health=200;r.fatal=true;assert(r.fn('isDead')())end)
case('metadata-dead',function(r)r.dead=false;r.health=200;r.data.metadata={dead=true};assert(r.fn('isDead')())end)
case('data-dead',function(r)r.dead=false;r.health=200;r.data.metadata={};r.data.dead=true;assert(r.fn('isDead')())end)
case('laststand-policy',function(r)r.dead=false;r.health=200;r.data.metadata={inlaststand=true};assert(not r.fn('isDead')())end)
case('grace',function(r)r.state.reviveGraceUntil=r.now+100;assert(not r.fn('isDead')())end)
case('auth-false',function(r)r.dead=false;r.health=200;r.library.cache.SetResourceState('qbx_core','session',{authenticated=false})
    assert(not r.fn('isDead')())end)
for _,cause in ipairs({'GROUP_PISTOL','GROUP_SMG','GROUP_RIFLE','GROUP_MG','GROUP_SHOTGUN','GROUP_SNIPER','GROUP_HEAVY'})do
    case('classify-'..cause,function(r)r.cause=cause;assert(r.fn('classify')()=='gunshot')end)
end
for _,mode in ipairs({'hunger','thirst','bleeding','injuries','other'})do
    case('classify-'..mode,function(r)
        r.data.metadata={};if mode=='hunger'or mode=='thirst'then r.status[mode]=0
        elseif mode=='bleeding'then r.data.metadata.bleeding='2'
        elseif mode=='injuries'then r.data.metadata.injuries={a={leg={bleeding=1}}}end
        assert(r.fn('classify')()==(mode=='other'and'other'or'collapse'))
    end)
end
case('status-dedupe',function(r)r.fn('showStatus')('hello','x');r.fn('showStatus')('hello','y');r.fn('hideStatus')();r.fn('hideStatus')()end)
case('status-provider-missing',function(r)r.library.ShowTextUI=nil;r.fn('showStatus')('hello')end)
for _,kind in ipairs({'disabled','dead','full','cancelled','success','late-disabled','late-ped','error'})do
    case('bandage-'..kind,function(r)
        r.health=150;r.dead=false;r.data.metadata={}
        if kind=='disabled'then r.state.settings={enabled=false}
        elseif kind=='dead'then r.dead=true
        elseif kind=='full'then r.health=200
        elseif kind=='error'then r.useError=true end
        local ret=r.exports.useBandage({name='bandage',slot=2},99)
        if kind=='success'or kind=='late-disabled'or kind=='late-ped'then
            if kind=='late-disabled'then r.state.settings.enabled=false end
            if kind=='late-ped'then r.ped=77;r.data={citizenid='C2',metadata={isdead=true}};r.health=100 end
            r.use(true)
            if kind=='success'then assert(ret==true and r.health==170)
            elseif kind=='late-ped'then assert(r.health==120)end
        elseif kind=='cancelled'then r.use(false);assert(r.health==150)end
        return ret
    end)
end
case('death-report-once',function(r)r.fn('reportDeath')();r.fn('reportDeath')();r.advance(501)end)
case('death-report-cleared',function(r)r.fn('reportDeath')();r.fn('resetDeathState')();r.advance(501)end)
case('death-report-new-session',function(r)r.fn('reportDeath')();r.fire('forge-core:session:changed',0);r.fn('reportDeath')();r.advance(501)end)
case('refresh-status',function(r)r.fn('refreshStatus')();assert(r.state.settings.cooldown==0)end)
case('refresh-status-fail',function(r)r.awaitHook=function()return false,'unavailable'end;r.fn('refreshStatus')()end)
case('refresh-status-error',function(r)r.awaitHook=function()error('fixture-rpc',0)end;r.fn('refreshStatus')()end)
case('request-error',function(r)r.awaitHook=function()error('fixture-rpc',0)end;r.fn('dispatchMedic')()end)
case('request-cooldown',function(r)r.awaitHook=function()return false,'cooldown',65 end;r.fn('dispatchMedic')()end)
case('request-denied',function(r)r.awaitHook=function()return false,'disabled'end;r.fn('dispatchMedic')()end)
case('request-lifecycle-changed',function(r)r.awaitHook=function()r.fire('forge-core:session:changed',0);return true,{token='old'}end;r.fn('dispatchMedic')();assert(not r.state.active)end)
case('npc-model-fallback',function(r)r.model=false;r.start('dispatchMedic');r.advance(10100);assert(not r.state.active)end)
case('npc-spawn-fallback',function(r)r.spawnFail=true;r.start('dispatchMedic');r.advance(10);assert(not r.state.active)end)
case('npc-arrives-complete',function(r)r.config.AutoMedic.Npc.crowdControl.enabled=false;r.config.AutoMedic.Npc.treatmentDuration=100
    r.start('dispatchMedic');r.advance(500);assert(not r.state.active)end)
case('npc-progress-cancel',function(r)r.config.AutoMedic.Npc.crowdControl.enabled=false;r.config.AutoMedic.Npc.treatmentDuration=100;r.progressResult=false
    r.start('dispatchMedic');r.advance(500);assert(not r.state.active)end)
case('npc-progress-fallback',function(r)r.config.AutoMedic.Npc.crowdControl.enabled=false;r.config.AutoMedic.Npc.treatmentDuration=100;r.library.progressBar=nil
    r.start('dispatchMedic');r.advance(500);assert(not r.state.active)end)
case('npc-complete-denied',function(r)r.config.AutoMedic.Npc.crowdControl.enabled=false;r.config.AutoMedic.Npc.treatmentDuration=100
    local old=r.library.callback.await;r.awaitHook=function(name)
        if name==r.config.AutoMedic.Callbacks.completeTreatment then return false,'no_money'end
        return true,{token='T1'}
    end;r.start('dispatchMedic');r.advance(500);assert(not r.state.active)end)
case('npc-stop',function(r)r.start('dispatchMedic');r.advance(1);r.fire('onResourceStop',0,'forge-core');r.advance(500)end)
case('revive-source-rejected',function(r)r.fire(r.config.AutoMedic.Events.revive,1);assert(r.health==100)end)
case('revive-local',function(r)r.config.AutoMedic.Npc.wakeup.enabled=false;r.fire(r.config.AutoMedic.Events.revive,65535);r.advance(10);assert(r.health==110 and not r.dead)end)
case('sync-disable-active',function(r)r.state.active=true;r.state.token='T';r.fire(r.config.AutoMedic.Events.sync,0,{enabled=false})end)
case('metadata-clear',function(r)r.fn('reportDeath')();r.dead=false;r.health=120;r.data.metadata={};r.fire('qbx_core:client:onSetMetaData',0,'isdead',true,false);r.advance(1)end)
case('spawn-dead-metadata',function(r)r.fire('playerSpawned',0);r.advance(1001)end)
case('spawn-alive',function(r)r.dead=false;r.health=150;r.status.health=50;r.data.metadata={};r.fire('playerSpawned',0);r.advance(1001)end)
print('PASS AutoMedic client runtime differentials '..n)
