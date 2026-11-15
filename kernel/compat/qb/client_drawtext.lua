-- Private port of installed QBX bridge/qb/client/drawtext.lua; see NOTICE-91.md and LICENSE-QBX.
return function(ports)
assert(type(ports.library)=='table'and type(ports.library.showTextUI)=='function'and type(ports.library.hideTextUI)=='function','explicit PR TextUI required')
assert(type(ports.scheduler)=='table'and type(ports.scheduler.createThread)=='function'and type(ports.scheduler.wait)=='function','explicit scheduler required')
local api={Events={},Exports={}}
local function listen(name,fn)api.Events[#api.Events+1]={name=name,handler=fn,network=true}end
local function createExport(name,fn)assert(api.Exports[name]==nil,'duplicate QB TextUI export');api.Exports[name]=fn end
---@enum Position
local positions = {
    left = 'left-center',
    right = 'right-center',
    top = 'top-center'
}

---@deprecated use ox_lib showTextUI calls directly
local function hideText()
    ports.library.hideTextUI()
end

---@deprecated use ox_lib showTextUI calls directly
---@param text string
---@param position Position
local function drawText(text, position)
    position = positions[position] or position
    ports.library.showTextUI(text, {
        position = position
    })
end

---@deprecated use ox_lib showTextUI calls directly
---@param text string
---@param position Position
local function changeText(text, position)
    position = positions[position] or position
    ports.library.hideTextUI()
    ports.library.showTextUI(text, {
        position = position
    })
end

---@deprecated use ox_lib showTextUI calls directly
local function keyPressed()
    ports.scheduler.createThread(function() -- Not sure if a thread is needed but why not eh?
        ports.scheduler.wait(500)
        ports.library.hideTextUI()
    end)
end

---@deprecated use ox_lib showTextUI calls directly
listen('qb-core:client:DrawText', function(text, position)
    drawText(text, position)
end)

---@deprecated use ox_lib showTextUI calls directly
listen('qb-core:client:ChangeText', function(text, position)
    changeText(text, position)
end)

---@deprecated use ox_lib showTextUI calls directly
listen('qb-core:client:HideText', function()
    ports.library.hideTextUI()
end)

---@deprecated use ox_lib showTextUI calls directly
listen('qb-core:client:KeyPressed', function()
    keyPressed()
end)

local createQbExport = createExport

---@deprecated use ox_lib showTextUI calls directly
createQbExport('DrawText', drawText)
---@deprecated use ox_lib showTextUI calls directly
createQbExport('ChangeText', changeText)
---@deprecated use ox_lib showTextUI calls directly
createQbExport('HideText', hideText)
---@deprecated use ox_lib showTextUI calls directly
createQbExport('KeyPressed', keyPressed)

return api
end
