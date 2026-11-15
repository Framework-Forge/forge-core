--263: one registration ledger across raw/graph/compat consumers in this resource.
return function(p)
 local verify=assert(p.available);local current=assert(p.isCurrent);local exports,commands=assert(p.publishExport),assert(p.prCommand)
 local ox=assert(p.oxCommand);local owned={};local closed=false;local pending=0
 local api={OperationalReady=false}
 local function key(kind,name)return kind..':'..(kind=='command'and name:lower()or name)end
 local function live()return not closed and current()==true end
 function api.Available(kind,name)
  if not live()or type(name)~='string'or name==''or owned[key(kind,name)]then return false end
  pending=pending+1;local out=table.pack(pcall(verify,kind,name));pending=pending-1
  if not out[1]then error(out[2],0)end
  return live()and not owned[key(kind,name)]and out[2]==true
 end
 local function publish(kind,name,fn,provider,...)
  assert(type(fn)=='function','registration handler required')
  if not api.Available(kind,name)then return false end
  owned[key(kind,name)]='reserved';pending=pending+1
  local out=table.pack(pcall(provider,name,fn,...));pending=pending-1
  --Even refused/uncertain physical publication is not reused.
  owned[key(kind,name)]=out[1]and out[2]~=false and'published'or'uncertain'
  if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
 end
 local function command(name,properties,fn,provider,...)
  assert(type(fn)=='function');local list=type(name)=='table'and name or{name};local seen={}
  assert(#list>0,'command names required')
  for _,n in ipairs(list)do local k=key('command',n);assert(not seen[k],'duplicate command alias');seen[k]=true
   if not api.Available('command',n)then return false end
  end
  if not live()then return false end
  for k in pairs(seen)do if owned[k]then return false end end
  for k in pairs(seen)do owned[k]='reserved'end;pending=pending+1
  local out=table.pack(pcall(provider,name,properties,fn,...));pending=pending-1
  for k in pairs(seen)do owned[k]=out[1]and out[2]~=false and'published'or'uncertain'end
  if not out[1]then error(out[2],0)end;return table.unpack(out,2,out.n)
 end
 api.Registration={available=api.Available,
 publishExport=function(name,fn)return publish('export',name,fn,exports)end,
 prCommand=function(name,properties,fn,...)return command(name,properties,fn,commands,...)end,
 oxCommand=function(name,properties,fn,...)return command(name,properties,fn,ox,...)end}
 function api.Close()closed=true;return pending==0 end
 function api.Progress()
  local published,uncertain=0,0;for _,state in pairs(owned)do if state=='published'then published=published+1 else uncertain=uncertain+1 end end
  return{closed=closed,pending=pending,published=published,uncertain=uncertain,complete=closed and pending==0,physicalRemoval=false}
 end
 return api
end
