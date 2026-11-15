local root='../../../../.planning/migration/'
local function read(p)local f=assert(io.open(root..p,'rb'));local s=f:read('*a');f:close();return s end
local p=test_decode_json(read('BOOT-CANDIDATE-220.json'));local count=0
for _,e in ipairs(p.files)do
 if e.path:match('%.lua$')then assert(load(read('../../'..p.sources[e.from+1]..e.path),'@@candidate220/'..e.path,'t',{}));count=count+1 end
end
assert(count==505 and p.operationalReady==false and p.bootstrapGraphBuilt==false and #p.missing==0)
assert(#p.replacements==1 and p.replacements[1].path=='forge-core/kernel/entry/boot_candidate_entry.lua')
print('PASS220 all'..count..' Lua compile in delivery;declared unified client/server entry replacement;no candidate scripts executed')
