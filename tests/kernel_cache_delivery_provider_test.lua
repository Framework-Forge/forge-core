local T=dofile('tests/kernel_cache_delivery_harness.lua');local H,P=T.H,T.P
local a,b=T.provider(),T.provider();b.mount();assert(#b.trace==0 and b.api.Open(),'PR boundary construction/Open inert')
local old,new=a.writer(false),b.writer(true);local count=0
local function run(name,fn)
    local x,y=table.pack(pcall(fn,old,a)),table.pack(pcall(fn,new,b))
    H.same(P.snapshot(y),P.snapshot(x),name..' returns');H.same(b.trace,a.trace,name..' trace');H.same(b.snapshot(),a.snapshot(),name..' state');count=count+1
end
run('queue while stopped',function(w,r)r.state='stopped';w.record('playerData',{name='A',items={1,2},metadata={health=200}});return w.flush('init')end)
run('starting also queues',function(w,r)r.state='starting';w.patch('playerData',{name='B'});return w.flush('starting')end)
run('started delivery',function(w,r)r.state='started';return w.flush('ready')end)
run('idempotent flush',function(w)return w.flush('same')end)
run('small metadata patch',function(w)w.patch('playerData',{metadata={health=175}});return w.flush('patch')end)
run('copy inbound delta',function(w)local d={items={3,4}};w.patch('playerData',d);d.items[1]=999;return w.flush('copy')end)
run('replace removed fields',function(w)w.record('playerData',{name='C'});return w.flush('replace')end)
run('fields insert',function(w)w.fields('metadata:self:',{a=1,b=2});return w.flush('fields')end)
run('fields remove',function(w)w.fields('metadata:self:',{a=3});return w.flush('remove')end)
run('explicit nil',function(w)w.stage('metadata:self:a',nil);return w.flush('nil')end)
run('force replay cleared host',function(w,r)r.host.clear();return w.flush('bridge-start',true)end)
run('stopped replacement',function(w,r)r.state='stopped';w.record('playerData',{name='D'});return w.flush('stopped')end)
run('replay replacement',function(w,r)r.state='started';return w.flush('ready',true)end)
run('unknown patch',function(w)w.patch('absent',{x=1});return w.flush()end)
run('equal stage',function(w)w.stage('playerData',{name='D'});return w.flush('same')end)
run('false export is not ack checked',function(w,r)r.falseAccess=true;w.stage('cash',19);return w.flush('refused')end)
assert(b.host.get('cash')==nil)
run('unchanged record not retried after false',function(w,r)r.falseAccess=false;return w.flush('no retry')end)
assert(b.host.get('cash')==nil,'installed false-success policy retained')
run('force replay after false',function(w)return w.flush('replay',true)end)
assert(b.host.get('cash')==19)
run('export error',function(w,r)r.failAccess=true;w.stage('bank',9);return w.flush('error')end)
run('retry retained pending',function(w,r)r.failAccess=false;return w.flush('retry')end)
run('patch updates local value before error',function(w,r)r.failAccess=true;return w.patch('playerData',{name='E'})end)
run('equal patch after failure not retried',function(w,r)r.failAccess=false;return w.patch('playerData',{name='E'})end)
assert(b.host.get('playerData').name=='D','installed patch failure partial state retained')
run('force fixes projection only',function(w)return w.flush('force',true)end)
assert(b.host.get('playerData').name=='E'and count==23)
local methods=0
for _,colon in ipairs({false,true})do
    local left,right=T.provider(),T.provider();right.mount();assert(right.api.Open())
    local function invoke(r,ported,name,...)
        local cache=ported and r.api.Cache or r.localCache
        if colon then return cache[name](cache,...)end;return cache[name](...)
    end
    local function call(name,...)
        local x=table.pack(invoke(left,false,name,...));local y=table.pack(invoke(right,true,name,...))
        H.same(P.snapshot(y),P.snapshot(x),name);H.same(right.snapshot(),left.snapshot(),name..' state');methods=methods+1
    end
    call('set','playerData',{citizenid='A'});call('get','playerData');call('GetPlayer')
    call('patch','playerData',{money={cash=2}});call('set','metadata:self:health',170);call('GetMetadata','health')
    call('SetResourceState','qbx_core','session',{loaded=true});call('GetResourceState','qbx_core','session')
    call('set','forge-core:skills',{a=1});call('clear','forge-core:skills');call('clearPrefix','metadata:self:');call('clear','playerData')
end
assert(methods==24)
local passive=T.provider();passive.mount();assert(passive.api.Open());local notified=0
passive.localCache.onChange('playerData',function()notified=notified+1 end)
passive.api.Delivery.writeCache('set','playerData',{citizenid='A'});assert(notified==0,'installed PR cache never notifies automatically')
local metrics=passive.host.getMetrics();assert(not metrics.automaticCollection and not metrics.automaticNotifications and not metrics.automaticCleanup)
local x,y,z=passive.api.Delivery.emit('exact',1);assert(x==nil and y==false and z==17);assert(#passive.trace>0)
print('PASS lot71 provider:23 installed writer comparisons,24 cache dot/colon comparisons;whole PR host/client routing,partial failure/false-success and passive cache characterized;virtual only')
