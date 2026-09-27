PR = PR or {}
PR.Whitelist = PR.Whitelist or {}

PR.Whitelist.Storage = {
    playersTable = 'pinel_whitelist',
    configTable = 'pinel_whitelist_config',
    configFile = 'data/whitelist.json',
    answersTable = 'pinel_whitelist_answers',
}

PR.Whitelist.Callbacks = {
    getConfig = 'forge-core:server:whitelist:getConfig',
    saveConfig = 'forge-core:server:whitelist:saveConfig',
    check = 'forge-core:server:whitelist:check',
    listPlayers = 'forge-core:server:whitelist:listPlayers',
    add = 'forge-core:server:whitelist:add',
    remove = 'forge-core:server:whitelist:remove',
    ban = 'forge-core:server:whitelist:ban',
    submitPreExam = 'forge-core:server:whitelist:submitPreExam',
    clientAdded = 'forge-core:client:whitelist:added',
    clientRemoved = 'forge-core:client:whitelist:removed',
    clientConfigUpdated = 'forge-core:client:whitelist:configUpdated',
}

PR.Whitelist.Defaults = {
    enabled = true,
    percent = 70,
    loadNotify = 'Voce deve completar o exame de cidadania para jogar.',
    escapeNotify = 'Voce deve completar o exame de cidadania para jogar.',
    startExamLabel = 'Iniciar exame de cidadania',
    interactionMode = 'drawtext',
    markerEnabled = true,
    targetEnabled = false,
    blip = {
        enabled = false,
        sprite = 525,
        color = 3,
        scale = 0.8,
        label = 'Exame de cidadania',
    },
    startExamHeader = 'Exame de cidadania',
    startExamContent = 'Todos os novos cidadaos devem passar no exame antes de jogar. Responda com calma e bom senso.',
    successHeader = 'Voce passou no exame de cidadania!',
    successContent = 'Bem-vindo ao servidor.',
    failedHeader = 'Voce falhou no exame de cidadania!',
    failedContent = 'Por favor, tente novamente.',
    spawnCoords = { x = -66.24, y = -822.09, z = 284.61, w = 78.8 },
    examCoords = { x = -68.24, y = -814.40, z = 285.35 },
    completionCoords = { x = -1042.68, y = -2745.97, z = 21.36, w = 323.7 },
    citizenZone = {
        coords = { x = -73.34, y = -821.15, z = 285.0 },
        size = { x = 28.0, y = 22.2, z = 6.2 },
    },
    preExam = {
        enabled = false,
        formatPhone = true,
        webhook = '',
        label = 'Precisamos de algumas informacoes:',
        questions = {
            { type = 'input', label = 'Qual seu nome completo na vida real?', placeholder = 'Seu nome', required = true, min = 3, max = 100, kind = 'name' },
            { type = 'input', label = 'Qual o seu e-mail?', placeholder = 'seu@email.com', required = true, min = 7, max = 50, kind = 'email' },
            { type = 'number', label = 'Qual o seu WhatsApp?', placeholder = '9999999999', required = true, kind = 'phone' },
        },
    },
    questions = {
        {
            question = 'O que e Meta Gaming?',
            options = {
                { label = 'Usar informacoes que seu personagem nao aprendeu dentro do roleplay.', value = true },
                { label = 'Nao temer pela vida do personagem.', value = false },
                { label = 'Usar vantagem fisica impossivel no roleplay.', value = false },
                { label = 'Eu nao sei.', value = false },
            },
        },
        {
            question = 'O que e Power Gaming?',
            options = {
                { label = 'Usar formas irreais de roleplay ou recusar roleplay para obter vantagem.', value = true },
                { label = 'Atacar outro jogador sem motivo.', value = false },
                { label = 'Usar informacoes de fora da cidade.', value = false },
                { label = 'Eu nao sei.', value = false },
            },
        },
        {
            question = 'Voce pode usar software de trapaca de terceiros?',
            options = {
                { label = 'Nao, isso nao e permitido sob nenhuma circunstancia.', value = true },
                { label = 'Sim, se ninguem descobrir.', value = false },
                { label = 'Somente com permissao de amigos.', value = false },
                { label = 'Eu nao sei.', value = false },
            },
        },
        {
            question = 'Qual dos exemplos abaixo normalmente e uma zona segura?',
            options = {
                { label = 'Hospitais.', value = true },
                { label = 'Qualquer rua da cidade.', value = false },
                { label = 'Bancos de parque.', value = false },
                { label = 'Todos os lugares.', value = false },
            },
        },
        {
            question = 'O que significa falar fora do personagem?',
            options = {
                { label = 'Falar como pessoa real dentro da cidade, quebrando o personagem.', value = true },
                { label = 'Usar radio comunicador.', value = false },
                { label = 'Falar baixo perto de outros players.', value = false },
                { label = 'Eu nao sei.', value = false },
            },
        },
        {
            question = 'O que e RDM?',
            options = {
                { label = 'Atacar ou matar outro jogador aleatoriamente sem desenvolvimento de RP.', value = true },
                { label = 'Dirigir rapido em uma avenida.', value = false },
                { label = 'Comprar comida sem falar.', value = false },
                { label = 'Eu nao sei.', value = false },
            },
        },
    },
}
