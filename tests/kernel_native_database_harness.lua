local T=dofile('tests/kernel_native_configuration_harness.lua');local H=T.H
local M={T=T,H=H,path='../pr_bridge/bridge/database/forge_native_await.lua'}
function M.new()
    local r={current=true,state='started',calls={},callbacks={},result={{value=3}},resultWrite={affectedRows=4},defer=false,fail=false}
    local exports={oxmysql={}}
    for _,name in ipairs({'query','execute','insert','scalar','transaction','prepare','rawExecute'})do exports.oxmysql[name]=function(self,sql,params,cb)
        assert(self==exports.oxmysql);r.calls[#r.calls+1]={name,sql,params};if r.fail then error('virtual db failure')end
        local result=name=='query'and r.result or name=='execute'and r.resultWrite or name=='transaction'and true or 17
        if r.defer then r.callbacks[#r.callbacks+1]=function()cb(result)end else cb(result)end
    end end
    local env=H.environment({ActiveBridges={database='oxmysql'},exports=exports,Debug=function()end,
        GetResourceState=function()return r.state end,promise={new=function()return{resolve=function(self,v)self.value=v;self.done=true end}end},
        Citizen={Await=function(p)if not p.done then coroutine.yield('database132')end;return p.value end}})
    r.provider=H.load('../pr_bridge/bridge/database/oxmysql/server.lua',env)
    r.ports={database=r.provider,isCurrent=function()return r.current end};r.factory=H.load(M.path,H.environment())
    function r.mount()r.api=r.factory(r.ports);r.db=r.api.Database;return r.api end
    function r.deliver()local q=r.callbacks;r.callbacks={};for _,fn in ipairs(q)do fn()end end
    return r
end
return M
