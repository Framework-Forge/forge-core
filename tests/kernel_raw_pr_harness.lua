local B=dofile('tests/kernel_pr_native_api_harness.lua');local H=B.H;local T={H=H,B=B,path='../pr_bridge/bridge/frameworks/forge/raw_core_factory.lua'}
function T.new(side)
    local r={side=side or'server',resource='forge-core',current=true,pr={},public={},loads={},effects={}}
    local bank={getAccountMoney=function(_,name)r.effects[#r.effects+1]={'get',name};return 23 end,
        addAccountMoney=function(_,...)r.effects[#r.effects+1]={'add',...};return true end,removeAccountMoney=function()return false end}
    local env=H.environment({exports={['Renewed-Banking']=bank},Debug=function()end,TriggerClientEvent=function(...)r.effects[#r.effects+1]={'notify',...}end})
    r.ports={native={GetCurrentResourceName=function()return r.resource end,IsDuplicityVersion=function()return r.side=='server'end},
        prCore=r.pr,public=r.public,isCurrent=function()return r.current end,environment=env,callback={register=function()error('raw121 must not register callbacks')end},
        profile={{field='banking',path='bridge/banking/renewed/'..r.side},{field='math',path='bridge/utils/numbers'}},
        load=function(path,target)
            r.loads[#r.loads+1]=path;if r.loadHook then r.loadHook(path,target)end
            return H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target)
        end}
    r.factory=H.load(T.path,H.environment());function r.allocate()r.raw=r.factory(r.ports);return r.raw end
    return r
end
return T
