-- Private lifecycle ownership, not a live bootstrap or forced thread termination.
return function(spec,ports)
    local owner,current=assert(spec.owner),assert(spec.isCurrent)
    assert(current()and owner.ShutdownSequence==nil,'fresh canonical shutdown owner required')
    local worker=assert(spec.worker)
    local start,close,progress=assert(worker.Start),assert(worker.Close),assert(worker.Progress)
    local attach,detach,activate,pending=assert(ports.attach),assert(ports.detach),assert(ports.setActive),assert(ports.pending)
    local entries,binders={},{}
    for i,d in ipairs(spec.entries)do entries[i]={name=d.name,handler=assert(d.handler)}end
    for i,d in ipairs(spec.binders)do binders[i]={name=d.name,install=assert(d.api.Install),dispose=assert(d.api.Dispose)}end
    local phase,installing,starting,busy='prepared',false,false,false
    local closing,nativeStop,token,tokenRemoved,cleanupHadInFlight=false,false,nil,false,false
    local errors,ledger,revoked={}, {}, {}
    local api={PhysicalRemoval=false,OperationalReady=false}
    owner.ShutdownSequence=api
    local function canonical()
        if owner.ShutdownSequence~=api then return false end
        local ok,value=pcall(current);return ok and value==true
    end
    local function fail(name,err)errors[#errors+1]={stage=name,error=tostring(err)}end
    local function attempt(name,fn)
        local result=table.pack(pcall(fn))
        if not result[1]then fail(name,result[2]);return false end
        if result[2]==false then fail(name,result[3]or'refused');return false end
        return true
    end
    local function drain()
        if busy or installing then return false,'operation_in_progress'end
        busy=true
        if not revoked.worker then revoked.worker=attempt('workers.Close',close)end
        -- Reverse registration order; never repeat successful disposal.
        for i=#binders,1,-1 do local d=binders[i]
            if not revoked[d.name]then revoked[d.name]=attempt(d.name..'.Dispose',d.dispose)end
        end
        if token~=nil and not tokenRemoved then tokenRemoved=attempt('stop-listener.remove',function()return detach(token)end)end
        local ok,p=pcall(progress)
        if not ok then fail('workers.Progress',p);busy=false;phase='cleanup-failed';return false end
        local pendingOk,entered=pcall(pending)
        if not pendingOk then fail('ingress.Progress',entered);busy=false;phase='cleanup-failed';return false end
        local inFlight=not p.quiescent or starting or entered>0
        if inFlight and not nativeStop then busy=false;phase='draining';return false,'workers_pending'end
        if inFlight then cleanupHadInFlight=true end
        for i,d in ipairs(entries)do if not ledger[i]then
            if not canonical()then
                ledger[i]='skipped-stale';fail(d.name,'canonical owner replaced')
            else
                ledger[i]='entered' -- Reentrant/native Stop cannot replay an entered body.
                ledger[i]=attempt(d.name,d.handler)and'completed'or'failed'
            end
        end end
        phase=#errors==0 and'cleaned'or'cleanup-failed'
        busy=false
        return phase=='cleaned'and p.quiescent
    end
    local function stop(native)
        if native then nativeStop=true end
        if not closing then
            closing=true;phase='closing';activate(false)
        end
        return drain()
    end
    function api.Install()
        if phase~='prepared'then return false,'installation_not_repeatable'end
        assert(canonical(),'stale shutdown context')
        phase='installing';installing=true
        local ok,err=pcall(function()
            token=attach(function()if closing then return false end;return stop(true)end)
            assert(token~=nil and token~=false,'owned stop token required')
            assert(not closing and canonical(),'shutdown during stop registration')
            for _,d in ipairs(binders)do
                assert(not closing and canonical(),'shutdown during registration')
                local installed,reason=d.install();assert(installed,reason or'registration refused')
            end
            assert(not closing and canonical(),'shutdown before registration commit')
        end)
        installing=false
        if not ok then fail('Install',err);stop(false);return false,err end
        phase='installed';activate(true);return true
    end
    function api.Start()
        if phase~='installed'or closing then return false,'not_installed'end
        if not canonical()then fail('Start','canonical owner replaced');stop(false);return false,'stale_context'end
        phase='starting';starting=true
        local ok,value,reason=pcall(start)
        starting=false
        if not ok or value~=true or closing then
            if not closing then fail('Start',not ok and value or reason or'refused')end
            stop(false);return false,not ok and value or reason
        end
        phase='running';return true
    end
    function api.Stop()return stop(false)end
    function api.Poll()if not closing then return false,'not_stopping'end;return drain()end
    function api.Describe()
        local out={};for i,d in ipairs(entries)do out[i]={name=d.name}end;return out
    end
    function api.Progress()
        local out={phase=phase,nativeBestEffort=nativeStop,cleanupHadInFlight=cleanupHadInFlight,errors={},ledger={},registrationsRevoked=true}
        for _,d in ipairs(binders)do if not revoked[d.name]then out.registrationsRevoked=false end end
        for i,v in ipairs(ledger)do out.ledger[i]=v end
        for i,d in ipairs(errors)do out.errors[i]={stage=d.stage,error=d.error}end
        local ok,p=pcall(progress);out.workersQuiescent=ok and p.quiescent==true and not starting
        local pendingOk,entered=pcall(pending);out.ingressPending=pendingOk and entered or -1
        out.complete=phase=='cleaned'and out.workersQuiescent and out.ingressPending==0 and out.registrationsRevoked and(token==nil or tokenRemoved)
        return out
    end
    return api
end
