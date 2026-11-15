local root='../../../../.planning/migration/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('BOOT-CANDIDATE-180.json'));local count=0
for _,e in ipairs(p.files)do
 if e.path:match('%.lua$')then assert(load(read('../../'..p.sources[e.from+1]..e.path),'@@candidate180/'..e.path,'t',{}));count=count+1 end
end
assert(count==465 and p.operationalReady==false and p.bootstrapGraphBuilt==false and #p.missing==0)
print('PASS180 all'..count..' Lua compile in full incremental delivery;no candidate scripts executed')
