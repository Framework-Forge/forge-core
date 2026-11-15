local T=dofile('tests/kernel_progress_environment_harness.lua');local r=T.new();local a,b=T.factory.Names(),T.factory.Names();a[1]='changed';assert(b[1]=='GetCurrentResourceName')
r.bindings.localPlayer={};assert(not pcall(r.build));r.bindings.localPlayer=r.environment.LocalPlayer
r.bindings.settings={};assert(not pcall(r.build));r.bindings.settings=r.settings
r.bindings.getUI=nil;assert(not pcall(r.build));r.bindings.getUI=function()return r.ui end
r.executionFixture.api.Close();assert(not pcall(r.build));print('PASS153 five names/state/settings/UI/current checks;no collector or global patch')
