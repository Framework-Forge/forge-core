-- Port of installed QBX bridge/qb/server/commands.lua; see NOTICE-88.md and LICENSE-QBX.
return function(ports)
assert(type(ports.lib)=='table' and type(ports.lib.addCommand)=='function','explicit PR command library required')
local commands = {}

---@deprecated
function commands.Add(name, help, arguments, argsrequired, callback, permission)
    local properties = {
        help = help,
        restricted = permission and permission ~= 'user' and 'group.'..permission or false,
        params = {}
    }
    for i = 1, #arguments do
        local argument = arguments[i]
        properties.params[i] = {
            name = argument.name,
            help = argument.help,
            type = argument.type or nil,
            optional = not argsrequired or (argument and argument.optional)
        }
    end
    ports.lib.addCommand(name, properties, function(source, args, raw)
        local _args = {}
        if #args > 0 then
            _args = args
        else
            for i = 1, #arguments do
                _args[i] = args[arguments[i].name]
            end
        end
        callback(source, _args, raw)
    end)
end

---@deprecated
function commands.Refresh(_) end

return commands
end
