-- Run from forge-core with lua55.exe; no live player or database is used.
local language=dofile('locale/pt-br.lua')
local function t(key,vars)
    local value=language
    for part in key:gmatch('[^.]+') do value=value and value[part] end
    value=value or key
    for name,item in pairs(vars or {}) do value=value:gsub('%%{'..name..'}',tostring(item)) end
    return value
end
ForgeCore={t=t,Client={Menu={},MenuShared={t=t}}}
dofile('client/menu/menu_prison.lua')
local describe=ForgeCore.Client.MenuShared.prisonDescription
local text=describe({jailed=true,remainingMinutes=1501,sentence={amount=2,unit='days'},clock='real'})
assert(text:find('Status: Preso',1,true) and text:find('1 dias, 1 horas e 1 minutos',1,true))
assert(text:find('Pena original: 2 Dias',1,true) and not text:find('Contagem',1,true))
assert(describe({fugitive=true,status='fugitive',remainingMinutes=60}):find('Status: Foragido',1,true))
local available,state,metadata=true,{jailed=true,status='jailed'},{}
local changed=0
local job={label='Taxi',grades={['0']={name='Driver',payment=10}}}
pr_lib={load=function(path)
    assert(path=='@pr_bridge/bridge/prison/server')
    return {isAvailable=function() return available end,getStatus=function() return state end}
end,framework={
    GetPlayer=function() return {PlayerData={metadata=metadata}} end,
    GetPlayerData=function() return {job={name='taxi',grade=0}} end,
    GetPlayerMetadata=function() return {{name='taxi',grade=0}} end,
    SetPlayerJob=function() changed=changed+1;return true end,
}}
GetCurrentResourceName=function() return 'forge-core' end
dofile('../pr_bridge/bridge/persistence.lua')(pr_lib, function(path) return 'forge-core',path end)
TriggerClientEvent=function() end
exports={qbx_core={GetJob=function() return job end}}
dofile('server/player/prison.lua')
dofile('shared/multijob.lua')
dofile('server/multijob/service.lua')
local service=ForgeCore.MultiJobService
service.getSettings=function() return {enabled=true,blockedJobs={},includeCurrentJob=true} end
assert(not service.setActiveJob(1,'taxi') and changed==0,'Server must reject jailed job changes')
state={jailed=false,fugitive=true,status='fugitive'}
assert(service.setActiveJob(1,'taxi') and changed==1,'Fugitives may change jobs')
state={jailed=false,status='free'}
assert(service.setActiveJob(1,'taxi') and changed==2,'Free characters may change jobs')
state=nil;assert(not service.setActiveJob(1,'taxi') and changed==2,'Pending prison state cannot authorize a change')
available=false;metadata={injail=5,prisonStatus='jailed'}
assert(not service.setActiveJob(1,'taxi') and changed==2,'Known prisoners stay blocked if XT is stopped')
metadata={injail=0,prisonStatus='fugitive'}
assert(service.setActiveJob(1,'taxi') and changed==3)
print('PASS: localized status/days/hours/minutes/original sentence, jailed server rejection and fugitive/free job access')
