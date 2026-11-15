-- Explicit private initialization only. Cancellation is not teardown/rollback. See NOTICE-56.md.
local function copy(v)
    if type(v)~='table'then return v end
    local out={};for k,item in pairs(v)do out[k]=copy(item)end;return out
end
return function(spec,ports)
    local owner,current=assert(spec.owner),assert(spec.isCurrent)
    local ready,preflight=assert(ports.isReady),assert(spec.preflight)
    assert(type(current)=='function'and type(ready)=='function'and type(preflight)=='function','explicit initialization guards required')
    assert(current()and owner.InitializationSequence==nil,'fresh canonical initialization owner required')
    local entries,seen={},{}
    for _,d in ipairs(assert(spec.entries))do
        assert(type(d.name)=='string'and type(d.handler)=='function'and type(d.owner)=='string','invalid initializer descriptor')
        assert(not seen[d.name]and not seen[d.handler],'duplicate initializer name/function')
        seen[d.name],seen[d.handler]=true,true
        entries[#entries+1]={name=d.name,owner=d.owner,handler=d.handler}
    end
    local phase='prepared-inactive'
    local api={State=phase,StartsWorkers=false,ReversesEffects=false}
    local ledger,results={},{}
    for i in ipairs(entries)do ledger[i]='pending'end
    local inFlight,lastError
    owner.InitializationSequence=api
    local function setPhase(value)phase=value;api.State=value end
    local function canonical()return owner.InitializationSequence==api and current()end
    local function running()return canonical()and phase=='initializing'end
    function api.Describe()return copy(entries)end
    function api.Progress()return{phase=phase,ledger=copy(ledger),results=copy(results),inFlight=inFlight,error=lastError}end
    function api.Cancel()
        if phase=='cancelled'or phase=='failed'or phase=='initialized'then return false end
        setPhase('cancelled');return true -- An entered body may still return later.
    end
    function api.Initialize()
        if phase~='prepared-inactive'then return false,'initialization_not_repeatable'end
        setPhase('initializing')
        local ok,problem=pcall(function()
            assert(running(),'initialization owner replaced/cancelled')
            local canStart=ready()
            assert(running()and canStart==true,'initialization dependencies not ready or cancelled')
            preflight()
            assert(running(),'initialization cancelled/replaced during preflight')
            for i,d in ipairs(entries)do
                assert(running(),'initialization cancelled/replaced before '..d.name)
                ledger[i]='entered';inFlight=i
                results[i]=table.pack(d.handler())
                inFlight=nil
                if not running()then ledger[i]='returned-after-revocation';error('initialization cancelled/replaced after '..d.name,0)end
                ledger[i]='completed'
            end
            assert(running(),'initialization cancelled/replaced before commit')
            setPhase('initialized')
        end)
        if not ok then
            if inFlight then ledger[inFlight]='failed';inFlight=nil end
            lastError=tostring(problem)
            if phase~='cancelled'then setPhase('failed')end
            return false,problem
        end
        return true
    end
    return api
end
