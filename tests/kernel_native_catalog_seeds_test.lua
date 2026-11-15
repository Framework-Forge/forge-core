local H=dofile('tests/kernel_harness.lua')
for _,name in ipairs({'jobs','gangs','weapons','locations'})do
 local function read(path)local f=assert(io.open(path,'rb'));local s=f:read('*a');f:close();return s end
 local origin=read('../../../[qbx]/qbx_core/shared/'..name..'.lua')
 local port=read('kernel/shared/'..name..'.lua')
 assert(port:gsub('%s+$','')==origin:gsub('%s+$',''),'catalog drift:'..name)
 local a,b=assert(load(origin))(),H.load('kernel/shared/'..name..'.lua',H.environment())
 local function eq(x,y)assert(type(x)==type(y));if type(x)=='table'then for k,v in pairs(x)do eq(v,y[k])end;for k in pairs(y)do assert(x[k]~=nil)end else assert(x==y)end end
 eq(a,b)
end
assert(H.load('kernel/shared/jobs.lua',H.environment()).unemployed)
assert(H.load('kernel/shared/gangs.lua',H.environment()).none)
print('PASS171 four installed catalog seeds preserved apart from final whitespace;no QBX runtime dependency')
