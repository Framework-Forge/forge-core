local N=dofile('tests/kernel_multijob_harness.lua')
local H=N.H
H.same(N.config(true),N.config(false),'whole installed config')
N.case('default settings no file read',function(r)return r.api.getSettings()end)
for _,value in ipairs({-99,-1,0,1,3.9,50,500,'7','bad'})do
    N.case('maxJobs '..tostring(value),function(r)return r.api.saveSettings(2,{maxJobs=value})end)
end
for _,value in ipairs({true,false,1,0,'true','false','yes','SIM','sim','bad'})do
    N.case('booleans '..tostring(value),function(r)return r.api.saveSettings(2,{enabled=value,allowPlayerRemove=value,includeCurrentJob=value})end)
end
N.case('normalize names and dedup',function(r)
    return r.api.saveSettings(2,{blockedJobs={' Taxi ','TAXI','pol ice','!!!','abc-def','pol_ice'}})
end)
N.case('blocked nonlist',function(r)return r.api.saveSettings(2,{blockedJobs='taxi'})end)
N.case('settings non-table',function(r)return r.api.saveSettings(2,'bad')end)
N.case('settings permission',function(r)return r.api.saveSettings(1,{enabled=false})end)
N.case('console manage no notify',function(r)return r.api.saveSettings(0,{enabled=false})end)
N.case('load and clone returns',function(r)
    r.api.load();local x=r.api.getSettings();x.blockedJobs[1]='changed';return r.api.getSettings()
end)
N.case('load missing file',function(r)r.memory.files={};return r.api.load()end)
N.case('load invalid data',function(r)r.memory.seed(r.config.Storage.file,'invalid');return r.api.load()end)
N.case('save false keeps old settings',function(r)r.api.settings={maxJobs=2};r.failSave=true;return r.api.saveSettings(2,{maxJobs=8})end)
N.case('save throws',function(r)r.saveError=true;return r.api.saveSettings(2,{})end)
N.case('save nested wrapper guard',function(r)
    r.saveHook=function()r.saveHook=nil;return r.api.saveSettings(2,{maxJobs=8})end
    return r.api.saveSettings(2,{maxJobs=4})
end)
N.case('start explicit',function(r)return r.api.start()end)
N.case('start repeats load',function(r)r.api.start();return r.api.start()end)
N.case('no notify provider',function(r)r.library.notify=nil;return r.api.saveSettings(2,{})end)
N.case('debug callable table',function(r)
    r.library.debug=setmetatable({}, {__call=function(_,...)r.record('callable-debug',...)end})
    return r.api.start()
end)
N.case('get jobs disabled',function(r)r.api.settings={enabled=false};return r.api.getPlayerJobs(1)end)
N.case('get jobs invalid player',function(r)return r.api.getPlayerJobs(999)end)
N.case('include current and defaults',function(r)return r.api.getPlayerJobs(1)end)
N.case('exclude current',function(r)r.api.settings={includeCurrentJob=false};return r.api.getPlayerJobs(1)end)
N.case('blocked current',function(r)r.api.settings={blockedJobs={'police'}};return r.api.getPlayerJobs(1)end)
N.case('normalized stored invalid/dedup/grade',function(r)
    r.players[1].PlayerData.metadata.multijob={{name=' TAXI ',grade=9,custom=true},{name='taxi',grade=0},{name='missing'},{name='unemployed'},false}
    return r.api.getPlayerJobs(1)
end)
N.case('stored label kept, current not duplicated',function(r)
    r.players[1].PlayerData.metadata.multijob={{name='police',grade=4,label='Cached',addedAt='12'}}
    return r.api.getPlayerJobs(1)
end)
N.case('grade number/string fallback',function(r)
    r.jobs.taxi.grades={['0']={label='Zero'},['3']={name='Three',payment='30'}}
    r.players[1].PlayerData.metadata.multijob={{name='taxi',grade=-2},{name='police',grade=999}}
    return r.api.getPlayerJobs(1)
end)
N.case('GetJob error registry fallback',function(r)r.jobError=true;return r.api.getPlayerJobs(1)end)
N.case('GetJob non-table registry fallback',function(r)r.jobs.police=false;return r.api.getPlayerJobs(1)end)
N.case('metadata wrong type',function(r)r.players[1].PlayerData.metadata.multijob='bad';return r.api.getPlayerJobs(1)end)
N.case('numeric/string source stays exact',function(r)return r.api.getPlayerJobs('1')end)
print('PASS multijob settings/query: '..N.count..' differential cases; actual installed config/service/PR adapter and in-memory persistence, no real writes')

