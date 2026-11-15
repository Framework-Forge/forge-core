local T=dofile('tests/kernel_server_startup_harness.lua');local create=T.H.load('kernel/server/startup_schema.lua',T.H.environment())
local users='CREATE TABLE IF NOT EXISTS `users` (`userId` INT);'
local column='ALTER TABLE `players` ADD COLUMN IF NOT EXISTS `userId` INT UNSIGNED DEFAULT NULL AFTER `id`;'
local count=0
local function factory()
    local r={calls=0,valid=true,inspect=true};r.api=create({isCurrent=function()return r.valid end,
        execute=function(sql)r.calls=r.calls+1;if r.hook then r.hook()end;if r.fail then error('virtual SQL error')end;return nil,false,7 end,
        inspect=function()return r.inspect end})
    r.handler=function()r.api.Execute('users',users);r.api.Execute('playerUserId',column)end;return r
end
local function case(fn)fn();count=count+1 end
case(function()local r=factory();assert(r.calls==0);assert(r.api.Prepare(r.handler));assert(r.calls==2 and r.api.Progress().verified)
    local result=table.pack(r.api.Execute('users',users));assert(result.n==3 and result[2]==false and result[3]==7 and r.calls==2)
    assert(not pcall(r.api.Execute,'users',users..' ')and not r.api.Prepare(r.handler),'only exact completed statement replay')end)
case(function()local r=factory();assert(not r.api.Prepare(function()r.api.Execute('playerUserId',column)end));assert(r.calls==0)end)
case(function()local r=factory();r.fail=true;assert(not r.api.Prepare(r.handler)and r.calls==1);assert(not r.api.Prepare(r.handler))end)
case(function()local r=factory();r.inspect=false;assert(not r.api.Prepare(r.handler)and r.calls==2 and not r.api.Progress().verified)end)
case(function()local r=factory();r.hook=function()r.api.Close()end;assert(not r.api.Prepare(r.handler)and r.calls==1,'close prevents second DDL')end)
case(function()local r=factory();r.valid=false;assert(not r.api.Prepare(r.handler)and r.calls==0)end)
case(function()local r=factory();assert(not pcall(r.api.Execute,'users',users));assert(not r.api.Matches('users','DROP TABLE users'))end)
print('PASS lot61 schema '..count..' checks;two installed operations in order, exact replay tuples, failure/inspection/close;not general SQL cache or rollback')
