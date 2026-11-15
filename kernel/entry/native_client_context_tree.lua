-- Build the real75/73/71/70/69/57 tree. Domain/PR integration ports stay explicit and mandatory.
return function(foundation,ports)
 assert(foundation.Side=='client'and foundation.IsCurrent(),'current client foundation required')
 local function tablePort(name)
  local value=assert(ports[name],'client context port required:'..name)
  assert(type(value)=='table','client context table required:'..name);return value
 end
 for _,name in ipairs({'running','onError','isReady','isCurrent'})do assert(type(ports[name])=='function','client context function required:'..name)end
 local central,domains=tablePort('central'),tablePort('domains')
 assert(type(central.config)=='table'and central.config.Client==nil,'client configuration belongs to70')
 assert(type(domains.config)=='table'and type(domains.domains)=='table'and type(domains.client)=='table','complete domain graph input required')
 local locale={};for k,v in pairs(foundation.Locales.Ports)do locale[k]=v end
 local bindings=tablePort('public');local input=tablePort('input');local callbacks=tablePort('callbacks')
 local media={media=tablePort('media'),createMedia=foundation.Factories.Get('media'),
  worker={central=central,domains=domains,createTasks=foundation.Factories.Get('tasks'),
   running=ports.running,onError=ports.onError,isReady=ports.isReady},
  shutdown={resource='forge-core',events=foundation.Events,public=bindings,callbacks=callbacks,input=input}}
 local context={locale=locale,createLocale=foundation.Locales.CreateLocale,
  localeBinding={listen=foundation.Events.listen,remove=foundation.Events.remove,
   available=foundation.RegistrationInput.available,publishExport=foundation.RegistrationInput.native.publishExport},
  runtimeContext={imports={nativeCache=foundation.NativeCache.Cache,running=ports.running},
   createImports=foundation.Factories.Get('imports'),
   deliveryContext={delivery=tablePort('delivery'),createDelivery=foundation.Factories.Get('delivery'),
    configurationContext={configuration=tablePort('configuration'),createConfiguration=foundation.Factories.Get('configuration'),
     mediaContext=media}}}}
 return{context=context,registration=foundation.RegistrationInput,isCurrent=ports.isCurrent,isReady=ports.isReady}
end
