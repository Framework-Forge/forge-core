-- Framework bootstrap is owned by Forge; it imports public PR primitives.
local source=assert(LoadResourceFile('forge-core','kernel/pr_integration/core_bootstrap.lua'),'Forge bootstrap missing')
local create=assert(load(source,'@@forge-core/kernel/pr_integration/core_bootstrap.lua','t',_ENV))()
create(_ENV)
