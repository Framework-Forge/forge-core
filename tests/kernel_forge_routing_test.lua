local P=dofile('tests/kernel_player_harness.lua');local H=P.H;local count=0
local function fixture(ported,backend,qb,compat)
    local active={frameworks=backend};local config={compatFramework=compat,compatQBCore=qb};local metadata={consumer={'esx','qb','qbx'}};local reads=0
    local r={active=active,config=config,metadata=metadata,current=true}
    if ported then r.api=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active=active,config=config,
        contracts={qb=true,qbx=true},resourceName='forge-core',isCurrent=function()return r.current end,
        readDeclarations=function(owner)reads=reads+1;return metadata[owner]end})
    else r.api=H.load('../pr_bridge/bridge/compat/framework_routing.lua',H.environment({
        GetNumResourceMetadata=function(owner,key)reads=reads+1;assert(key=='pr_bridge_framework');return #(metadata[owner]or{})end,
        GetResourceMetadata=function(owner,_,i)return(metadata[owner]or{})[i+1]end}))(active,config)end
    function r.reads()return reads end;return r
end
for _,backend in ipairs({'qbx','qb','esx','ox','nd','tmc','default'})do
    for _,compat in ipairs({'on','off'})do for _,qb in ipairs({true,false})do
        local a,b=fixture(true,backend,qb,compat),fixture(false,backend,qb,compat)
        for _,list in ipairs({{'esx','qb'},{'qb','esx','qbx'},{'ox'},{'qbx_core','qb-core'},{'es_extended'},{'unknown'},{}})do
            H.same(table.pack(a.api.select(list)),table.pack(b.api.select(list)));count=count+1
        end
        for _,name in ipairs({'QB-CORE','qbx_core','es_extended','core','unknown'})do
            assert(a.api.isNative(name)==b.api.isNative(name));count=count+1
        end
        local aa=table.pack(pcall(a.api.assertAllowed,'esx','consumer'));local bb=table.pack(pcall(b.api.assertAllowed,'esx','consumer'))
        if not aa[1]then aa[2]=aa[2]:gsub('^.-:%d+: ','');bb[2]=bb[2]:gsub('^.-:%d+: ','')end
        H.same(aa,bb);count=count+1
        pcall(a.api.assertAllowed,'esx','consumer');pcall(b.api.assertAllowed,'esx','consumer');assert(a.reads()==1 and b.reads()==1)
        a.api.forget('consumer');b.api.forget('consumer');pcall(a.api.assertAllowed,'esx','consumer');pcall(b.api.assertAllowed,'esx','consumer');assert(a.reads()==2 and b.reads()==2)
    end end
end
local f=fixture(true,'forge',true,'on')
assert(f.api.select({'qb','forge','qbx'})=='forge'and f.api.select({'esx','qbx','qb'})=='qbx')
assert(f.api.select({'esx','qb'})=='qb'and f.api.select({'forge-core'})=='forge')
assert(not pcall(f.api.assertAllowed,'esx','consumer'));f.api.Close();assert(f.api.Progress().complete)
local absent=H.load('../pr_bridge/bridge/frameworks/forge/routing_factory.lua',H.environment())({active={frameworks='forge'},config={compatFramework='off'},contracts={},
    isCurrent=function()return true end,readDeclarations=function()return{}end})
assert(not absent.isNative('qb')and not absent.isNative('qbx')and absent.select({'qb','qbx'})==nil,'no automatic native QB/QBX capability')
print('PASS lot85 routing:'..count..' installed-route comparisons/7 destinations/switches,owner metadata cache/forget,Forge exact/family priority and explicit capability refusal;virtual only')
