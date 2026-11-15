local root='../../../../.planning/migration/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('BOOT-CANDIDATE-280.json'));local count=0
for _,e in ipairs(p.files)do
 if e.path:match('%.lua$')then
  local code=read('../../'..p.sources[e.from+1]..e.path)
  local chunk,problem=load(code,'@@candidate280/'..e.path,'t',{})
  assert(chunk,problem);count=count+1
 end
end
assert(count==601 and p.operationalReady==false and p.bootstrapGraphBuilt==false and #p.missing==0)
assert(#p.replacements==7)
print('PASS280 all'..count..' candidate Lua compile;no resource execution')
