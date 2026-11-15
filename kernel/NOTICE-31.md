# Lote 31 — inativo

Fábricas privadas do AutoMedic cliente completo (NPC/atendimento/bandagem), hospital, duas APIs de menu e ramo cliente da vista Forge Session. Não são carregadas pelo fxmanifest. Ver .planning/migration/LOTE-31.md.

Mesmos PlayerData/Status/ProducerCore/Menu/Shared locais; não usar PR framework ou exports para voltar ao Forge. Integrações externas passam pela biblioteca PR (useItem, RPC, UI, devtools), plataforma GTA por portas explícitas. useItem não resolve a lacuna clearInventoryRaw do servidor30. Identificadores públicos preservados como descritores, não registrados.

Initialize da vista Session é explícito; o futuro bootstrap deve preservar a ordem instalada (snapshot inicial antes de instalar hospital/runtime), registrar/desregistrar uma única vez e só então iniciar o worker inicial. Hospitais descrevem o keybind depois de Initialize; threads dinâmicos só aparecem após ações explícitas. Canonical Session do produtor não é substituída pela vista Forge.

Sem operação real, ativação ou conclusão da migração. Riscos herdados de callbacks/timers/posição/pós-await/menu e identidade preservados e documentados; as únicas correções de runtime aprovadas continuam R08–R11 no lote05.
