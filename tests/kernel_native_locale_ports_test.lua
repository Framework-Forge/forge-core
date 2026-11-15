local T=dofile('tests/kernel_native_foundation_harness.lua');local req,env=T.loader({load=load})
local f=req('kernel.entry.native_locale_ports');local r=T.basePorts(true)
local function read(resource,path)
 assert(resource=='forge-core');local file=io.open(path,'rb');if not file then return nil end;local s=file:read('*a');file:close();return s
end
local tables=T.H.load('../pr_bridge/bridge/utils/tables.lua',env)
local language='pt-br';r.library.table.merge=tables.merge;r.library.getLocaleKey=function()return'en'end
r.io.Files.LoadResourceFile=read;r.io.Codec={decode=test_decode_json}
r.io.JSON={loadJson=function()error('Forge domain locale uses installed Lua files')end}
r.ports.public={settings={get=function(domain)assert(domain=='locale');return{name=language}end}}
r.ports.environment=env;r.ports.getConvar=function(_,fallback)return fallback end;r.ports.pullLocale=function(resource,key)return resource..':'..key end
r.ports.running=coroutine.running;r.ports.loadPR=function(path,target)return T.H.load('../pr_bridge/'..path:gsub('^@pr_bridge/','')..'.lua',target or env)end
local a=f(r.ports);local input={};for k,v in pairs(a.Ports)do input[k]=v end;input.resource,input.path='forge-core','kernel/locales'
local l=a.CreateLocale(input);l.Initialize();assert(l.Translate('error.not_online')~='error.not_online')
local domain=a.DomainLocale();assert(domain.currentLocale=='pt-br'and domain.resource=='forge-core')
assert(domain:t('automedic.beds_title')=='Leitos de recuperação')
assert(domain:t('automedic.beds_description',{count=3}):find('3 leito',1,true))
language='en';local english=a.CreateLocale(input);english.Initialize();assert(english.Translate('error.not_online')=='Player not online')
assert(english.PullLocale('other','x')=='other:x')
a.Close();assert(not pcall(a.DomainLocale)and not pcall(english.Translate,'error.not_online'))
print('PASS175 real PR locale factories and Forge Lua/kernel JSON dictionaries;named substitutions,language selection,foreign pull,revocation')
