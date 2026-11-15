local T=dofile('tests/kernel_transport_harness.lua')
local n=0
local function case(label,action,options)n=n+1;T.case('commands',label,action,options)end
case('three library descriptors',function(r)assert(#r.commands==3);for _,v in ipairs(r.commands)do assert(v.mode=='library')end end)
for _,mode in ipairs({'library','native'})do
    for _,src in ipairs({0,1})do
        for _,allow in ipairs({true,false})do
            case('open '..mode..src..tostring(allow),function(r)
                r.allow=allow
                for _,i in ipairs({1,3})do local cmd=r.commands[i];if cmd.options then assert(cmd.options.canAccess(src)==allow)end;cmd.handler(src,{},'raw')end
            end,function(r)if mode=='native'then r.library.command=nil end end)
        end
    end
end
for _,args in ipairs({{}, {'Taxi'}, {'2','Test','Company'}, {'0','Company'}, {'100','Company'}, {'-2','Company'}, {'3.9','Company'}})do
    case('MEI arguments',function(r)r.commands[2].handler(1,args,'raw')end)
end
case('MEI console refused',function(r)r.commands[2].handler(0,{},'raw')end)
for _,failure in ipairs({'denied','nil','false'})do
    case('MEI refusal '..failure,function(r)r.results.createMei=table.pack(false,failure~='nil'and failure or nil);r.commands[2].handler(1,{},'raw')end)
end
case('no notifier',function(r)r.results.createMei=table.pack(false);r.commands[2].handler(1,{},'raw')end,function(r)r.library.notify=nil end)
case('no console debug',function(r)r.commands[2].handler(0,{},'raw');r.commands[1].handler(0)end,function(r)r.library.debug=nil end)
case('await result ignored',function(r)r.results.await=table.pack(false,'timeout');r.commands[1].handler(1)end)
case('native fallback wraps fourth argument',function(r)for _,cmd in ipairs(r.commands)do assert(cmd.mode=='native'and cmd.restricted==false)end;r.commands[2].handler(1,{'2','Fallback'},'raw')end,function(r)r.library.command=nil end)
print('PASS '..n..' job command differential cases; three PR/native descriptors, menu access/await/console/notify and MEI grade/argument policy; no commands installed')
