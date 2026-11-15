local P = dofile('tests/kernel_player_harness.lua')
local H, count = P.H, 0
local function runtime(ported)
    local r = {warnings = {}}
    local warn = function(message) r.warnings[#r.warnings + 1] = message end
    local env = H.environment()
    if ported then r.Locale = H.load('kernel/shared/locale.lua', env)({warn = warn})
    else env.lib = {print = {warn = warn}}; P.loadOrigin('shared/locale.lua', env); r.Locale = env.Locale end
    assert(#r.warnings == 0)
    if ported then assert(rawget(env, 'Locale') == nil) end
    return r
end
local function test(name, action)
    local a, b = runtime(false), runtime(true)
    H.same(P.snapshot(table.pack(action(b))), P.snapshot(table.pack(action(a))), name)
    H.same(b.warnings, a.warnings, name .. ': warnings'); count = count + 1
end
local function new(r, opts) return r.Locale:new(opts or {phrases = {hello = 'Olá %{name}', nested = {value = 'V'}}}) end
test('nested translate', function(r) local l = new(r); return l:t('nested.value'), l.phrases end)
test('substitution', function(r) return new(r):t('hello', {name = 'Bruno'}) end)
test('number bool', function(r) return new(r, {phrases = {x = '%{n}/%{flag}'}}):t('x', {n = 7, flag = false}) end)
test('extend prefix', function(r) local l = new(r); l:extend({x = {a = 'A'}}, 'p'); return l:t('p.x.a') end)
test('missing warns default', function(r) return new(r):t('missing') end)
test('missing explicit quiet', function(r) return new(r, {warnOnMissing = false}):t('missing') end)
test('missing explicit warns', function(r) return new(r, {warnOnMissing = true}):t('missing') end)
test('nonboolean warning option', function(r) return new(r, {warnOnMissing = 0}):t('missing') end)
test('false value exists but not phrase', function(r) local l = new(r, {phrases = {x = false}}); return l:has('x'), l:t('x') end)
test('fallback', function(r)
    local fallback = new(r, {phrases = {x = 'F %{name}'}})
    return new(r, {fallbackLang = fallback}):t('x', {name = 'N'})
end)
test('fallback cloned and quiet', function(r)
    local fallback = new(r, {phrases = {x = 'F'}})
    local l = new(r, {fallbackLang = fallback}); fallback:replace({x = 'NEW'})
    return l:t('x'), l:t('missing')
end)
test('clear', function(r) local l = new(r); l:clear(); return l.phrases, l:has('hello') end)
test('replace', function(r) local l = new(r); l:replace({new = 'N'}); return l.phrases, l:has('hello') end)
test('replace nil', function(r) local l = new(r); l:replace(); return l.phrases end)
test('locale get/set', function(r) local l = new(r); local a = l:locale(); return a, l:locale('pt-br'), l:locale() end)
test('delete string', function(r) local l = new(r); l:delete('hello'); return l.phrases end)
test('delete nested', function(r) local l = new(r); l:delete({nested = {value = ''}}); return l.phrases end)
test('delete prefix', function(r) local l = new(r); l:delete({value = ''}, 'nested'); return l.phrases end)
test('delete missing', function(r) local l = new(r); l:delete('absent'); return l.phrases end)
test('pattern semantics retained', function(r) return new(r, {phrases = {x = '%{a.b}'}}):t('x', {['a.b'] = 'N'}) end)
test('invalid replacement raises like origin', function(r)
    local l = new(r, {phrases = {x = '%{a}'}})
    return pcall(l.t, l, 'x', {a = '%'}) and true or false
end)
test('constructor ignores legacy self', function(r) return r.Locale.new({}, {phrases = {x = 'X'}}):t('x') end)
local a, b = runtime(true), runtime(true)
a.Locale.custom = true; assert(b.Locale.custom == nil, 'Independent class namespaces')
assert(count == 22)
print('PASS kernel Locale: ' .. count .. ' differential cases; all class operations, nested/fallback/missing/substitution/error semantics, no global Locale')
