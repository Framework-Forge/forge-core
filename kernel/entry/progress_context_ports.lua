-- Same progress engine for all client consumers;other PR libraries/config/state remain borrowed.
return function(input,progress)
    assert(progress.IsCurrent()and type(progress.Library)=='table','owned progress scope required')
    local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;return o end
    local root=copy(input);local m=root
    for _,k in ipairs({'runtimeContext','deliveryContext','configurationContext','mediaContext'})do m[k]=copy(m[k]);m=m[k]end
    m.worker=copy(m.worker);local w=m.worker;local cache={}
    local function library(old)
        if not cache[old]then local out=copy(old);for name,value in pairs(progress.Library)do out[name]=value end;cache[old]=out end
        return cache[old]
    end
    w.central=copy(w.central);local c=w.central;local prior=c.library;c.library=library(prior)
    for name,p in pairs(c)do if type(p)=='table'and p.library then local q=copy(p);q.library=library(p.library);c[name]=q end end
    w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
    for name,p in pairs(w.domains.domains)do if p.library then local q=copy(p);q.library=library(p.library);w.domains.domains[name]=q end end
    return root
end
