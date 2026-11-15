--255: structural receipts narrow explicit external proofs;no inference from a running resource.
return function(p)
 local proofs={};for _,name in ipairs({'oxHooks','catalogs','banking','keys','decisions','environment'})do
  proofs[name]=assert(p.proofs[name],'effect proof required:'..name);assert(type(proofs[name])=='function')
 end
 local side=assert(p.side);assert(side=='server'or side=='client')
 local function live(g,e,r)
  return g==p.generation and e and r and e.Foundation and e.Foundation.Side==side and e.IsCurrent()
   and e.Bootstrap.Graph and r.Services and r.Services.Progress().phase=='open'
 end
 local function receipts(e)
  local graph=e.Bootstrap.Graph
  if side~='server'then return graph end
  local worker=assert(graph.Base.ServerWorkerContext,'canonical server worker required')
  local state=worker.Progress().initialization
  if not state or state.phase~='initialized'then return end
  local sequence=assert(worker.Initialization);local found={}
  for i,step in ipairs(sequence.Describe())do if state.ledger[i]=='completed'then found[step.name]=true end end
  for _,name in ipairs({'Central.Parts.Inventory.Service.Initialize','Central.Parts.Consumption.Service.Initialize','Central.Parts.Weapons.Service.Initialize'})do
   if not found[name]then return end
  end
  return graph
 end
 local out={}
 for name,proof in pairs(proofs)do out[name]=function(g,e,r)
  if not live(g,e,r)then return false end
  if name=='catalogs'and not receipts(e)then return false end
  if side=='server'and name=='oxHooks'then
   local owner=assert(r.Services.Inventory);local s=owner.Progress()
   if s.phase~='open'or s.unknown~=0 or s.removeFailed~=0 or s.publishing~=0 then return false end
   -- Hook tokens may be reused by the customized inventory;the proof must check its actual identity.
  end
  if side=='server'and(name=='banking'or name=='keys')then
   local owner=assert(r.Services[name=='banking'and'Banking'or'Keys'])
   if owner.Progress().phase~='open'then return false end
  end
  return proof(g,e.Bootstrap.Graph,r,e)==true
 end end
 return out
end
