local W=dofile('tests/kernel_weapon_harness.lua')
local total=0
local function scenario(mode,options,fn)local p=W.pair(mode,options);fn(p);total=total+p.count end
for _,mode in ipairs({'projection','ox_sync'})do
    scenario(mode,nil,function(p)
        p.run(mode..' initial',function(r)return r.api.syncAll()end)
        p.run(mode..' deactivate',function(r)r.records.weapon_pistol.active=false;return r.api.syncAll()end)
        p.run(mode..' restore',function(r)r.records.weapon_pistol.active=true;return r.api.syncAll()end)
        p.run(mode..' remove',function(r)r.records={};return r.api.syncAll()end)
        p.run(mode..' repeat empty',function(r)return r.api.syncAll()end)
        p.run(mode..' missing registry',function(r)r.services.WeaponRegistry=nil;return r.api.syncAll()end)
    end)
    for _,state in ipairs({'started','starting','stopped','uninitialized','restart'})do
        scenario(mode,function(r)
            r.qbxState=state;r.oxState=state
            r.records.weapon_pistol.ammotype='none';r.records.weapon_pistol.access={mode='admin'}
            r.records.weapon_pistol.client={anim='x'};r.records.weapon_pistol.oxName='CUSTOM'
        end,function(p)
            p.run(mode..' '..state,function(r)return r.api.syncAll()end)
            p.run(mode..' '..state..' remove tracked',function(r)r.records={};return r.api.syncAll()end)
        end)
    end
end
for _,method in ipairs({'CreateWeapons','RemoveWeapon'})do
    for _,value in ipairs({'false','nil','throw'})do
        scenario('projection',nil,function(p)
            p.run(method..' initial',function(r)r.api.syncAll()end)
            p.run(method..' '..value,function(r)
                r.results[method]=value=='throw'and'throw'or(value=='false'and table.pack(false)or table.pack(nil))
                if method=='RemoveWeapon'then r.records={}end
                assert(r.api.syncAll()==true);return r.api.registeredWeapons
            end)
        end)
    end
end
for _,method in ipairs({'SetWeaponItem','DisableWeaponItem','RemoveWeaponItem'})do
    for _,value in ipairs({'false','nil','throw'})do
        scenario('ox_sync',nil,function(p)
            p.run(method..' initial',function(r)r.api.syncAll()end)
            p.run(method..' '..value,function(r)
                r.results[method]=value=='throw'and'throw'or(value=='false'and table.pack(false)or table.pack(nil))
                if method=='RemoveWeaponItem'then r.records={}elseif method=='DisableWeaponItem'then r.records.weapon_pistol.active=false end
                assert(r.api.syncAll()==true);return r.api.registeredWeapons
            end)
        end)
    end
end
print('PASS '..total..' weapon projection/OX-sync differential cases; complete mapping/disabled/delete/starting/tracking and inherited false/nil/error acknowledgement behavior')
