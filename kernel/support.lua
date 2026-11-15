-- Private support composition. No Player/Storage authority or runtime registration.
local createShared = require 'kernel.config.shared'
local createClient = require 'kernel.config.client'
local createServer = require 'kernel.config.server'
local createHooks = require 'kernel.modules.hooks'
local createLogger = require 'kernel.modules.logger'

return function(ports)
    assert(type(ports) == 'table' and (ports.side == 'server' or ports.side == 'client'), 'support side required')
    local support = {Config = {Shared = createShared(assert(ports.shared, 'shared config ports required'))}}
    if ports.side == 'server' then
        support.Config.Server = createServer(assert(ports.server, 'server config ports required'))
        support.Hooks = createHooks(assert(ports.hooks, 'hook ports required'))
        support.Logger = createLogger(assert(ports.logger, 'logger ports required'))
        assert(support.Logger, 'server logger required')
    else
        support.Config.Client = createClient(assert(ports.client, 'client config ports required'))
    end
    return support
end
