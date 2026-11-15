local R=dofile('tests/kernel_world_harness.lua')
local n=0
local function case(name,fn)R.menuCase(name,fn);n=n+1 end
case('density parent',function(r)assert(r.menu.openDensityMenu());assert(r.last.menu=='forge_core_server_settings'and #r.last.options==4)end)
case('denied read',function(r)r.densityHook=function()return false,'no_permission'end;assert(not r.menu.openDensityMenu())end)
case('malformed read fallback',function(r)r.densityHook=function()return true,false end;assert(r.menu.openDensityMenu())end)
for i,answers in ipairs({{'true','false','true'},{0.1,0.2,0.3,0.4,0.5},{2,1},{'false'}})do
    case('editor save '..i,function(r)r.menu.openDensityMenu();r.inputs={answers};r.select(i);r.runTimers()end)
    case('editor cancel '..i,function(r)r.menu.openDensityMenu();r.select(i)end)
    case('editor denied '..i,function(r)r.menu.openDensityMenu();r.inputs={answers};r.densityHook=function()return false,'no_permission'end;r.select(i);r.runTimers()end)
end
case('sliders exact range',function(r)
    r.inputHook=function(_,fields)assert(#fields==5);for _,f in ipairs(fields)do assert(f.type=='slider'and f.min==0 and f.max==1 and f.step==0.1)end;return nil end
    r.menu.openDensityValuesEditor({})
end)
case('double editor lock keeps mutation',function(r)r.menu.openDensityMenu();local ctx=r.last;r.inputs={{2,1},{0,0}};r.select(3,ctx);r.select(3,ctx);r.runTimers()end)
case('timer unlock',function(r)r.inputs={{2,1},{1,2}};r.menu.openDensityPopulationEditor({});r.runTimers(1000);r.menu.openDensityPopulationEditor({})end)
case('late snapshot overwrite preserved',function(r)r.menu.openDensityMenu();local ctx=r.last;r.densitySettings.enabled=false;r.inputs={{2,1}};r.select(3,ctx);assert(r.densitySettings.enabled)end)
for _,value in ipairs({'started','stopped','error','false','nil'})do
    case('weather panel '..value,function(r)
        r.resources['Renewed-Weathersync']=value=='stopped'and'stopped'or'started'
        r.panelError=value=='error'
        if value=='nil'then r.panelResult=nil else r.panelResult=value~='false'end
        local ok=r.menu.openWeatherTimeMenu()
        assert(ok==(value=='started'or value=='nil'))
    end)
end
case('weather custom resource',function(r)r.config.Weather.Resource='custom-weather';assert(r.menu.openWeatherTimeMenu())end)
case('parent routes weather',function(r)r.menu.openServerSettingsMenu();r.select(4)end)
case('parent routes density',function(r)r.menu.openServerSettingsMenu();r.select(6)end)
print('PASS world menu differentials '..n)
