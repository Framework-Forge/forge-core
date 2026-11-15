local T=dofile('tests/kernel_keybind_profile_harness.lua');local H=T.H
local factory=H.load('kernel/entry/native_foundation_profile.lua',H.environment())
for _,side in ipairs({'server','client'})do
 local r=T.new(side);local p=r.profilePorts;local open,close=0,0;local closed=false
 local f={Side=side,Seed=r.seed,Base=side=='server'and r.fixture.base or r.fixture.state,
 Public=p.public,RegistrationInput=p.bootstrap.registration,DomainLocale=r.configFixture144.locale,
 Locale=function(...)return ...end,IsCurrent=function()return not closed and r.seed.IsCurrent()end}
 local bootstrap
 f.BindBootstrap=function(b)assert(not bootstrap);bootstrap=b;return true end
 f.OpenObservers=function()assert(bootstrap.Transport.Progress().phase=='open');open=open+1;return true end
 f.Close=function()assert(bootstrap.Progress().complete);close=close+1;closed=true;return r.seed.Close()end
 f.Progress=function()return{complete=closed}end
 p.prCore.forgeNativeFoundation=f;p.rpc=p.prCore.forgeOwnedCallbacks
 local a=factory(f,p);assert(a.Seed==r.seed and a.Bootstrap==bootstrap and close==0 and open==0)
 assert(a.Prepare('pt-br'));r.surface.Open();assert(a.Install()and open==1);assert(p.prCore.forgeNativeSeed==r.seed)
 if side=='client'then r.runtimeImports.pollNative()end
 if side=='server'then
  r.api=a;r.emit('onResourceStart','forge-core');r.begin();if coroutine.status(r.co)~='dead'then r.resume()end
  assert(r.outcome[1]and r.outcome[2],tostring(r.outcome[3]or r.outcome[2]))
 else assert(a.Start())end
 a.Stop();r.clock.advance(1200000);assert(a.Poll()and close==1 and not r.seed.IsCurrent())
 assert(a.Progress().complete);r.platform.Close();if r.utilities then r.utilities.Close()end;r.finishProfile()
end
print('PASS181 actual166 graphs borrow one seed/base/RPC;observer install after transport;profile drains before foundation closes')
