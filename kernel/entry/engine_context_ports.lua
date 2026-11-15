-- Replace only catalogued function slots;retain explicit unknown/scalar ports and report them.
local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
local function branch(root,path)local o=root;for _,k in ipairs(path)do o[k]=copy(o[k]);o=o[k]end;return o end
local function views(engine,schema)
    assert(type(schema)=='table'and engine.IsCurrent(),'engine schema/current owner required')
    local cache={};local audit={mapped=0,remaining={},OperationalReady=false}
    local function native(source,where)
        if cache[source]then return cache[source]end
        local out=copy(source);local selected={};cache[source]=out
        for name,value in pairs(source)do
            if type(value)=='function'and schema[name]then selected[name]=schema[name];audit.mapped=audit.mapped+1
            else audit.remaining[#audit.remaining+1]={where=where,name=name,kind=type(value)}end
        end
        for name,value in pairs(engine.Select(selected))do out[name]=value end;return out
    end
    local function parts(source,where)
        local out=copy(source)
        for name,value in pairs(source)do if type(value)=='table'and value.native then
            local p=copy(value);p.native=native(value.native,where..'.'..name);out[name]=p
        end end;return out
    end
    return native,parts,audit
end
local api={OperationalReady=false}
function api.Server(input,engine,schema)
    assert(engine.Side=='server','server engine ports required');local native,parts,audit=views(engine,schema);local root=copy(input)
    local life=branch(root,{'deliveryContext','mediaContext','supportContext','configurationContext','vehicleContext','bankingContext','operationsContext','inventoryContext','startup','lifecycle'})
    life.worker=copy(life.worker);local w=life.worker;w.graph=copy(w.graph);local g=w.graph
    g.central=parts(g.central,'central');g.domains=parts(g.domains,'domains');g.helpers=copy(g.helpers);g.helpers.native=native(g.helpers.native,'helpers')
    if w.bootstrap.native then w.bootstrap=copy(w.bootstrap);w.bootstrap.native=native(w.bootstrap.native,'bootstrap')end
    return root,audit
end
function api.Client(input,engine,schema)
    assert(engine.Side=='client','client engine ports required');local native,parts,audit=views(engine,schema);local root=copy(input)
    local media=branch(root,{'runtimeContext','deliveryContext','configurationContext','mediaContext'})
    media.worker=copy(media.worker);local w=media.worker;local old=w.central;w.central=parts(old,'central');w.central.native=native(old.native,'central.native')
    w.domains=copy(w.domains);w.domains.domains=parts(w.domains.domains,'domains')
    local jobs=w.domains.domains.Jobs
    if jobs and type(jobs.wait)=='function'then jobs=copy(jobs);jobs.wait=engine.Select({wait='Wait'}).wait;w.domains.domains.Jobs=jobs end
    return root,audit
end
return api
