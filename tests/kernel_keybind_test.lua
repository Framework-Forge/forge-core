local T=dofile('tests/kernel_keybind_harness.lua')
for i,data in ipairs({{defaultKey='e'},{defaultKey='CTRL + E',secondaryKey='F2'},{keys={'shift','+'}},{allowUnbound=true}})do
 local a,b=T.new(false),T.new(true);local traces={{},{}}
 local function create(r,n)local p={name='key_'..i,description='desc'};for k,v in pairs(data)do p[k]=v end
 p.onPressed=function(bind)traces[n][#traces[n]+1]='press:'..tostring(bind.currentKey)end
 p.onReleased=function()traces[n][#traces[n]+1]='release'end;return r.lib(p)end
 local x,y=create(a,1),create(b,2);assert(x.defaultKey==y.defaultKey and #a.mappings==#b.mappings)
 for j,m in ipairs(a.mappings)do for k=1,m.n do assert(m[k]==b.mappings[j][k])end end
 local names={};for name in pairs(a.commands)do if name:sub(1,1)=='+'then names[#names+1]=name end end;table.sort(names)
 for _,name in ipairs(names)do a.fire(name);b.fire(name)end
 assert(x:isControlPressed()==y:isControlPressed());for _,name in ipairs(names)do a.fire('-'..name:sub(2));b.fire('-'..name:sub(2))end
 assert(table.concat(traces[1],',')==table.concat(traces[2],','));a.flush();b.flush();assert(#a.trace==#b.trace)
 assert(b.lib.get(y.name)==y and b.lib.remove(y.name)==true);assert(b.api.Close())
end
print('PASS164 four installed keybind parity traces:single/combo/secondary/aliases/unbound,mappings,callbacks,labels,timers/remove')
