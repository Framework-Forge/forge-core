-- Main menu shortcut only; no edits or calls to starter-pack/item services.
local function fixture(state, result, failure)
    local contexts, notifications, calls = {}, {}, 0
    local env = setmetatable({PR={}, ForgeCore={t=function(key) return key end}}, {__index=_G})
    env.pr_lib = {table={clone=function(value) return value end,count=function() return 0 end},
        Notify=function(data) notifications[#notifications+1]=data end,
        menus={RegisterContext=function(context) contexts[context.id]=context end,ShowContext=function() end}}
    env.GetResourceState = function(resource) assert(resource=='forge-dk'); return state end
    env.AddEventHandler = function() end
    env.exports = {['forge-dk']={OpenAdminPanel=function()
        calls=calls+1; if failure then error('DK stopped') end; return result
    end}}
    assert(loadfile('client/menu/menu.lua','t',env))()
    env.ForgeCore.Client.Menu.openMain()
    local option
    for _, entry in ipairs(contexts.forge_core_main.options) do
        if entry.title=='panels.documents.title' then assert(not option); option=entry end
    end
    assert(option and option.icon=='person-vcard-fill')
    return option, notifications, function() return calls end
end
local option, notices, calls=fixture('started',{ok=true})
assert(not option.disabled and option.onSelect() and calls()==1 and #notices==0)
option,notices,calls=fixture('stopped',{ok=true})
assert(option.disabled and not option.onSelect() and calls()==0 and notices[1].description=='panels.unavailable')
option,notices,calls=fixture('started',{ok=false,error='no_permission'})
assert(not option.onSelect() and calls()==1 and notices[1].description=='panels.failed')
option,notices,calls=fixture('started',nil,true)
assert(not option.onSelect() and calls()==1 and #notices==1)
for _, path in ipairs({'locale/pt-br.lua','locale/en-us.lua'}) do
    local locale=dofile(path); assert(locale.panels.documents.title and locale.panels.documents.description)
end
print('Forge Core document shortcut: 6 scenarios passed')
