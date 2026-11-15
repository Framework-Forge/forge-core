local T=dofile('tests/kernel_raw_pr_harness.lua');local count=0
local function case(fn)local r=T.new();fn(r);if r.raw then r.raw.Close()end;count=count+1 end
case(function(r)r.resource='qbx_core';assert(not pcall(r.allocate))end)
case(function(r)r.pr.forgeRawCore={};assert(not pcall(r.allocate))end)
case(function(r)r.ports.profile[1].path='bridge/frameworks/qbx/server';assert(not pcall(r.allocate))end)
case(function(r)r.public.banking={};assert(not pcall(r.allocate))end)
case(function(r)r.allocate();r.loadHook=function(_,env)assert(not pcall(env.PRCore.load,'@pr_bridge/bridge/compat/qb/main'))end;assert(r.raw.Prepare())end)
case(function(r)r.allocate();r.loadHook=function()r.raw.Close()end;assert(not r.raw.Prepare()and r.raw.Progress().complete and next(r.public)==nil)end)
case(function(r)r.allocate();assert(r.raw.Prepare());local held=r.public.banking.GetJobAccountBalance;local foreign={};r.public.banking=foreign
    assert(not pcall(held,'police'));assert(r.raw.Close()and r.public.banking==foreign)end)
case(function(r)r.allocate();assert(r.raw.Prepare());local held=r.public.banking.GetJobAccountBalance;r.current=false;assert(not pcall(held,'police'))end)
assert(count==8);print('PASS lot121 eight raw-scope identity/path/slot/current/reentry/Close cases;foreign provider preserved')
