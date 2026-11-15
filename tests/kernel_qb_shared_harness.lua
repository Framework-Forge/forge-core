local P=dofile('tests/kernel_player_harness.lua');local H=P.H;local T={H=H,P=P}
function T.shared(ported,starter)
    local r={};r.canonical={Vehicles={},VehicleHashes={},Locations={},Weapons={}}
    r.helpers={string={trim=function(v)return v:match('^%s*(.-)%s*$')end,capitalize=function(v)return v:sub(1,1):upper()..v:sub(2)end},
        math={round=function(v)return math.floor(v+.5)end},setVehicleExtras=function(...)return ... end,armsWithoutGloves={male={1},female={2}}}
    r.lib={math={groupdigits=function(v)return 'group:'..v end},string={random=function(pattern)return pattern end}}
    r.config={starterItems=starter};local env=H.environment()
    env.math.random=function()return 1 end
    env.string.strsplit=function(delimiter,str)return str:match('^(.-)'..delimiter..'(.*)$')end
    if ported then r.shared=H.load('kernel/compat/qb/shared.lua',env)({shared=r.canonical,config=r.config,lib=r.lib,helpers=r.helpers})
    else env.require=function(n)if n=='shared.main'then return r.canonical elseif n=='config.shared'then return r.config end;error(n)end
        env.lib=r.lib;env.qbx=r.helpers;r.shared=P.loadOrigin('bridge/qb/shared/main.lua',env)end
    return r
end
function T.converter(ported,items,list,opts)
    opts=opts or{};local r={items=H.copy(items),list=H.copy(list or{}),trace={},tasks={}}
    local function rec(k,...)r.trace[#r.trace+1]={k,P.snapshot(table.pack(...))}end
    local ports={inventory={readItemsFile=function()rec('read');if opts.readError then error('fixture_read')end;return opts.file or 'return {\n}'end,
        writeItemsFile=function(text,size)rec('write',text,size);if opts.writeError then error('fixture_write')end;return opts.writeResult end},
        trim=function(s)return s:match('^%s*(.-)%s*$')end,log=function(...)rec('log',...)end,
        scheduler={createThread=function(fn)r.tasks[#r.tasks+1]=fn;rec('schedule')end,wait=function(ms)rec('wait',ms)end}}
    local env=H.environment()
    if ported then r.api=H.load('../pr_bridge/bridge/compat/forge/qb_item_conversion_factory.lua',env)(ports)
    else
        env.LoadResourceFile=function(resource,file)assert(resource=='ox_inventory'and file=='data/items.lua');return ports.inventory.readItemsFile()end
        env.SaveResourceFile=function(resource,file,text,size)assert(resource=='ox_inventory'and file=='data/items.lua');return ports.inventory.writeItemsFile(text,size)end
        env.CreateThread=ports.scheduler.createThread;env.Wait=ports.scheduler.wait;env.print=ports.log;env.string.strtrim=ports.trim
        r.api=P.loadOrigin('bridge/qb/shared/compat.lua',env)
    end
    assert(#r.trace==0,'construction performed IO')
    r.run=function()local ok,err=pcall(r.api.convertItems,r.list,r.items);r.ok=ok;r.err=err and tostring(err):match('fixture_%w+');return ok end
    r.flush=function()for _,fn in ipairs(r.tasks)do fn()end end
    return r
end
return T
