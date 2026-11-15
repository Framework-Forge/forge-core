local root='../../../../.planning/migration/staging/155/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('package.json'));local count=0
for _,f in ipairs(p.files)do if f.path:match('%.lua$')then assert(load(read(f.path),'@@package155/'..f.path,'t',{}));count=count+1 end end
assert(count==97 and #p.files==100 and p.previousPackage==150 and not p.operationalReady)
print('PASS155 all97 Lua compile in inactive100-file overlay;150 inheritance/progress entry derivation checked separately')
