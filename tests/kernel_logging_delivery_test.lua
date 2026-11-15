local R=dofile('tests/kernel_support_context_harness.lua');local r=R.logging();r.mount()
assert(#r.requests==0 and #r.libraryCalls==0,'logging scope constructor inert');assert(r.api.Open())
assert(table.pack(r.api.LibraryLogger(2,'money','virtual',nil)).n==0)
assert(#r.batchRequests==0 and #r.libraryCalls==1);r.api.Close();r.clock.advance(500)
assert(#r.batchRequests==1,'accepted shared PR batch may flush after private Close')
assert(r.api.Progress().complete and r.api.Progress().SharedBatchOwned==false,'complete only covers private delegation not PR timer')
local late=R.logging();late.mount();assert(late.api.Open());late.defer=true;local fired=false
late.api.HttpRequest('virtual://discord',function()fired=true end,'POST','body',{})
late.api.Close();assert(late.api.Progress().pendingHTTP==1 and not late.api.Progress().complete)
late.callbacks[1](204,'',{});assert(not fired and late.api.Progress().complete,'late HTTP reply drains without old callback body')
local uncertain=R.logging();uncertain.mount();assert(uncertain.api.Open());uncertain.httpError=true
assert(not pcall(uncertain.api.HttpRequest,'virtual://discord',function()end,'POST','body',{}));uncertain.api.Close()
assert(uncertain.api.Progress().unknownHTTP==1 and not uncertain.api.Progress().complete,'published then throw has explicit uncertain HTTP residual')
local ordinary=R.logging();ordinary.mount();assert(ordinary.api.Open());ordinary.status=500
local status;ordinary.api.HttpRequest('virtual://discord',function(code)status=code end)
assert(status==500 and ordinary.api.Progress().pendingHTTP==0)
ordinary.current=false;assert(ordinary.api.LibraryLogger(2,'late','refused')==nil and #ordinary.libraryCalls==0)
print('PASS lot67 installed PR logging/fivemanage batch and explicit HTTP:constructor inert,shared late send,pending reply revocation,uncertain publication,no real network')
