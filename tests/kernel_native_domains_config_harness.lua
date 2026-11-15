local H=dofile('tests/kernel_harness.lua');local T={H=H}
function T.new()
    local r={current=true,reads=0,loads={}};local env=H.environment();env._ENV=env
    r.vec3=function(x,y,z)return{x=x,y=y,z=z}end
    r.getConvar=function(k,d)r.reads=r.reads+1;return k=='inventory:imagepath'and'images/custom///'or d end
    r.locale=function()return{t=function(_,key)return't:'..key end}end
    r.ports={vec3=r.vec3,getConvar=r.getConvar,locale=r.locale,isCurrent=function()return r.current end,
        requireLocal=function(name)r.loads[#r.loads+1]=name;return H.load(name:gsub('%.','/')..'.lua',env)end}
    r.factory=H.load('kernel/entry/native_domain_configuration.lua',env)
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.original()
        local e=H.environment({PR={},ForgeCore={},GetConvar=r.getConvar,vec3=r.vec3,vector3=r.vec3,pr_lib={locale=r.locale}})
        H.load('shared/config.lua',e)
        for _,n in ipairs({'job','player','afk','password','weather','whitelist','density','weapons','inventory','vehicles','skills','staff','multijob','vinewood',
            'objects','npcs','npcs_animations','npcs_peds','spotlights','billboards','stores','farms','starterpack','database_backup','automedic','vip','player_management','character_slots'})do
            H.load('shared/'..n..'.lua',e)
        end
        return e.PR
    end
    return r
end
return T
