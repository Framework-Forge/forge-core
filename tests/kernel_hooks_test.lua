local S = dofile('tests/kernel_support_harness.lua')
local H, P, count = S.H, S.P, 0
local function compare(name, action)
    local a, b = S.hooks(false), S.hooks(true)
    local left, right = table.pack(action(a)), table.pack(action(b))
    H.same(P.snapshot(right), P.snapshot(left), name .. ': returns')
    H.same(b.trace, a.trace, name .. ': trace')
    count = count + 1
end
compare('empty', function(r) return r.api.trigger('money', {}) end)
for _, response in ipairs({true, false, 'nil', 'message'}) do
    compare('response ' .. tostring(response), function(r)
        local value = response
        if response == 'nil' then value = nil end
        local cb = r.callback('first', value)
        local id = r.exported.registerHook('money', cb)
        assert(getmetatable(cb).__index == nil and getmetatable(cb).__newindex == nil)
        r.exported.registerHook('money', r.callback('second', true))
        return id, cb.resource, cb.hookId, r.api.trigger('money', {amount = 10})
    end)
end
for _, value in ipairs({'boom', false}) do
    compare('throw ' .. tostring(value), function(r)
        r.exported.registerHook('money', r.callback('first', value, 'error'))
        r.exported.registerHook('money', r.callback('second', true))
        return r.api.trigger('money', {})
    end)
end
for _, duration in ipairs({99999, 100000, 150000}) do
    compare('time ' .. duration, function(r)
        r.duration = duration
        r.exported.registerHook('money', r.callback('slow', true))
        return r.api.trigger('money', {})
    end)
end
for _, mode in ipairs({'byId', 'allOwned', 'foreignId', 'resourceStop', 'fallbackOwner', 'unknownId'}) do
    compare(mode, function(r)
        local id = r.exported.registerHook('money', r.callback('A', true))
        r.exported.registerHook('money', r.callback('A2', true))
        r.exported.registerHook('other', r.callback('other', false))
        r.caller = 'B'; r.exported.registerHook('money', r.callback('B', true))
        if mode == 'foreignId' then r.exported.removeHooks(id)
        elseif mode == 'resourceStop' then r.events.onResourceStop('A')
        elseif mode == 'fallbackOwner' then
            r.caller = 'forge-core'; r.exported.registerHook('money', r.callback('own', true))
            r.caller = nil; r.exported.removeHooks()
        else
            r.caller = 'A'
            r.exported.removeHooks(mode == 'byId' and id or (mode == 'unknownId' and 999 or nil))
        end
        return r.api.trigger('money', {}), r.api.trigger('other', {})
    end)
end
compare('ids monotonic across events and removals', function(r)
    local first = r.exported.registerHook('x', r.callback('x', true))
    r.exported.removeHooks()
    return first, r.exported.registerHook('y', r.callback('y', true))
end)
compare('plain callback rejected like Cfx contract', function(r)
    return pcall(r.exported.registerHook, 'money', function() end) and true or false
end)
local a, b = S.hooks(true), S.hooks(true)
a.exported.registerHook('x', a.callback('x', false))
assert(b.api.trigger('x', {}), 'Hook instances must not share state')
a.dependency = false; assert(not pcall(a.api.CheckDependencies), 'Explicit failed dependency must refuse')
assert(count == 18)
print('PASS kernel hooks: ' .. count .. ' differential cases; owner/ID/stop cleanup, callable callback, veto/error/timing, explicit inactive dependency gate')
