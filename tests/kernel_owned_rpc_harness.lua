local R=dofile('tests/kernel_callback_registration_harness.lua');local H=R.H;local T={R=R,H=H,path='kernel/pr_integration/callback_owner.lua'}
function T.new()
    local w=R.wire();w.prs={server={},client={}};w.scopes={};w.ports={}
    for _,side in ipairs({'server','client'})do
        local e=w[side];local base=e.env;local n={}
        -- Separate host registry at the export boundary. Full ox_host validation is
        -- additionally exercised by kernel_callback_public_host_test.
        e.publicRegistry=H.load('../pr_bridge/bridge/callback/registry.lua',H.environment({
            GetCurrentResourceName=function()return 'pr_bridge'end,
            GetInvokingResource=function()return 'forge-core'end,AddEventHandler=function()end}))
        base.exports={pr_bridge={oxService=function(_,name,...)
            local fn=({setValidCallback=e.publicRegistry.set,isCallbackValid=e.publicRegistry.valid})[name]
            assert(fn,'unexpected host service: '..tostring(name));return fn(...)
        end}}
        for _,key in ipairs({'GetCurrentResourceName','GetInvokingResource','GetGameTimer','GetConvarInt','DoesPlayerExist','TriggerClientEvent','TriggerServerEvent','SetTimeout','AddEventHandler','RemoveEventHandler','RegisterNetEvent'})do n[key]=base[key]end
        n.IsDuplicityVersion=function()return side=='server'end
        local p={native=n,prCore=w.prs[side],environment=base,getSource=function()return base.source end,isCurrent=function()return not w.stale end,
            available=function(_,wire)if w.foreign==wire then return false end;for _,v in ipairs(w.events[side])do if not v.removed and v.name==wire then return false end end;return true end,
            load=function(path,env)if w.loadHook then w.loadHook(side,path)end;return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',env)end}
        w.ports[side]=p;w.scopes[side]=H.load(T.path,H.environment())(p)
    end
    function w.open()assert(w.scopes.server.Open());assert(w.scopes.client.Open())end
    function w.close()w.scopes.server.Close();w.scopes.client.Close()end
    return w
end
return T
