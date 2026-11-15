local root='../../../../.planning/migration/staging/135/'
local function read(path)local f=assert(io.open(root..path,'rb'));local text=f:read('*a');f:close();return text end
local package=test_decode_json(read('package.json'));local count=0
for _,file in ipairs(package.files)do if file.path:match('%.lua$')then
    assert(load(read(file.path),'@@package135/'..file.path,'t',{}));count=count+1
end end
assert(count==48 and package.previousPackage==130 and not package.operationalReady)
print('PASS lot135 all48 Lua in inactive package compile;51 files,48 exact copies checked separately;no entry executed or operational writes')
