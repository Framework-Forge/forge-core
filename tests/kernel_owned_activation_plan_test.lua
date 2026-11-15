local H=dofile('tests/kernel_native_foundation_harness.lua').H
local create=H.load('kernel/entry/owned_activation_plan.lua',H.environment())
local log={};local function mark(s)log[#log+1]=s;return true end
local barrier={Progress=function()return{generation='234'}end}
local entry={Bootstrap={Progress=function()return{phase='installed'}end}}
local raw={Services={Progress=function()return{phase='open'}end}}
local closed={};local pending=true
local function owner(name)
 return{Progress=function()return{complete=closed[name]==true}end,
 Close=function()mark('close:'..name);if name=='consumers'and pending then return false end;closed[name]=true;return true end}
end
local pub,cons,ready=owner('pub'),owner('consumers'),owner('ready')
pub.Prepare=function(c)assert(c);return mark('publication:prepare')end
pub.ObservePrepared=function()return mark('observe')end
pub.Install=function()return mark('publish')end
cons.Prepare=function()return mark('consumers:prepare')end
cons.Attach=function()return mark('attach')end
ready.Arm=function(c)assert(c);return mark('arm')end
local candidate={Prepare=function()return mark('prepare')end,Install=function()return mark('install')end,
 GetPreparedEntry=function()return entry end,GetPreparedRaw=function()return raw end,GetPreparedBarrier=function()return barrier end,
 ClosePreparedCore=function()return mark('core:close')end}
local p=create{barrier=barrier,generation='234',publication=pub,consumers=cons,readiness=ready}
for i=1,6 do assert(p.steps[i].run(barrier,'234',candidate))end
assert(table.concat(log,',')=='prepare,publication:prepare,consumers:prepare,observe,install,publish,attach,arm')
assert(p.steps[6].close());assert(not p.steps[5].close());assert(p.steps[4].close())
assert(p.steps[3].close());assert(p.steps[2].close());assert(not p.steps[1].close())
assert(log[#log]~='core:close')
pending=false;assert(p.steps[5].close());assert(p.steps[1].close());assert(log[#log]=='core:close')
assert(not pcall(create,{barrier=barrier,generation='wrong',publication=pub,consumers=cons,readiness=ready}))
print('PASS234 owned A-F operations; pending consumer retains core; passive checks own nothing')
