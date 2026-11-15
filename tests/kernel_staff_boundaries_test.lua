local Q=dofile('tests/kernel_staff_harness.lua')
for _,key in ipairs({'getAll','getPlayers','catalog','add','remove'})do
    for _,src in ipairs({1,2})do
        Q.boundaryCase('callback '..key..src,function(r)
            local args={getAll={},getPlayers={{1,2}},catalog={},add={{source=1,role='mod'}},remove={{source=2}}}
            return r.callbacks[r.config.Callbacks[key]](src,table.unpack(args[key]))
        end)
    end
end
for _,native in ipairs({false,true})do
    for _,src in ipairs({0,1,2})do
        Q.boundaryCase('menu command '..tostring(native)..src,function(r)return r.command('forgestaff',src,{})end,native)
    end
    Q.boundaryCase('direct add '..tostring(native),function(r)
        local args=native and {'1','add','mod'}or{id={value=1},action={value='add'},role={value='mod'}}
        return r.command('staff',2,args)
    end,native)
    Q.boundaryCase('direct remove '..tostring(native),function(r)
        local args=native and{'1','rem'}or{id={value=2},action={value='remove'}}
        return r.command('staff',2,args)
    end,native)
    Q.boundaryCase('direct invalid '..tostring(native),function(r)return r.command('staff',2,{})end,native)
end
Q.boundaryCase('command access',function(r)
    for _,entry in ipairs(r.commands)do if entry.options then assert(entry.options.canAccess(2));assert(not entry.options.canAccess(1))end end
end)
Q.boundaryCase('menu await error',function(r)r.awaitError=true;return r.command('forgestaff',2,{})end)
Q.boundaryCase('forgeace denied',function(r)return r.command('forgeace',1,{})end)
Q.boundaryCase('forgeace non-status no mutation',function(r)return r.command('forgeace',2,{'apply','1'})end)
Q.boundaryCase('forgeace console',function(r)return r.command('forgeace',0,{'status','1'})end)
Q.boundaryCase('forgeace player',function(r)return r.command('forgeace',2,{'status','1'})end)
Q.boundaryCase('forgeace invalid target',function(r)return r.command('forgeace',2,{'status','bad'})end)
Q.boundaryCase('forgeace older status fallback',function(r)r.api.permissionDiagnostics=nil;return r.command('forgeace',2,{'status','1'})end)
Q.boundaryCase('direct failure notify',function(r)return r.command('staff',2,{id={value=999},action={value='add'},role={value='mod'}})end)
Q.boundaryCase('direct invalid action console log',function(r)return r.command('staff',0,{action={value='bad'}})end)
Q.boundaryCase('missing notify falls back debug',function(r)r.library.notify=nil;return r.command('staff',2,{action={value='bad'}})end)
print('PASS staff boundaries: '..Q.count..' differential cases; five callbacks/three commands PR+native modes, ACL/client-only/diagnostics/errors; no public bindings or real ACL')

