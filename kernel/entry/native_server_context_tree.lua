-- Build74..59 structure around explicit graph leaves;135 adopts the one raw provider set before construction.
return function(foundation,ports)
 assert(foundation.Side=='server'and foundation.IsCurrent(),'current server foundation required')
 local function t(name)local v=assert(ports[name],'server context port required:'..name);assert(type(v)=='table','server context table required:'..name);return v end
 for _,name in ipairs({'running','onError','isReady','isCurrent','resourceState','databaseReady'})do
  assert(type(ports[name])=='function','server context function required:'..name)
 end
 local graph=t('graph');assert(type(graph.central)=='table'and type(graph.domains)=='table'and type(graph.helpers)=='table'and type(graph.config)=='table','complete server graph input required')
 local lifecycle={resource='forge-core',events=foundation.Events,public=t('public'),callbacks=t('callbacks'),
  worker={graph=graph,createTasks=foundation.Factories.Get('tasks'),running=ports.running,onError=ports.onError,isReady=ports.isReady,bootstrap=t('bootstrap')}}
 local inventory={inventory=t('inventory'),createInventoryProvider=foundation.Factories.Get('inventory'),
  startup={lifecycle=lifecycle,resourceState=ports.resourceState,databaseReady=ports.databaseReady}}
 local operations={operations=t('operations'),createOperations=foundation.Factories.Get('operations'),inventoryContext=inventory}
 local banking={banking=t('banking'),createBanking=foundation.Factories.Get('banking'),operationsContext=operations}
 local vehicles={vehicles=t('vehicles'),createVehicles=foundation.Factories.Get('keys'),bankingContext=banking}
 local configuration={shared=t('shared'),configuration=t('configuration'),createConfiguration=foundation.Factories.Get('configuration'),vehicleContext=vehicles}
 local support={delivery=t('loggingDelivery'),createDelivery=foundation.Factories.Get('logging'),
  hooks=t('hooks'),logger=t('logger'),public=ports.public,createTasks=foundation.Factories.Get('tasks'),
  running=ports.running,onError=ports.onError,configurationContext=configuration}
 local media={media=t('media'),createMedia=foundation.Factories.Get('media'),supportContext=support}
 local delivery={delivery=t('delivery'),createDelivery=foundation.Factories.Get('delivery'),mediaContext=media}
 local locale={};for k,v in pairs(foundation.Locales.Ports)do locale[k]=v end
 return{registration=foundation.RegistrationInput,isCurrent=ports.isCurrent,isReady=ports.isReady,
  context={locale=locale,createLocale=foundation.Locales.CreateLocale,
   imports={nativeCache=foundation.NativeCache.Cache,running=ports.running},createImports=foundation.Factories.Get('imports'),
   localeBinding={listen=foundation.Events.listen,remove=foundation.Events.remove,available=foundation.RegistrationInput.available,
    publishExport=foundation.RegistrationInput.native.publishExport},deliveryContext=delivery}}
end
