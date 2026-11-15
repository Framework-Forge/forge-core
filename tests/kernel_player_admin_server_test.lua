local R=dofile('tests/kernel_player_admin_harness.lua');local H=R.H;local n=0
local function case(name,fn)R.case(name,fn);n=n+1 end
H.same(R.config(true),R.config(false),'whole Player/PlayerManagement configs');n=n+1
case('personal info',function(r)local ok,p=r.info(1);assert(ok and p.age=='26'and p.birthdate=='22/10/2000'and p.job=='Police - Sergeant');return ok,p end)
case('personal invalid player',function(r)r.players[1]=nil;return r.info(1)end)
for _,date in ipairs({'2000-10-23','2000/10/21','23/10/2000','21-10-2000','bad','2099-10-01','','2000-99-50'})do case('date '..date,function(r)r.players[1].PlayerData.charinfo.birthdate=date;return r.info(1)end)end
case('charinfo aliases',function(r)r.players[1].PlayerData.charinfo={firstName='Alias',lastName='Name'};return r.info(1)end)
case('missing fields',function(r)r.players[1].PlayerData={source=1,citizenid='CID1'};return r.info(1)end)
for _,role in ipairs({'group.admin','unknown','',{'admin'},false})do case('staff extra '..tostring(type(role)),function(r)r.players[1].PlayerData.metadata[r.config.Staff.Metadata]=role;local ok,p=r.info(1);p.extra=type(p.extra)=='string'and p.extra:gsub('table: 0x%x+','table: address')or p.extra;return ok,p end)end
case('VIP info and detail',function(r)r.vips[1]={tier='gold',config={label='Gold'},expiresAt=1792638000};return r.info(1),r.service.details(2,1)end)
case('info no optional VIP',function(r)r.services.VipService=nil;return r.info(1)end)
case('list sorted native online',function(r)local ok,p=r.service.list(2);assert(ok and #p==2 and p[1].source==1 and p[2].source==2);return ok,p end)
case('list whitelist failure',function(r)r.wlOk=false;r.wl='denied';return r.service.list(2)end)
case('list VIP labels',function(r)r.vips[1]={tier='gold',config={label='Gold'},expiresAt=1792638000};return r.service.list(2)end)
case('list native name fallback',function(r)r.players[1].PlayerData.charinfo={};return r.service.list(2)end)
case('offline skipped',function(r)r.players[1]=nil;return r.service.list(2)end)
for _,method in ipairs({'list','details','whitelist'})do case('denied '..method,function(r)r.manage=false;local ok,e=r.service[method](1,1,true);assert(not ok and e=='no_permission');return ok,e end)end
case('missing JobService denies',function(r)r.services.JobService=nil;return r.service.list(2)end)
for _,id in ipairs({1,'1',99,'invalid',0})do case('details target '..tostring(id),function(r)return r.service.details(2,id)end)end
for _,grade in ipairs({3,{level=2,name='Sergeant'},{grade=1,label='Trainee'},{value=5}})do case('grade normalization '..tostring(type(grade)),function(r)r.players[1].PlayerData.job.grade=grade;return r.service.details(2,1)end)end
for _,permissions in ipairs({'admin',{'moderator','admin'},{admin=true,moderator=false},{permissions={'moderator','admin'}},{permissions={moderator=true,admin=true}}})do case('staff permissions normalized',function(r)
 r.players[1].PlayerData.metadata[r.config.Staff.Metadata]=permissions;local ok,p=r.service.details(2,1);assert(ok and type(p.staffPermissions)=='table');return ok,p
end)end
case('references preserved',function(r)local ok,p=r.service.details(2,1);assert(ok and p.money==r.players[1].PlayerData.money);p.money.cash=99;assert(r.players[1].PlayerData.money.cash==99)end)
case('available jobs sorted',function(r)local ok,p=r.service.details(2,1);assert(ok and p.availableJobs[1].value=='police'and p.availableJobs[1].grades[1].value=='0');return ok,p end)
case('jobs failure ignored',function(r)r.multiOk=false;r.multiPayload='no_jobs';return r.service.details(2,1)end)
case('whitelist record fallback',function(r)r.wlRecord={whitelisted=true,answers={a='ok'}};return r.service.details(2,1)end)
for _,enabled in ipairs({false,true,'false',0,1})do case('whitelist truthiness '..tostring(enabled),function(r)r.service.whitelist(2,'1',enabled);assert(r.calls[#r.calls][2]==(enabled and'add'or'remove'));return r.calls end)end
case('whitelist missing player',function(r)return r.service.whitelist(2,99,true)end)
case('personal source only',function(r)r.info(1);assert(r.trace[1].kind=='lookup'and r.trace[1].args[1]==1)end)
for _,key in ipairs({'list','details','whitelist','prisonSentence','prisonRelease'})do case('callback '..key,function(r)return r.handlers[r.config.PlayerManagement.Callbacks[key]](2,1,30)end)end
-- Error behavior is compared by class, not source line/path; no production sanitization is added.
case('malformed grade sort remains error',function(r)r.jobs.police.grades.bad={name='Bad'};local ok=pcall(r.service.details,2,1);assert(not ok);return ok end)
case('mixed staff permissions remains error',function(r)r.players[1].PlayerData.metadata[r.config.Staff.Metadata]={'admin',2};local ok=pcall(r.service.details,2,1);assert(not ok);return ok end)
print('PASS player admin server/config/info: '..n..' differential cases')
