local P = PRProgression
local state = P.client()
local definitions = { skills = {}, reputations = {}, settings = {} }
local indexed, nextDecay = {}, {}
local unloaded = false
local dirty = false

local function maximum(name) return indexed[name] and indexed[name].maxXp or 0 end

local function effective(name)
    local definition = indexed[name]
    if not definition then return 0 end
    if definition.calculation ~= 'sum_reputations' then return state.values[name] or 0 end
    local total = 0
    for _, rep in ipairs(definitions.reputations or {}) do
        if rep.skill == name then total = total + (state.values[rep.name] or 0) end
    end
    return math.min(definition.maxXp, P.round(total))
end

local function levelFor(definition, xp)
    local levels = definition.levels or definitions.settings.defaultLevels or {}
    local last = levels[1] or { from = 0, to = 1 }
    for index, level in ipairs(levels) do
        last = level
        if xp >= level.from and xp < level.to then
            return { index = index - 1, title = level.title, from = level.from, to = level.to, progress = xp }
        end
    end
    return { index = #levels, title = 'Maestria', from = last.to, to = last.to, progress = xp }
end

local function payload()
    if not state.token then return nil end
    local result = { values = P.copy(state.values), skills = {}, reputations = {}, revision = definitions.revision }
    for _, section in ipairs({ 'skills', 'reputations' }) do
        for _, definition in ipairs(definitions[section] or {}) do
            local entry = P.copy(definition)
            entry.type = section == 'skills' and 'skill' or 'rep'
            entry.xp = effective(entry.name)
            entry.level = levelFor(definition, entry.xp)
            result[section][#result[section] + 1] = entry
        end
    end
    return result
end

local function publish()
    pr_lib.cache.set('forge-core:skills', payload())
    TriggerEvent('forge-core:client:skills:changed', payload())
end

local function update(name, amount)
    local definition = indexed[name]
    if not definition or definitions.settings.enabled == false then return false, 'not_found_or_disabled' end
    if definition.calculation == 'sum_reputations' then return false, 'skill_uses_reputation_sum' end
    amount = P.number(amount)
    if not amount then return false, 'invalid_amount' end
    if not definition.clientGain and not (amount < 0 and definition.decay and definition.decay.enabled) then
        return false, 'client_gain_disabled'
    end
    local ok, actual = P.clientChange(state, name, amount, definition.maxXp)
    if ok and actual ~= 0 then dirty = true; publish() end
    return ok, actual
end

RegisterNetEvent('forge-core:client:skills:sync', function(packet)
    if unloaded then return end
    if type(packet) ~= 'table' then return end
    if packet.definitions then
        definitions, indexed = packet.definitions, {}
        for _, section in ipairs({ 'skills', 'reputations' }) do
            for _, entry in ipairs(definitions[section] or {}) do indexed[entry.name] = entry end
        end
    end
    if P.receive(state, packet, maximum) then publish() end
end)

AddEventHandler('qbx_core:client:collectStatusExtensions', function(extensions)
    extensions.forgeSkills = P.snapshot(state)
end)

AddEventHandler('QBCore:Client:OnPlayerUnload', function()
    unloaded, state, indexed, nextDecay = true, P.client(), {}, {}
    definitions = { skills = {}, reputations = {}, settings = {} }
    pr_lib.cache.clear('forge-core:skills')
end)
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    unloaded = false
    TriggerServerEvent('forge-core:server:skills:initialize')
end)

CreateThread(function()
    while true do
        Wait(PR.Skills.Client.mirrorMs)
        if not unloaded then
            if not state.token then
                TriggerServerEvent('forge-core:server:skills:initialize')
            else
                local now = GetGameTimer()
                for name, definition in pairs(indexed) do
                    local decay = definition.decay
                    if definition.calculation ~= 'sum_reputations' and decay and decay.enabled then
                        nextDecay[name] = nextDecay[name] or (now + decay.intervalMs)
                        if now >= nextDecay[name] then
                            update(name, -decay.amount)
                            nextDecay[name] = now + decay.intervalMs
                        end
                    else nextDecay[name] = nil end
                end
                local pending = dirty
                for name, counter in pairs(state.counters) do
                    local ack = state.ack[name] or { gain = 0, loss = 0 }
                    if counter.gain > ack.gain or counter.loss > ack.loss then pending = true; break end
                end
                if pending then TriggerServerEvent('forge-core:server:skills:mirror', P.snapshot(state)); dirty = false end
            end
        end
    end
end)

exports('updateSkill', update)
exports('fetchSkills', payload)
exports('getCurrentSkill', effective)
exports('getCurrentLevel', function(name)
    return indexed[name] and levelFor(indexed[name], effective(name)) or nil
end)
exports('getSkillInfo', function(name) return P.copy(indexed[name]) end)
