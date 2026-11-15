-- Private QBX port; not loaded by the live manifest. See kernel/NOTICE-06.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit support ports required')
    local vec4 = assert(ports.vec4, 'vec4 port required')
return {
    serverName = "Server",
    defaultSpawn = vec4(-540.58, -212.02, 37.65, 208.88),
    notifyPosition = "center-left", -- 'top' | 'top-right' | 'top-left' | 'bottom' | 'bottom-right' | 'bottom-left'
    ---@type { name: string, amount: integer, metadata: fun(source: number): table }[]
    -- Other starter items remain configurable through Forge Core.
    -- Documents are issued at Forge DK service NPCs, never on character creation.
    starterItems = {},
}
end
