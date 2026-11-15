--269: preserve candidate internals while its public Stop/Poll drain the owned activation worker.
local create=require 'kernel.entry.activation_driver'
return function(candidate,p)
 assert(candidate.ActivationDriver==nil,'candidate driver already bound')
 local progress=candidate.Progress
 local borrowed=setmetatable({Stop=candidate.Stop,Poll=candidate.Poll,Progress=progress,Activate=candidate.Activate},{__index=candidate})
 local input={};for k,v in pairs(p)do input[k]=v end;input.candidate=borrowed
 local driver=create(input);candidate.ActivationDriver=driver
 candidate.Stop=driver.Stop;candidate.Poll=driver.Poll
 candidate.Progress=function()
  local state=progress();state.driver=driver.Progress()
  state.complete=state.complete==true and state.driver.complete==true;return state
 end
 return driver
end
