-- One installed keybind instance across client libraries and state-input descriptors.
return function(input,scope)
 assert(scope.IsCurrent()and type(scope.Keybind)=='table'and getmetatable(scope.Keybind).__call,'owned keybind required')
 local function copy(t)local o={};for k,v in pairs(assert(t))do o[k]=v end;local mt=getmetatable(t);if type(mt)=='table'then setmetatable(o,mt)end;return o end
 local root=copy(input);local m=root
 for _,name in ipairs({'runtimeContext','deliveryContext','configurationContext','mediaContext'})do m[name]=copy(m[name]);m=m[name]end
 m.shutdown=copy(m.shutdown);m.shutdown.input=copy(m.shutdown.input);m.shutdown.input.keybind=scope.Keybind
 m.worker=copy(m.worker);local w=m.worker;w.central=copy(w.central);local c=w.central;local cache={}
 local function library(old)if not cache[old]then local out=copy(old);for k,v in pairs(scope.Library)do out[k]=v end;cache[old]=out end;return cache[old]end
 c.library=library(c.library)
 for name,p in pairs(c)do if type(p)=='table'and p.library then local q=copy(p);q.library=library(p.library);c[name]=q end end
 w.domains=copy(w.domains);w.domains.domains=copy(w.domains.domains)
 for name,p in pairs(w.domains.domains)do if p.library then local q=copy(p);q.library=library(p.library);w.domains.domains[name]=q end end
 return root
end
