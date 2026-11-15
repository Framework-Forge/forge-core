--234: operations A-F over one prepared candidate. Passive checks own no registrations.
return function(p)
 local barrier,generation=assert(p.barrier),assert(p.generation)
 local publication,consumers,readiness=assert(p.publication),assert(p.consumers),assert(p.readiness)
 assert(barrier.Progress().generation==generation,'activation generation mismatch')
 local candidate
 local function bind(c)
  assert(c and (not candidate or candidate==c),'activation candidate changed');candidate=c
  return c
 end
 local function structural(c)
  local entry,raw=c.GetPreparedEntry(),c.GetPreparedRaw()
  assert(entry and raw and c.GetPreparedBarrier()==barrier,'prepared identity mismatch')
  assert(raw.Services.Progress().phase=='open','raw providers not open')
  local phase=entry.Bootstrap.Progress().phase
  assert(phase=='installed'or phase=='running','bootstrap not installed')
  if entry.Capabilities then assert(entry.Capabilities.IsReady(),'client capabilities not ready')end
  return true
 end
 local steps={}
 steps[1]={name='A-prepare',run=function(b,g,c)
  assert(b==barrier and g==generation);bind(c)
  local ok,why=c.Prepare();if ok~=true then return false,why end
  ok,why=publication.Prepare(c);if ok~=true then return false,why end
  ok,why=consumers.Prepare();if ok~=true then return false,why end
  return publication.ObservePrepared()
 end,close=function()
  --227 visits lower stages even while an upper cleanup is pending. Keep the core alive.
  local clean=true
  for _,owner in ipairs({readiness,consumers,publication})do
   if not owner.Progress().complete then local ok,v=pcall(owner.Close);if not ok or v~=true then clean=false end end
   if not owner.Progress().complete then clean=false end
  end
  if not clean then return false end
  if not candidate then return true end
  return candidate.ClosePreparedCore()
 end}
 steps[2]={name='B-install-core',run=function(_,_,c)bind(c);return c.Install()end,
  close=function()return true end} -- Core ownership belongs to A; do not close it twice.
 steps[3]={name='C-observe-core',run=function(_,_,c)return structural(bind(c))end,
  close=function()return true end} -- Read-only observation.
 steps[4]={name='D-publish',run=function(_,_,c)structural(bind(c));return publication.Install()end,
  close=function()return publication.Close()end}
 steps[5]={name='E-attach-consumers',run=function(_,_,c)structural(bind(c));return consumers.Attach()end,
  close=function()return consumers.Close()end}
 steps[6]={name='F-arm-readiness',run=function(_,_,c)structural(bind(c));return readiness.Arm(c)end,
  close=function()return readiness.Close()end}
 return{barrier=barrier,generation=generation,steps=steps}
end
