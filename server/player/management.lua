ForgeCore = ForgeCore or {}
local Service={}
local function canManage(source)return ForgeCore.JobService and ForgeCore.JobService.canManage(source)end
local function qbx(source)return exports.qbx_core:GetPlayer(tonumber(source) or 0)end
local function group(group)
    group=type(group)=='table' and group or {}; local grade=group.grade; local level=type(grade)=='table' and (grade.level or grade.grade) or grade
    return {name=group.name or 'none',label=group.label or group.name or 'Nenhum',grade=tonumber(level) or 0,gradeLabel=type(grade)=='table' and (grade.name or grade.label) or tostring(level or 0)}
end
local function name(data)local c=data.charinfo or {};return (('%s %s'):format(c.firstname or '',c.lastname or '')):gsub('^%s+',''):gsub('%s+$','')end
local function whitelistMap(source)
    local ok,payload=ForgeCore.WhitelistService.listPlayers(source); local map={}; if ok and payload then for _,entry in ipairs(payload.players or {}) do map[entry.citizenid]=entry end end; return map
end
function Service.list(source)
    if not canManage(source) then return false,'no_permission' end
    local wl=whitelistMap(source); local result={}
    for _,raw in ipairs(GetPlayers()) do local id=tonumber(raw); local p=qbx(id); if p and p.PlayerData then local d=p.PlayerData; local active=ForgeCore.VipService.get(id); result[#result+1]={source=id,citizenid=d.citizenid,name=name(d)~='' and name(d) or GetPlayerName(id),job=group(d.job),gang=group(d.gang),whitelisted=wl[d.citizenid] and wl[d.citizenid].whitelisted==true,vip=active and active.config.label or 'Standard',vipExpiresAt=active and active.expiresAt or 0} end end
    table.sort(result,function(a,b)return a.source<b.source end); return true,result
end
function Service.details(source,target)
    if not canManage(source) then return false,'no_permission' end
    target=tonumber(target); local p=qbx(target); if not p or not p.PlayerData then return false,'invalid_player' end
    local d=p.PlayerData; local c=d.charinfo or {}; local active=ForgeCore.VipService.get(target); local _,jobs=ForgeCore.MultiJobService.getPlayerJobs(target); local _,wl=ForgeCore.WhitelistService.getPlayerRecord(source,d.citizenid)
    local available={}; for jobName,job in pairs(ForgeCore.JobRegistry.getJobs() or {}) do local grades={}; for level,grade in pairs(job.grades or {}) do grades[#grades+1]={value=tostring(level),label=('%s - %s'):format(tostring(level),grade.name or grade.label or level)} end; table.sort(grades,function(a,b)return tonumber(a.value)<tonumber(b.value)end); available[#available+1]={value=jobName,label=job.label or jobName,grades=grades} end; table.sort(available,function(a,b)return a.label<b.label end)
    return true,{source=target,citizenid=d.citizenid,license=d.license,name=name(d),firstname=c.firstname,lastname=c.lastname,birthdate=c.birthdate,nationality=c.nationality,phone=c.phone,job=group(d.job),gang=group(d.gang),money=d.money or {},metadata={isdead=d.metadata and d.metadata.isdead,hunger=d.metadata and d.metadata.hunger,thirst=d.metadata and d.metadata.thirst},staffRole=d.metadata and d.metadata[PR.Staff.Metadata] or nil,whitelist=wl or {whitelisted=false,answers={}},jobs=jobs and jobs.jobs or {},availableJobs=available,vip=active and {tier=active.tier,label=active.config.label,expiresAt=active.expiresAt,expiresAtFormatted=os.date('%d/%m/%Y %H:%M',active.expiresAt)} or {tier='standard',label='Standard',expiresAt=0,expiresAtFormatted='Sem VIP'}}
end
function Service.whitelist(source,target,enabled)
    if not canManage(source) then return false,'no_permission' end
    local p=qbx(target); if not p then return false,'invalid_player' end
    if enabled then return ForgeCore.WhitelistService.add(source,p.PlayerData.citizenid) end
    return ForgeCore.WhitelistService.remove(source,p.PlayerData.citizenid)
end

local legacyDetails = Service.details
function Service.details(source, target)
    local ok, data = legacyDetails(source, target)
    if not ok or type(data) ~= 'table' then return ok, data end
    local raw = data.staffRole
    local permissions = {}
    if type(raw) == 'string' then permissions[1] = raw
    elseif type(raw) == 'table' then
        raw = type(raw.permissions) == 'table' and raw.permissions or raw
        for key, value in pairs(raw) do if type(key) == 'number' then permissions[#permissions + 1] = value elseif value == true then permissions[#permissions + 1] = key end end
    end
    table.sort(permissions)
    data.staffPermissions = permissions
    data.prison = ForgeCore.PrisonService.status(target)
    data.staffRole = permissions[1]
    return ok, data
end
ForgeCore.PlayerManagementService=Service
