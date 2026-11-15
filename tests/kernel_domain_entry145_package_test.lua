local root='../../../../.planning/migration/staging/145/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('package.json'));local count=0
for _,file in ipairs(p.files)do if file.path:match('%.lua$')then assert(load(read(file.path),'@@package145/'..file.path,'t',{}));count=count+1 end end
assert(count==88 and #p.files==91 and p.previousPackage==140 and not p.operationalReady)
print('PASS145 all88 Lua in inactive91-file overlay compile;candidate-only provenance independent of pending historical gate inclusion')
