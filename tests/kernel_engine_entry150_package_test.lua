local root='../../../../.planning/migration/staging/150/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('package.json'));local count=0
for _,f in ipairs(p.files)do if f.path:match('%.lua$')then assert(load(read(f.path),'@@package150/'..f.path,'t',{}));count=count+1 end end
assert(count==93 and #p.files==96 and p.previousPackage==145 and not p.operationalReady)
print('PASS150 all93 Lua compile in inactive96-file overlay;inherited145 and engine146-149 entry derivation checked separately')
