local T=dofile('tests/kernel_locale_runtime_harness.lua');local H,P=T.H,T.P
local a,b=T.provider(false),T.provider(true);assert(#b.reads==0 and not b.api.Progress().initialized,'locale constructor inert')
local checks=0
for _,lang in ipairs(T.languages)do
    a.lang=lang;b.lang=lang;a.api.Initialize();b.api.Initialize()
    H.same(b.api.GetLocales(),a.api.GetLocales(),lang..' full dictionary');H.same(b.reads,a.reads,lang..' read order')
    for _,key in ipairs({'error.not_online','info.char_male','info.play_description','missing74'})do
        H.same(P.snapshot(table.pack(pcall(b.api.Translate,key,'PLAYER'))),P.snapshot(table.pack(pcall(a.api.Translate,key,'PLAYER'))),lang..':'..key);checks=checks+1
    end
end;assert(checks==144)
for _,lang in ipairs({'absent','pt-BR','',false})do a.api.Initialize(lang);b.api.Initialize(lang);H.same(b.api.GetLocales(),a.api.GetLocales(),'no new normalization')end
local special='{"ref":"Value %%","x":"${ref}","nested":{"a":"N %s"},"raw":false}'
a.override={en=special};b.override={en=special};local alias=b.api.GetLocales()
a.api.Initialize('en');b.api.Initialize('en');H.same(b.api.GetLocales(),a.api.GetLocales(),'flatten/interpolation')
assert(alias==b.api.GetLocales()and b.api.Translate('x')=='Value %%','dictionary identity and interpolation preserved')
for _,args in ipairs({table.pack('nested.a','X'),table.pack('nested.a',false,2),table.pack('nested.a',nil,2),table.pack('raw')})do
    H.same(P.snapshot(table.pack(pcall(b.api.Translate,table.unpack(args,1,args.n)))),P.snapshot(table.pack(pcall(a.api.Translate,table.unpack(args,1,args.n)))),'positional false/nil')
end
a.foreign='External';b.foreign='External';H.same(b.api.PullLocale('other','x'),a.api.PullLocale('other','x'),'pull overwrite')
a.foreign=nil;b.foreign=nil;H.same(b.api.PullLocale('other','missing'),a.api.PullLocale('other','missing'),'pull missing')
H.same(b.warnings,a.warnings,'warnings');H.same(b.pulls,a.pulls,'pulls')
b.override.en='{invalid';assert(not pcall(b.api.Initialize,'en')and b.api.Progress().pending==0,'decode error releases pending without invented rollback')
print('PASS lot74 locale:36 complete local Forge dictionaries and144 positional comparisons against whole installed engine;real ox server key resolver,merge/flatten/interpolation/fallback/alias/pull/warnings/false/nil/errors;virtual IO/codec')
