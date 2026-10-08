-- One catalog drives local animations and validates replicated player posture.
ForgeCore.PostureContract={}
local Contract=ForgeCore.PostureContract
Contract.anims={
    female={{name='holding_elbow',
        enter={dict='amb@world_human_leaning@female@wall@back@holding_elbow@enter',anim='enter_front'},
        base={dict='amb@world_human_leaning@female@wall@back@holding_elbow@base',anim='base'},
        idles={{dict='amb@world_human_leaning@female@wall@back@holding_elbow@idle_a',anim='idle_a'},
            {dict='amb@world_human_leaning@female@wall@back@holding_elbow@idle_a',anim='idle_b'}},
        exit={dict='amb@world_human_leaning@female@wall@back@holding_elbow@exit',anim='exit_front'}}},
    male={{name='foot_up',
        enter={dict='amb@world_human_leaning@male@wall@back@foot_up@enter',anim='enter_back'},
        base={dict='amb@world_human_leaning@male@wall@back@foot_up@base',anim='base'},
        idles={{dict='amb@world_human_leaning@male@wall@back@foot_up@idle_a',anim='idle_b'},
            {dict='amb@world_human_leaning@male@wall@back@foot_up@idle_b',anim='idle_e'}},
        exit={dict='amb@world_human_leaning@male@wall@back@foot_up@exit',anim='exit_front'}},
        {name='legs_crossed',
        enter={dict='amb@world_human_leaning@male@wall@back@legs_crossed@enter',anim='enter_back'},
        base={dict='amb@world_human_leaning@male@wall@back@legs_crossed@base',anim='base'},
        idles={{dict='amb@world_human_leaning@male@wall@back@legs_crossed@idle_a',anim='idle_a'},
            {dict='amb@world_human_leaning@male@wall@back@legs_crossed@idle_a',anim='idle_c'}},
        exit={dict='amb@world_human_leaning@male@wall@back@legs_crossed@exit',anim='exit_front'}}}
}
local allowed={}
for _,profiles in pairs(Contract.anims) do
    for _,profile in ipairs(profiles) do
        for _,kind in ipairs({'enter','base','exit'}) do
            local anim=profile[kind];allowed[anim.dict..'/'..anim.anim]=true
        end
        for _,anim in ipairs(profile.idles) do allowed[anim.dict..'/'..anim.anim]=true end
    end
end
function Contract.finite(n) return type(n)=='number' and n==n and math.abs(n)<math.huge end
function Contract.normalize(kind,value)
    if kind~='sit' and kind~='lean' then return false end
    if value==nil or value==false then return true,nil end
    if type(value)~='table' or type(value.coords)~='table' or not Contract.finite(value.heading) then return false end
    local coords={}
    for _,axis in ipairs({'x','y','z'}) do
        local n=value.coords[axis]
        if not Contract.finite(n) or math.abs(n)>100000 then return false end
        coords[axis]=n
    end
    local result={coords=coords,heading=value.heading%360}
    if kind=='sit' then
        local found=value.scenario=='WORLD_HUMAN_LEANING' or value.scenario=='WORLD_HUMAN_PICNIC'
            or value.scenario=='WORLD_HUMAN_SEAT_LEDGE'
        for _,scenario in ipairs(PR.Sit.Scenarios or {}) do if scenario==value.scenario then found=true end end
        if not found or (value.inPlace~=nil and type(value.inPlace)~='boolean') then return false end
        result.scenario=value.scenario;result.inPlace=value.inPlace==true
    else
        if type(value.dict)~='string' or type(value.anim)~='string' or not allowed[value.dict..'/'..value.anim] then return false end
        if value.duration~=nil and (not Contract.finite(value.duration) or value.duration< -1 or value.duration>60000) then return false end
        for _,key in ipairs({'looped','advanced'}) do
            if value[key]~=nil and type(value[key])~='boolean' then return false end
            result[key]=value[key]==true
        end
        result.dict=value.dict;result.anim=value.anim;result.duration=value.duration
    end
    return true,result
end
