local S = dofile('tests/kernel_job_service_harness.lua')
local count = 0
local function case(label,action,options)S.case(label,action,options);count=count+1 end
case('invalid console',function(r)return r.api.createMei(0,{label='Company'})end)
case('negative source',function(r)return r.api.createMei(-1,{label='Company'})end)
case('missing player',function(r)return r.api.createMei(8,{label='Company'})end)
case('missing payments',function(r)return r.api.createMei(1,{label='Company'})end,function(r)r.services.JobPayments=nil end)
case('disabled MEI',function(r)r.settings.mei.enabled=false;return r.api.createMei(1,{label='Company'})end)
case('missing settings',function(r)r.settings=nil;return r.api.createMei(1,{label='Company'})end)
case('missing mei settings',function(r)r.settings={};return r.api.createMei(1,{label='Company'})end)
for i,label in ipairs({'','  ','!!!','Taxi','  São João & Cia  ','ÁÉÍÓÚ Ç Ñ','A---B','A___B',123})do
    case('name '..i,function(r)return r.api.createMei(1,{label=label})end)
end
case('nil data',function(r)return r.api.createMei(1,nil)end)
case('default grades owner',function(r)
    local ok,group=r.api.createMei(1,{label='New Company'})
    assert(ok and group.owner=='A' and group.name=='new_company' and group.grades[0].isboss)
    assert(r.players[1].PlayerData.job.name=='new_company');return ok,group
end)
case('highest grade',function(r)return r.api.createMei(1,{label='Company',grades={['0']={name='Worker'},['7']={name='Boss'}}})end)
case('malformed grade',function(r)return r.api.createMei(1,{label='Company',grades={['2']=4}})end)
case('pending incident per citizen',function(r)r.api.incidents={['mei:A']={reason='unknown'}};return r.api.createMei(1,{label='Company'})end)
case('old incident for another citizen',function(r)r.api.incidents={['mei:B']={reason='unknown'}};return r.api.createMei(1,{label='Company'})end)
case('strict readiness',function(r)r.state='starting';return r.api.createMei(1,{label='Company'})end)
case('banking unavailable',function(r)return r.api.createMei(1,{label='Company'})end,function(r)r.library.banking=nil end)
case('society denied',function(r)r.societyResult=table.pack(false,'denied');return r.api.createMei(1,{label='Company'})end)
for _,reason in ipairs({'not_enough_money','government_charge_unknown','refund_failed'})do
    case('charge '..reason,function(r)r.chargeResult=table.pack(false,reason);return r.api.createMei(1,{label='Company'})end)
end
case('upsert failed refunds',function(r)
    r.registry.upsert=function()return false,'fixture-invalid'end
    return r.api.createMei(1,{label='Company'})
end)
case('upsert refund failed incident',function(r)
    r.registry.upsert=function()return false,'fixture-invalid'end;r.refundResult=false
    return r.api.createMei(1,{label='Company'})
end)
case('save failed refunds',function(r)r.saveResult=table.pack(false,'save_failed');return r.api.createMei(1,{label='Company'})end)
case('save refund failed incident',function(r)r.saveResult=table.pack(false,'save_failed');r.refundResult=false;return r.api.createMei(1,{label='Company'})end)
case('blocked save refunds',function(r)r.api.persistenceBlocked=true;return r.api.createMei(1,{label='Company'})end)
case('SetJob rejected ignored inherited',function(r)r.setJobResult=false;return r.api.createMei(1,{label='Company'})end)
case('SetJob exception ignored inherited',function(r)r.setJobError=true;return r.api.createMei(1,{label='Company'})end)
case('source changes after charge inherited',function(r)
    r.chargeHook=function()r.players[1]={PlayerData={source=1,citizenid='NEW',job={name='taxi'}}}end
    local ok,group=r.api.createMei(1,{label='Company'})
    assert(ok and group.owner=='A' and r.players[1].PlayerData.citizenid=='NEW' and r.players[1].PlayerData.job.name=='company')
    return ok,group
end)
case('repeat create rejects existing',function(r)
    assert(r.api.createMei(1,{label='Company'}));return r.api.createMei(1,{label='Company'})
end)
case('journal save failure still memory blocked',function(r)
    r.chargeResult=table.pack(false,'government_charge_unknown')
    r.memory.onWrite=function()return false end
    local ok,reason=r.api.createMei(1,{label='Company'})
    assert(not ok and reason=='reconciliation_required' and r.api.incidents['mei:A'])
    return r.api.createMei(1,{label='Another'})
end)
print(('PASS JobService MEI: %d differential cases, name/owner/grades/charge/refund/journal and retained late-session/SetJob failure behavior; Payments is a double'):format(count))
