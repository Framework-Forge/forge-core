-- Assemble central47 ports without adopting any Player authority. Domain-specific PR ports stay explicit.
local names={'session','slots','lifecycle','runtime','character','catalog','jobs','finance','business','inventory','consumption','weapons','transport'}
local function copy(t)local out={};for k,v in pairs(assert(t))do out[k]=v end;return out end
return function(foundation,ports)
 assert(foundation.Side=='server'and foundation.IsCurrent(),'server central foundation required')
 local source,library,db=assert(ports.parts),assert(ports.library),assert(ports.database)
 assert(type(db.query)=='table'and type(db.query.await)=='function'and type(db.single.await)=='function','awaited canonical database required')
 local selected={};for _,entry in ipairs(foundation.EngineInputs.Describe())do selected[#selected+1]=entry.name end
 local native=foundation.EngineInputs.Select(selected)
 native.on,native.listen=foundation.Events.listen,foundation.Events.listen
 native.getSource=foundation.Events.source
 local out={}
 for _,name in ipairs(names)do
  assert(type(source[name])=='table','server central part required:'..name);out[name]=copy(source[name])
  if source[name].native~=nil then out[name].native=native end
  if source[name].library~=nil then out[name].library=library end
  if source[name].json~=nil then out[name].json=foundation.Seed.IO.Codec end
 end
 out.session.player=copy(out.session.player)
 for _,name in ipairs({'core','storage','lookup','groups','characterSlots','statusFactory','cacheFactory'})do
  assert(out.session.player[name]==nil,'assembly owns Player dependency:'..name)
 end
 out.session.player.platform=assert(ports.platform,'native Player platform required')
 out.session.player.db,out.session.player.json,out.session.player.library=db,foundation.Seed.IO.Codec,library
 out.slots.db,out.slots.json=db,foundation.Seed.IO.Codec
 for _,name in ipairs({'service','storage','getPlayer','logout'})do assert(out.slots[name]==nil,'assembly owns slot dependency:'..name)end
 out.lifecycle.querySchema=db.query.await
 out.jobs.dependencies={}
 for _,name in ipairs({'slots','slotPolicy','previewsReady','getPreviews'})do assert(out.character[name]==nil,'assembly owns character dependency:'..name)end
 return out
end
