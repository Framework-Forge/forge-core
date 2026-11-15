--261: explicit immutable-by-copy configuration,not runtime approval or a framework selector.
return function(input)
 assert(type(input)=='table'and input.authority=='forge-core','Forge authority required')
 local generation=assert(input.generation);assert(type(generation)=='string'and generation~='','generation required')
 assert(type(input.qbEnabled)=='boolean','explicit QB capability required')
 local byName,ordered={},{}
 for _,row in ipairs(assert(input.consumers))do
  local name=assert(row.name);assert(type(name)=='string'and name:match('^[%w_-]+$')and name~='forge-core'and name~='qbx_core'and not byName[name],'unique external consumer required')
  local sides={};for _,side in ipairs({'server','client'})do
   local value=row[side]
   if value~=nil then
    assert(type(value)=='table'and type(value.instance)=='string'and value.instance~='','explicit side instance required')
    assert(type(value.inventory)=='boolean','explicit inventory capability required')
    assert(not value.inventory or side=='server'and name=='ox_inventory','inventory server owner mismatch')
    sides[side]={instance=value.instance,inventory=value.inventory}
   end
  end
  assert(next(sides),'consumer side required')
  byName[name]=sides;ordered[#ordered+1]=name
 end
 assert(#ordered>0,'configured consumers required');table.sort(ordered)
 local api={OperationalReady=false,Generation=generation,QBEnabled=input.qbEnabled}
 function api.Get(name,side)
  assert(side=='server'or side=='client','explicit profile side required')
  local row=byName[name]and byName[name][side];if not row then return end
  return{name=name,side=side,instance=row.instance,inventory=row.inventory,generation=generation,qbEnabled=input.qbEnabled}
 end
 function api.Consumers(side)
  local out={};for _,name in ipairs(ordered)do local row=api.Get(name,side);if row then out[#out+1]=row end end;return out
 end
 return api
end
