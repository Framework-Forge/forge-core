local H=dofile('tests/cache_harness.lua')
local names={'objects','npcs','spotlights','billboards','stores','farms','starterpack','density','vinewood'}
local vector
vector=function(x,y,z,w)
    return setmetatable({x=x or 0,y=y or 0,z=z or 0,w=w},{
        __vector=true,__sub=function(a,b) return vector(a.x-b.x,a.y-b.y,a.z-b.z) end,
        __len=function(a) return math.sqrt(a.x^2+a.y^2+a.z^2) end,
    })
end
for _,name in ipairs(names) do
    local r=H.new(false);local e=r.env
    local old=getmetatable(e).__index
    setmetatable(e,{__index=function(t,key)
        local value=old[key]
        if value~=nil then return value end
        for _,prefix in ipairs({'Set','Remove','Clear','Delete','Freeze','Destroy','Enable','Disable','Hide','Render'}) do
            if key:sub(1,#prefix)==prefix then return function() end end
        end
    end})
    e.vector3=vector;e.vec3=vector;e.vector4=vector;e.vec4=vector;e.joaat=function() return 1 end
    e.type=function(value)
        local mt=getmetatable(value)
        if type(mt)=='table' and mt.__vector then return value.w and 'vector4' or 'vector3' end
        return type(value)
    end
    e.pr_lib.math={toVector=function(value) return vector(value.x,value.y,value.z) end}
    e.PlayerPedId=function() return 1 end;e.PlayerId=function() return 1 end
    e.GetEntityCoords=function() return vector(0,0,0) end;e.DoesEntityExist=function() return true end
    e.RegisterCommand=function() end;e.GetFrameCount=function() return 0 end
    e.IsControlJustPressed=function() return false end;e.IsPedInAnyVehicle=function() return false end
    local groups={job={name='police',grade=2},gang={name='lost',grade={level=1}}}
    e.ForgeCore.Session={isLoaded=function() return true end,group=function(kind) return groups[kind] end}
    e.ForgeCore.t=function(key) return key end
    local values,listeners={},{}
    e.ForgeCore.State={peek=function(key) return values[key] end,get=function(key) return H.copy(values[key]) end,
        onChange=function(key,fn) listeners[key]=fn end}
    local function update(value) values[name]=value;if listeners[name] then listeners[name](value) end end
    local target,zoneId,removed=nil,0,0
    e.pr_lib.target={addBoxZone=function() zoneId=zoneId+1;return zoneId end,removeZone=function() removed=removed+1 end,
        addLocalEntity=function(_,options) target=options[1] end,removeLocalEntity=function() end,disableTargeting=function() end}
    e.pr_lib.fivem={streaming={createPed=function() return 42 end,createObject=function() return 43 end}}
    r.load('shared/'..name..'.lua');r.load('client/'..name..'/main.lua')
    if name=='density' then
        local applied
        e.SetPedDensityMultiplierThisFrame=function(value) applied=value end
        update({enabled=true,revision=1,values={peds=0.23}});r.advance(0);assert(applied==0.23)
        update({enabled=false,revision=2,values={peds=1}});r.advance(1);assert(applied==0)
    elseif name=='vinewood' then
        update({enabled=false,revision=1});r.advance(0);update({enabled=false,revision=2})
    else
        assert(listeners[name],'Missing subscription for '..name)
        update({enabled=false,settings={enabled=false},prologue={enabled=false}});r.advance(0)
        if name=='objects' then
            update({enabled=false,objects={{id=1,model='prop_box',coords={x=1,y=2,z=3}}}})
            assert(e.ForgeCore.Client.Objects.get(1));update(nil);assert(not e.ForgeCore.Client.Objects.get(1))
        elseif name=='npcs' then
            update({enabled=true,npcs={{id=1,model='a_m_m_business_01',coords={x=0,y=0,z=0},
                interaction={mode='target',label='test',access={job='police',grade=2}}}}})
            r.advance(1200);assert(target and target.canInteract(),'Numeric job grade must be readable from session cache')
            groups.job={name='taxi',grade={level=3}};assert(not target.canInteract())
            update({enabled=true,npcs={{id=1,model='a_m_m_business_01',coords={x=0,y=0,z=0},
                interaction={mode='target',label='test',access={gang='lost',gangGrade=1}}}}})
            assert(target.canInteract(),'Gang data must be readable from session cache')
            update(nil);assert(next(e.ForgeCore.Client.Npcs.entries)==nil)
        elseif name=='stores' then
            update({settings={enabled=true},stores={{id='test',enabled=true,coords={x=1,y=2,z=3},blip={enabled=false}}}})
            assert(zoneId==1);update(nil);assert(removed==1 and #e.ForgeCore.Client.Stores.zones==0)
        elseif name=='farms' then
            update({settings={enabled=false},farms={}});update(nil);assert(#e.ForgeCore.Client.Farms.zones==0)
        elseif name=='billboards' then
            update({enabled=true,billboards={{id=1,enabled=true,vertices={}}}})
            assert(#e.ForgeCore.Client.Billboards.entries==1);update(nil);assert(#e.ForgeCore.Client.Billboards.entries==0)
        elseif name=='starterpack' then
            update(nil);assert(not e.ForgeCore.Client.Starterpack.payload)
        elseif name=='spotlights' then update(nil);assert(next(e.ForgeCore.Client.Spotlights.lights)==nil) end
    end
    r.fire('onResourceStop',nil,'forge-core')
    print('PASS world consumer: '..name)
end
