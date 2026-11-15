--249: hold the existing entry until accepted origin-scoped calls have drained.
return function(entry,origin)
 assert(entry.ActivationOriginOwner==nil,'entry origin already bound')
 entry.ActivationOriginOwner=origin
 local stop,poll,isCurrent,progress=entry.Stop,entry.Poll,entry.IsCurrent,entry.Progress
 local closing,delegated=false,false
 function entry.Stop()
  closing=true;if not origin.Close()then return false end
  delegated=true;return stop()
 end
 function entry.Poll()
  if not closing then return false,'entry_not_stopping'end
  if not origin.Close()then return false end
  if not delegated then delegated=true;return stop()end
  return poll()
 end
 function entry.IsCurrent()return not closing and origin.IsCurrent()and isCurrent()end
 function entry.Progress()
  local out=progress();out.origin=origin.Progress();out.complete=out.complete==true and out.origin.complete==true;return out
 end
 return entry
end
