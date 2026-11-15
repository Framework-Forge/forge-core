-- Inactive installed-QBX port; see kernel/NOTICE-08.md.
return function(ports)
    assert(type(ports) == 'table', 'explicit legacy/client ports required')
    local awaitGroups = assert(ports.awaitGroups, 'internal group transport port required')
    local api = {Exports = {}, Events = {}}
local jobs = assert(ports.jobs, 'explicit job seeds required')
local gangs = assert(ports.gangs, 'explicit gang seeds required')

---@return table<string, Job>
local function GetJobs()
    return jobs
end

api.GetJobs = GetJobs; api.Exports.GetJobs = GetJobs

---@return table<string, Gang>
local function GetGangs()
    return gangs
end

api.GetGangs = GetGangs; api.Exports.GetGangs = GetGangs

---@param name string
---@return Job?
local function GetJob(name)
    return jobs[name]
end

api.GetJob = GetJob; api.Exports.GetJob = GetJob

---@param name string
---@return Gang?
local function GetGang(name)
    return gangs[name]
end

api.GetGang = GetGang; api.Exports.GetGang = GetGang

api.Events[#api.Events + 1] = {name = 'qbx_core:client:onJobUpdate', network = true, handler = function(jobName, job)
    jobs[jobName] = job
end}

api.Events[#api.Events + 1] = {name = 'qbx_core:client:onGangUpdate', network = true, handler = function(gangName, gang)
    gangs[gangName] = gang
end}

local initialized, initializing = false, false
function api.Initialize()
    if initialized or initializing then return false end
    initializing = true
    local ok, groups = pcall(awaitGroups, 'qbx_core:server:getGroups')
    initializing = false
    if not ok then error(groups, 0) end
    jobs = groups.jobs
    gangs = groups.gangs
    initialized = true
    return true
end
return api
end
