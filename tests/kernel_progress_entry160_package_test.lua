local root='../../../../.planning/migration/staging/160/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('package.json'));local count=0
for _,f in ipairs(p.files)do if f.path:match('%.lua$')then assert(load(read(f.path),'@@package160/'..f.path,'t',{}));count=count+1 end end
assert(count==102 and #p.files==105 and p.previousPackage==155 and not p.operationalReady)
print('PASS160 all102 Lua compile in inactive105-file overlay;155 inheritance/exact shutdown derivation checked separately')
