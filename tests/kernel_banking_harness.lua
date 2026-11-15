-- Whole installed Renewed main + PR factory/adapter. SQL/cache/threads/UI/framework boundaries virtual.
local O=dofile('tests/kernel_inventory_operations_harness.lua');local H=O.H
local B={O=O,H=H,provider='../../../[standalone]/Renewed-Banking/server/main.lua'}
function B.new()
    local r={cache={},exported={},callbacks={},commands={},threads={},sql={},calls={},modes={},state='started',selected='Renewed-Banking',current=true}
    local function db(kind,sql,params)
        r.sql[#r.sql+1]={kind=kind,sql=H.copy(sql),params=H.copy(params)}
        if r.dbHook then r.dbHook(kind,sql,params)end
        if r.dbError==kind then error('virtual '..kind..' SQL error')end
        if r.dbFalse==kind then return false,'virtual SQL refusal'end
        return true
    end
    local library={cache={set=function(name,value)r.cache[name]=value end},database={},
        callback={register=function(name,fn)r.callbacks[name]=fn end},addCommand={add=function(name,options,fn)r.commands[name]=fn end}}
    for _,name in ipairs({'query','insert','update','execute','transaction'})do local kind=name
        library.database[name]=function(...)return db(kind,...)end
    end
    local env=H.environment({pr_lib=library,json={encode=function(t)return t end,decode=function(t)return H.copy(t)end},
        CreateThread=function(fn)r.threads[#r.threads+1]=fn end,locale=function(key)return key end,
        GetInvokingResource=function()return'forge-core'end,os={time=function()return 1000 end},print=function()end,
        exports=function(name,fn)r.exported[name]=fn end})
    env.math.random=function(a)return a end
    H.load(B.provider,env);r.env=env;r.accounts=assert(r.cache['Renewed-Banking:accounts'])
    assert(#r.threads==1,'installed hydration worker captured, never launched')
    r.proxy={}
    for name,fn in pairs(r.exported)do local method=name
        r.proxy[name]=function(self,...)
            assert(self==r.proxy);r.calls[#r.calls+1]={name=method,args=table.pack(...)}
            if r.exportHook then r.exportHook(method,...)end
            if r.modes[method]=='throw'then error('virtual '..method..' export error')end
            if r.modes[method]=='nil'then return nil end
            if r.modes[method]=='false'then return false end
            return fn(...)
        end
    end
    local e=H.environment({exports={['Renewed-Banking']=r.proxy},Bridge={framework=setmetatable({},{__index=function()error('forbidden self-framework cycle')end})},Debug=function()end})
    e.PRCore={load=function(name,scope)assert(name=='@pr_bridge/bridge/banking/factory');return H.load('../pr_bridge/bridge/banking/factory.lua',scope)end}
    r.public=H.load('../pr_bridge/bridge/banking/renewed/server.lua',e)
    local publicResource=r.public.GetResourceName;r.public.GetResourceName=function()return r.selected or publicResource()end
    r.factory=H.load('../pr_bridge/bridge/banking/forge_society.lua',H.environment())
    r.ports={banking=r.public,renewed=r.proxy,resourceState=function(name)assert(name=='Renewed-Banking');return r.state end,isCurrent=function()return r.current end}
    function r.mount()r.api=r.factory(r.ports);return r.api end
    function r.count(kind)local n=0;for _,d in ipairs(r.sql)do if d.kind==kind then n=n+1 end end;return n end
    function r.seed(name,balance)
        return r.exported.CreateJobAccount({name=name,label=name},balance or 0)
    end
    return r
end
function B.context()
    local r=O.context();r.bank=B.new()
    r.bankContextPorts={operationsContext=r.operationContextPorts,banking=r.bank.ports,createBanking=r.bank.factory}
    local env=O.P.T.T.W.D.R.env();env.print=function(...)r.fixture.central.record('print',...)end
    r.bankFactory=H.load('kernel/server/banking_context.lua',env)
    function r.prepareBanking()r.api=r.bankFactory(r.fixture.base,r.bankContextPorts);r.graph=r.api.Graph;r.bank.api=r.api.Banking;return r.api end
    function r.bankingInstall()r.wire.Initialize();r.surface.Open();return r.api.Install()end
    return r
end
return B
