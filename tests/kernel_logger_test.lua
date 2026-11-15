local S = dofile('tests/kernel_support_harness.lua')
local H, P, count = S.H, S.P, 0
local function compare(name, action)
    local a, b = S.logger(false), S.logger(true)
    local left, right = table.pack(action(a)), table.pack(action(b))
    H.same(P.snapshot(right), P.snapshot(left), name .. ': returns')
    H.same(b.trace, a.trace, name .. ': trace')
    assert(#a.tasks == #b.tasks)
    count = count + 1
end
local function log(r, fields)
    local value = {source = 17, event = 'money', message = 'test', oxLibTags = 'account:cash'}
    for key, item in pairs(fields or {}) do value[key] = item end
    return r.api.log(value)
end
compare('library only', function(r) return log(r) end)
for _, color in ipairs({'default', 'blue', 'red', 'green', 'white', 'black', 'orange', 'yellow', 'pink', 'lightgreen', 'unknown'}) do
    compare('color ' .. color, function(r)
        log(r, {webhook = 'mock://discord', color = color, tags = {'<@role>', '@everyone'}})
        assert(r.requests == 0 and #r.tasks == 1)
        r.pump()
    end)
end
for _, status in ipairs({200, 201, 204, 304, 429, 500}) do
    compare('http ' .. status, function(r) r.status = status; log(r, {webhook = 'mock://discord'}); r.pump() end)
end
compare('nil status', function(r) r.status = nil; log(r, {webhook = 'mock://discord'}); r.pump() end)
for _, total in ipairs({2, 5, 6, 11}) do
    compare('queue ' .. total, function(r)
        for i = 1, total do log(r, {webhook = 'mock://' .. i, message = 'log' .. i}) end
        assert(#r.tasks == 1); r.pump()
        log(r, {webhook = 'mock://next'}); assert(#r.tasks == 1); r.pump()
    end)
end
for _, reset in ipairs({'1002', '999', 'invalid'}) do
    compare('ratelimit ' .. reset, function(r)
        r.headers = {['X-RateLimit-Remaining'] = '0', ['X-RateLimit-Reset'] = reset}
        log(r, {webhook = 'mock://discord'}); log(r, {webhook = 'mock://discord'}); r.pump()
    end)
end
compare('requests remain', function(r)
    r.headers = {['X-RateLimit-Remaining'] = '2', ['X-RateLimit-Reset'] = '1002'}
    log(r, {webhook = 'mock://discord', tags = {}}); r.pump()
end)
compare('late http callback', function(r)
    local pending
    r.onHttp = function(callback) pending = callback end
    log(r, {webhook = 'mock://discord'}); r.pump()
    pending(204, '', {['X-RateLimit-Remaining'] = '0', ['X-RateLimit-Reset'] = '1002'})
    log(r, {webhook = 'mock://discord'}); r.pump()
end)
compare('legacy missing headers error retained', function(r)
    r.headers = nil; log(r, {webhook = 'mock://discord'})
    return pcall(r.pump) and true or false
end)
local a, b = S.logger(false, false), S.logger(true, false)
assert(a.api == nil and b.api == nil); H.same(b.trace, a.trace)
local fresh = S.logger(true)
assert(#fresh.tasks == 0 and #fresh.trace == 0)
assert(count == 29)
print('PASS kernel logger: ' .. count .. ' differential cases plus client refusal; exact embeds/tags/colors/library delivery, queue delays/rate-limit/errors, no real HTTP')
