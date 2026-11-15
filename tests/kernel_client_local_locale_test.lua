local T=dofile('tests/kernel_locale_runtime_harness.lua');local r=T.R.context();local locale=T.provider(true);locale.api.Initialize('pt-br')
r.importPorts.imports.locale=locale.api.Translate
r.prepareImports();assert(r.installImports());assert(r.api.Start())
local translate=r.api.Imports.Translate;assert(translate('error.not_online')==locale.api.Translate('error.not_online'),'client73 loads local Forge dictionary through unchanged port')
locale.api.Initialize('en');assert(translate('error.not_online')=='Player not online','same captured client function sees dictionary reload')
r.api.Stop();r.clock.advance(120000);r.api.Poll();locale.api.Close()
assert(r.api.Progress().complete and not pcall(translate,'x'),'client73 cleanup remains unchanged')
print('PASS lot74 client73:local Forge datasets without QBX file reads in new loader,positional translator shared/reloaded,existing71/cache/cleanup preserved;virtual only')
