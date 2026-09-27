PR = PR or {}
PR.Spotlights = PR.Spotlights or {}

PR.Spotlights.Storage = {
    file = 'data/spotlights.json',
}

PR.Spotlights.Defaults = {
    enabled = true,
    drawDistance = 450.0,
}

PR.Spotlights.Callbacks = {
    getAll = 'forge-core:server:spotlights:getAll',
    createGroup = 'forge-core:server:spotlights:createGroup',
    renameGroup = 'forge-core:server:spotlights:renameGroup',
    deleteGroup = 'forge-core:server:spotlights:deleteGroup',
    createLight = 'forge-core:server:spotlights:createLight',
    updateLight = 'forge-core:server:spotlights:updateLight',
    deleteLight = 'forge-core:server:spotlights:deleteLight',
}

local function colorChannel(value, fallback)
    value = tonumber(value)
    if value == nil then value = tonumber(fallback) or 255 end
    return math.max(0, math.min(255, math.floor(value + 0.5)))
end

function PR.Spotlights.NormalizeColor(value, fallback)
    fallback = type(fallback) == 'table' and fallback or { r = 255, g = 255, b = 255 }

    if type(value) == 'table' then
        return {
            r = colorChannel(value.r or value.x or value[1], fallback.r),
            g = colorChannel(value.g or value.y or value[2], fallback.g),
            b = colorChannel(value.b or value.z or value[3], fallback.b),
        }
    end

    if type(value) == 'string' then
        local normalized = value:lower():gsub('^%s+', ''):gsub('%s+$', '')
        local hex = normalized:match('^#?(%x%x%x%x%x%x)%x?%x?$')

        if hex then
            return {
                r = tonumber(hex:sub(1, 2), 16),
                g = tonumber(hex:sub(3, 4), 16),
                b = tonumber(hex:sub(5, 6), 16),
            }
        end

        local shortHex = normalized:match('^#?(%x%x%x)$')
        if shortHex then
            return {
                r = tonumber(shortHex:sub(1, 1):rep(2), 16),
                g = tonumber(shortHex:sub(2, 2):rep(2), 16),
                b = tonumber(shortHex:sub(3, 3):rep(2), 16),
            }
        end

        local r, g, b = normalized:match('^rgba?%(%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)')
        if not r then
            r, g, b = normalized:match('^%s*([%d%.]+)%s*,%s*([%d%.]+)%s*,%s*([%d%.]+)%s*$')
        end

        if r then
            return {
                r = colorChannel(r, fallback.r),
                g = colorChannel(g, fallback.g),
                b = colorChannel(b, fallback.b),
            }
        end
    end

    return {
        r = colorChannel(fallback.r, 255),
        g = colorChannel(fallback.g, 255),
        b = colorChannel(fallback.b, 255),
    }
end

function PR.Spotlights.ColorToHex(value, fallback)
    local color = PR.Spotlights.NormalizeColor(value, fallback)
    return ('#%02x%02x%02x'):format(color.r, color.g, color.b)
end
