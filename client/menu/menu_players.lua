ForgeCore = ForgeCore or {}
local Menu,Shared=ForgeCore.Client.Menu,ForgeCore.Client.MenuShared
local function fetch(callback,...)
    local ok,data=Shared.awaitServer(callback,...); if not ok then Shared.notifyFailure('notify.player.load_failed',data); return nil end; return data
end
local function details(target)return fetch(PR.PlayerManagement.Callbacks.details,target)end
local function money(data)local out={};for key,value in pairs(data or {})do out[#out+1]=('%s: %s'):format(key,value)end;table.sort(out);return table.concat(out,' | ')end
local function giveCatalog()
    local catalog=fetch(PR.Inventory.Callbacks.getGiveCatalog);if not catalog then return nil end
    local options,map={},{}
    for _,entry in ipairs(catalog)do options[#options+1]={value=entry.token,label=entry.label};map[entry.token]=entry end
    return options,map
end
function Menu.openPlayerGiveAdmin(target)
    local data=details(target);if not data then return Menu.openPlayersManagement()end
    local options,map=giveCatalog();if not options then return Menu.openManagedPlayer(target)end
    if #options==0 then Shared.notifyFailure('notify.inventory.give_failed','empty_catalog');return Menu.openManagedPlayer(target)end
    local form=Shared.inputDialog('Dar item para '..data.name,{
        {type='select',label='Item, arma, munição ou componente',options=options,searchable=true,required=true},
        {type='number',label='Quantidade',default=1,min=1,max=100000,required=true},
    })
    if not form then return Menu.openManagedPlayer(target)end
    local selected=map[form[1]];if not selected then Shared.notifyFailure('notify.inventory.give_failed','invalid_entry');return Menu.openManagedPlayer(target)end
    local amount=tonumber(form[2]) or 1
    if selected.kind=='weapon' and amount>25 then Shared.notifyFailure('notify.inventory.give_failed','invalid_amount');return Menu.openManagedPlayer(target)end
    local ok,err=Shared.awaitServer(PR.Inventory.Callbacks.give,target,selected.kind,selected.name,amount)
    if not ok then Shared.notifyFailure('notify.inventory.give_failed',err)end
    SetTimeout(400,function()Menu.openManagedPlayer(target)end)
end
function Menu.openPlayersManagement()
    local players=fetch(PR.PlayerManagement.Callbacks.list); if not players then return end
      local options={{title='Criação de personagens',description='Configurar slots e posicionar os previews animados de cada personagem.',icon='person-circle-plus',arrow=true,onSelect=function()Menu.openCharacterCreationSettings('forge_core_players_management')end},{title='Configurar classes VIP',description='Criar, editar e remover níveis e benefícios VIP.',icon='stars',arrow=true,onSelect=function()Menu.openVipClassesMenu('forge_core_players_management')end}}
    for _,entry in ipairs(players)do
        local player=entry
        options[#options+1]={title=('[%s] - %s'):format(player.source,player.name),description=('%s | VIP: %s | Whitelist: %s'):format(player.job.label,player.vip,player.whitelisted and 'Ativa' or 'Pendente'),icon='person-fill',iconColor=player.whitelisted and '#22c55e' or '#ef4444',metadata={{label='CitizenID',value=player.citizenid},{label='Emprego',value=('%s (%s)'):format(player.job.label,player.job.gradeLabel)},{label='Gang',value=player.gang.label},{label='VIP',value=player.vip},{label='Whitelist',value=player.whitelisted and 'Aprovada' or 'Pendente'}},arrow=true,onSelect=function()Menu.openManagedPlayer(player.source)end}
    end
    if #players==0 then options[#options+1]={title='Nenhum jogador online',icon='info-circle',disabled=true}end
    Shared.showContext({id='forge_core_players_management',title=('Gestão de Players (%s)'):format(#players),menu='forge_core_main',options=options})
end
function Menu.openManagedPlayer(target)
    local data=details(target);if not data then return Menu.openPlayersManagement()end
    Shared.showContext({id='forge_core_managed_player',title=('[%s] %s'):format(data.source,data.name),menu='forge_core_players_management',options={
        {title='Dados principais',description=('CitizenID: %s\nNascimento: %s | Nacionalidade: %s\nDinheiro: %s'):format(data.citizenid,data.birthdate or '-',data.nationality or '-',money(data.money)),icon='person-vcard',metadata={{label='License',value=data.license or '-'},{label='Fome',value=tostring(data.metadata.hunger or '-')},{label='Sede',value=tostring(data.metadata.thirst or '-')},{label='Morto',value=data.metadata.isdead and 'Sim' or 'Não'}},disabled=true},
        {title='Slots de personagem',description='Ver quantidade liberada e liberar ou bloquear slots específicos.',icon='person-circle-check',arrow=true,onSelect=function()Menu.openPlayerCharacterSlots(target)end},
        {title='Whitelist',description=data.whitelist.whitelisted and 'Aprovada — visualizar respostas e remover.' or 'Pendente — visualizar respostas e aprovar.',icon='person-check-fill',iconColor=data.whitelist.whitelisted and '#22c55e' or '#ef4444',arrow=true,onSelect=function()Menu.openPlayerWhitelistAdmin(target)end},
        {title='Empregos',description=('%s emprego(s) registrado(s).'):format(#(data.jobs or {})),icon='briefcase-fill',arrow=true,onSelect=function()Menu.openPlayerJobsAdmin(target)end},
        {title='Staff',description=data.staffRole and ('Cargo: '..tostring(data.staffRole)) or 'Sem cargo administrativo.',icon='person-badge-fill',iconColor=data.staffRole and '#22c55e' or '#ffffff',arrow=true,onSelect=function()Menu.openPlayerStaffAdmin(target)end},
        {title='VIP',description=('%s | %s'):format(data.vip.label,data.vip.expiresAtFormatted),icon='star-fill',iconColor=data.vip.tier~='standard' and '#f5c542' or '#ffffff',arrow=true,onSelect=function()Menu.openPlayerVipAdmin(target)end},
        {title='Dar item, arma, munição ou componente',description='Abre a lista completa do Forge e entrega a quantidade escolhida.',icon='gift-fill',iconColor='#22c55e',arrow=true,onSelect=function()Menu.openPlayerGiveAdmin(target)end},
        {title='Dar Admin Car atual',description='Transforma em propriedade permanente o veículo em que este jogador está.',icon='car-front-fill',iconColor='#f5c542',onSelect=function()
            local answer=Shared.alertDialog({header='Dar Admin Car',content=('Registrar permanentemente o veículo atual de %s?'):format(data.name),centered=true,cancel=true})
            if answer=='confirm'then local ok,err=Shared.awaitServer(PR.Vehicles.Callbacks.adminCarCurrent,target);if not ok then Shared.notifyFailure('notify.vehicles.admin_car_failed',err)end end
            SetTimeout(400,function()Menu.openManagedPlayer(target)end)
        end},
    }})
end
function Menu.openPlayerWhitelistAdmin(target)
    local data=details(target);if not data then return end;local wl=data.whitelist;local options={}
    options[#options+1]={title=wl.whitelisted and 'Remover whitelist' or 'Aprovar whitelist',description=wl.whitelisted and 'O jogador será movido para o bucket da whitelist.' or 'Libera o jogador para entrar na cidade.',icon=wl.whitelisted and 'person-x-fill' or 'person-check-fill',iconColor=wl.whitelisted and '#ef4444' or '#22c55e',onSelect=function()local ok,err=Shared.awaitServer(PR.PlayerManagement.Callbacks.whitelist,target,not wl.whitelisted);if not ok then Shared.notifyFailure('notify.whitelist.save_failed',err)end;SetTimeout(400,function()Menu.openPlayerWhitelistAdmin(target)end)end}
    local count=0;for label,item in pairs(wl.answers or {})do count=count+1;local value=type(item)=='table' and item.value or item;local status=type(item)=='table' and item.correct~=nil and (item.correct and 'Correta' or 'Incorreta') or nil;options[#options+1]={title=tostring(label),description=tostring(value)..(status and ('\\n'..status) or ''),icon='chat-left-text',iconColor=status and (item.correct and '#22c55e' or '#ef4444') or '#ffffff',disabled=true}end
    if count==0 then options[#options+1]={title='Sem respostas registradas',description='Respostas anteriores à atualização não foram persistidas.',icon='info-circle',disabled=true}end
    Shared.showContext({id='forge_core_player_whitelist',title='Whitelist: '..data.name,menu='forge_core_managed_player',options=options})
end
local function jobByName(list,name)for _,job in ipairs(list or {})do if job.value==name then return job end end end
function Menu.openPlayerJobsAdmin(target)
    local data=details(target);if not data then return end;local options={{title='Adicionar emprego',description='Selecione o emprego e o cargo.',icon='person-plus-fill',onSelect=function()
        local jobs={};for _,job in ipairs(data.availableJobs or {})do jobs[#jobs+1]={value=job.value,label=job.label}end
        local first=Shared.inputDialog('Adicionar emprego',{{type='select',label='Emprego',options=jobs,required=true}});if not first then return Menu.openPlayerJobsAdmin(target)end
        local selected=jobByName(data.availableJobs,first[1]);local second=Shared.inputDialog(selected.label,{{type='select',label='Cargo',options=selected.grades,required=true}});if not second then return Menu.openPlayerJobsAdmin(target)end
        local ok,err=Shared.awaitServer(PR.MultiJob.Callbacks.addJob,target,selected.value,tonumber(second[1]) or 0);if not ok then Shared.notifyFailure('notify.multijob.add_failed',err)end;SetTimeout(400,function()Menu.openPlayerJobsAdmin(target)end)
    end}}
    for _,entry in ipairs(data.jobs or {})do local job=entry;options[#options+1]={title=job.label or job.name,description=('Cargo: %s | Salário: %s | %s'):format(job.gradeLabel,job.payment,job.active and 'Ativo' or 'Extra'),icon='briefcase',iconColor=job.active and '#22c55e' or '#ffffff',onSelect=function()local answer=Shared.alertDialog({header='Remover emprego',content=('Remover %s deste jogador?'):format(job.label or job.name),centered=true,cancel=true});if answer=='confirm'then local ok,err=Shared.awaitServer(PR.MultiJob.Callbacks.removeJob,target,job.name);if not ok then Shared.notifyFailure('notify.multijob.remove_failed',err)end end;SetTimeout(400,function()Menu.openPlayerJobsAdmin(target)end)end}end
    Shared.showContext({id='forge_core_player_jobs',title='Empregos: '..data.name,menu='forge_core_managed_player',options=options})
end
local function staffRoleOptions()
    local roles={}
    for _,role in ipairs(PR.Staff.Roles or {})do roles[#roles+1]={value=role.value,label=role.label}end
    return roles
end
function Menu.openPlayerStaffAdmin(target)
    local data=details(target);if not data then return end
    local options={{title=data.staffRole and 'Alterar cargo Staff' or 'Adicionar cargo Staff',description=data.staffRole and ('Cargo atual: '..data.staffRole) or 'Selecione um cargo administrativo.',icon='person-plus-fill',onSelect=function()
        local form=Shared.inputDialog('Cargo Staff',{{type='select',label='Cargo',options=staffRoleOptions(),default=data.staffRole,required=true}});if not form then return Menu.openPlayerStaffAdmin(target)end
        local ok,err=Shared.awaitServer(PR.Staff.Callbacks.add,{source=target,role=form[1]});if not ok then Shared.notifyFailure('notify.player.load_failed',err)end;SetTimeout(400,function()Menu.openPlayerStaffAdmin(target)end)
    end}}
    if data.staffRole then options[#options+1]={title='Remover cargo Staff',description='Remove metadata, principals e permissões do cargo atual.',icon='person-dash-fill',iconColor='#ef4444',onSelect=function()local answer=Shared.alertDialog({header='Remover Staff',content='Confirma a remoção do cargo administrativo?',centered=true,cancel=true});if answer=='confirm'then local ok,err=Shared.awaitServer(PR.Staff.Callbacks.remove,{source=target});if not ok then Shared.notifyFailure('notify.player.load_failed',err)end end;SetTimeout(400,function()Menu.openPlayerStaffAdmin(target)end)end}end
    Shared.showContext({id='forge_core_player_staff',title='Staff: '..data.name,menu='forge_core_managed_player',options=options})
end
local function forgeStaffSelection(raw)
    local map = {}
    if type(raw) == 'string' then raw = { raw }
    elseif type(raw) == 'table' and type(raw.permissions) == 'table' then raw = raw.permissions end
    for key, value in pairs(type(raw) == 'table' and raw or {}) do
        if type(key) == 'number' then map[value] = true elseif value == true then map[key] = true end
    end
    return map
end

function Menu.openPlayerStaffAdmin(target)
    local data=details(target);if not data then return end
    local current=data.staffPermissions or data.staffRole;local selected=forgeStaffSelection(current);local labels={};for permission in pairs(selected)do labels[#labels+1]=permission end;table.sort(labels);local hasStaff=#labels>0
    local options={{title=hasStaff and 'Alterar permissões Staff' or 'Adicionar permissões Staff',description=hasStaff and ('Atuais: '..table.concat(labels,', ')) or 'Marque uma ou várias permissões.',icon='person-plus-fill',onSelect=function()
        local okCatalog,catalog=Shared.awaitServer(PR.Staff.Callbacks.catalog);if not okCatalog then Shared.notifyFailure('notify.player.load_failed',catalog);return Menu.openPlayerStaffAdmin(target)end
        catalog=type(catalog)=='table'and catalog or {};local rows={};for _,permission in ipairs(catalog)do rows[#rows+1]={type='checkbox',label=permission.label or permission.value,description=permission.description or permission.value,checked=selected[permission.value]==true}end
        local form=Shared.inputDialog('Permissões Staff',rows);if not form then return Menu.openPlayerStaffAdmin(target)end
        local permissions={};for index,permission in ipairs(catalog)do if form[index]==true then permissions[#permissions+1]=permission.value end end
        local ok,err;if #permissions>0 then ok,err=Shared.awaitServer(PR.Staff.Callbacks.add,{source=target,permissions=permissions})else ok,err=Shared.awaitServer(PR.Staff.Callbacks.remove,{source=target})end
        if not ok then Shared.notifyFailure('notify.player.load_failed',err)end;SetTimeout(400,function()Menu.openPlayerStaffAdmin(target)end)
    end}}
    if hasStaff then options[#options+1]={title='Remover permissões Staff',description='Remove metadata, principals e ACEs atribuídos pelo painel.',icon='person-dash-fill',iconColor='#ef4444',onSelect=function()local answer=Shared.alertDialog({header='Remover Staff',content='Confirma a remoção de todas as permissões administrativas?',centered=true,cancel=true});if answer=='confirm'then local ok,err=Shared.awaitServer(PR.Staff.Callbacks.remove,{source=target});if not ok then Shared.notifyFailure('notify.player.load_failed',err)end end;SetTimeout(400,function()Menu.openPlayerStaffAdmin(target)end)end}end
    Shared.showContext({id='forge_core_player_staff',title='Staff: '..data.name,menu='forge_core_managed_player',options=options})
end
