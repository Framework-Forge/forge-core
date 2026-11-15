-- Forge-local origin scope. Only an authenticated compatibility gateway may enter Run.
return function(ports)
    local running,fallback,current=assert(ports.running),assert(ports.getInvokingResource),assert(ports.isCurrent)
    local scopes=setmetatable({},{__mode='k'});local closed,pending=false,0
    local api={OperationalReady=false}
    local function valid()local ok,value=pcall(current);return not closed and ok and value==true end
    function api.GetInvokingResource()
        local entry=scopes[running()];if entry then return entry.origin end
        return fallback()
    end
    function api.Run(origin,fn,...)
        assert(valid(),'compat_origin_closed');assert(type(origin)=='string'and origin~=''and type(fn)=='function','identified local origin required')
        local thread=running();local prior=scopes[thread];scopes[thread]={origin=origin};pending=pending+1
        local result=table.pack(pcall(fn,...));pending=pending-1;scopes[thread]=prior
        if not result[1]then error(result[2],0)end;return table.unpack(result,2,result.n)
    end
    function api.Close()closed=true;return pending==0 end
    function api.Progress()return{closed=closed,pending=pending,complete=closed and pending==0}end
    function api.IsCurrent()return valid()end
    return api
end
