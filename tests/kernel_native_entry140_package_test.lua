local root='../../../../.planning/migration/staging/140/'
local function read(path)local f=assert(io.open(root..path,'rb'));local text=f:read('*a');f:close();return text end
local package=test_decode_json(read('package.json'));local count=0
for _,file in ipairs(package.files)do if file.path:match('%.lua$')then assert(load(read(file.path),'@@package140/'..file.path,'t',{}));count=count+1 end end
assert(count==55 and package.previousPackage==135 and not package.operationalReady)
print('PASS lot140 all55 Lua in inactive58-file package compile;135 preserved and exact entry transform verified separately;no operational execution')
