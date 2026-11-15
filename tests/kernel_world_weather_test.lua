local R=dofile('tests/kernel_world_harness.lua')
local H,n=R.H,0
local function case(name,fn)R.case(name,fn);n=n+1 end
H.same(R.config(true),R.config(false),'whole local weather/density config');n=n+1
case('all callbacks described',function(r)local c=0;for _ in pairs(r.callbacks)do c=c+1 end;assert(c==10)end)
for _,key in ipairs({'getState','setWeather','setDuration','addWeather','removeWeather','setTime','setTimeScale','setFreezeTime'})do
    case('denied '..key,function(r)r.jobResult=false;local ok,err=r.w[key](2);assert(not ok and err=='no_permission')end)
end
case('raw truthy Job policy',function(r)r.jobResult=1;assert(r.w.canManage(0)==1)end)
case('Job policy throws',function(r)r.jobError=true;return r.w.canManage(2)end)
case('console ACE fallback',function(r)r.services.JobService=nil;r.ace=false;assert(r.w.canManage(0));assert(not r.w.canManage(2))end)
case('ACE true fallback',function(r)r.services.JobService=nil;assert(r.w.canManage(2))end)
case('get state through actual PR',function(r)local ok,v=r.w.getState(2);assert(ok and v.currentWeather.weather=='CLEAR')end)
case('weather bridge absent',function(r)r.library.weather=nil;local ok,e=r.w.getState(2);assert(not ok and e=='weather_bridge_unavailable')end)
case('weather method missing',function(r)r.library.weather.GetState=false;return r.w.getState(2)end)
case('resource stopped',function(r)r.resource='stopped';return r.w.getState(2)end)
case('provider throws',function(r)r.exportOverrides.GetSnapshot=function()error('fixture-weather',0)end;local ok= r.w.getState(2);assert(not ok)end)
case('current weather',function(r)return r.w.setWeather(2,'1','RAIN')end)
case('invalid type exact case',function(r)local ok,e=r.w.setWeather(2,1,'rain');assert(not ok and e=='invalid_weather')end)
case('type not configured',function(r)r.config.Weather.Types={};return r.w.setWeather(2,1,'CLEAR')end)
case('match fallback',function(r)return r.w.setWeather(2,0,'THUNDER',{weather='RAIN',time=20})end)
case('missing event adds',function(r)return r.w.setWeather(2,9,'SNOW',{time=7})end)
case('current export nil fallback',function(r)r.exportOverrides.SetWeatherType=function()return nil end;return r.w.setWeather(2,1,'RAIN')end)
case('current export false fallback',function(r)r.exportOverrides.SetWeatherType=function()return false end;return r.w.setWeather(2,1,'RAIN')end)
case('queue set false adds',function(r)r.exportOverrides.SetWeatherType=function()return false end;return r.w.setWeather(2,2,'RAIN',{time=9})end)
case('add false failure',function(r)r.exportOverrides.AddWeatherEvent=function()return false end;return r.w.setWeather(2,9,'RAIN')end)
for _,duration in ipairs({-10,0,1.9,1440,9999,'invalid'})do
    case('duration '..duration,function(r)return r.w.setDuration(2,2,duration,{weather='RAIN',time=20})end)
end
case('duration current fallback',function(r)r.exportOverrides.SetEventTime=function()return nil end;return r.w.setDuration(2,1,90)end)
case('duration missing adds',function(r)return r.w.setDuration(2,99,45,{weather='SNOW'})end)
case('duration missing error',function(r)return r.w.setDuration(2,nil,45)end)
case('add normalized',function(r)return r.w.addWeather(2,{weather='RAIN',duration=9999,index='3'})end)
case('add invalid data',function(r)return r.w.addWeather(2,false)end)
case('remove match',function(r)return r.w.removeWeather(2,0,{weather='RAIN',time=20})end)
case('remove missing success',function(r)local ok,e=r.w.removeWeather(2,9);assert(ok and e=='already_removed')end)
case('remove stopped inherited success',function(r)r.resource='stopped';local ok,e=r.w.removeWeather(2,9);assert(ok and e=='already_removed')end)
for _,v in ipairs({{-1,90},{99,-1},{12.9,30.9},{'bad','bad'}})do
    case('time '..tostring(v[1]),function(r)return r.w.setTime(2,table.unpack(v))end)
end
for _,v in ipairs({0,2000,5555.9,60000,99999,'bad'})do
    case('scale '..v,function(r)return r.w.setTimeScale(2,v)end)
end
for _,v in ipairs({true,false,'sim','NO',1,0})do
    case('freeze '..tostring(v),function(r)local ok=r.w.setFreezeTime(2,v);assert(ok)end)
end
case('freeze snapshot mismatch',function(r)r.exportOverrides.SetFreezeTime=function()return true end;assert(not r.w.setFreezeTime(2,true))end)
case('RPC handler same service',function(r)return r.callbacks[r.config.Weather.Callbacks.setTime](2,99,99)end)
print('PASS world weather differentials '..n)
