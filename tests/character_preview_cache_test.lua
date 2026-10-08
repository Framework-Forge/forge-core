local path='../../../[qbx]/qbx_core/client/character.lua'
local file=assert(io.open(path,'rb'));local source=file:read('a');file:close()
-- FiveM hash literals are adapted in memory only for the standard Lua parser.
assert(load(source:gsub('`[^`]+`','0'),'@'..path,'t',{}))
local helper=assert(source:match('(local function configuredPreviewLocations%(%)[%s%S]-)\nlocal previewCam'))
local tries,waits,state=0,0,'started'
local configured={{x=1,y=2,z=3,heading=90,scenario='PROP_HUMAN_SEAT_CHAIR'}}
local getter=function() tries=tries+1;return configured end
local env={type=type,pcall=pcall,GetResourceState=function() return state end,
    Wait=function(ms) assert(ms==250);waits=waits+1 end,
    exports={pr_bridge={GetResourceState=function(_,resource,key)
        assert(resource=='forge-core' and key=='characterPreviews');return getter()
    end}}}
local read=assert(load(helper..'\nreturn configuredPreviewLocations','preview helper','t',env))()
assert(read()[1].scenario=='PROP_HUMAN_SEAT_CHAIR' and waits==0)
tries,waits=0,0;getter=function() tries=tries+1;if tries<3 then return nil end;return configured end
assert(read()==configured and tries==3 and waits==2)
state='stopped';assert(#read()==0)
state='started';tries,waits=0,0;getter=function() error('Provider not ready') end
assert(#read()==0 and waits==20,'Unavailable provider must have a bounded fallback')
print('PASS QBX preview: full FiveM-aware syntax, provider lookup, delayed start, coordinates/animations, stopped/missing/error fallback')
