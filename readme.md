
client.lua
exports['forge-core']:OpenMeiCreator()

server.lua
exports['forge-core']:OpenMeiCreator(source)



erros a corrigir:

[     script:qbx_core] [qbx_core] [WARN] Invalid grade 3 found in player_groups table for gang ballas, Does it exist in shared/gangs.lua?
[     script:qbx_core] [qbx_core] [WARN] Invalid group mei_teste found in player_groups table, Does it exist in shared/jobs.lua?
[     script:qbx_core] [qbx_core] [WARN] Invalid group teste found in player_groups table, Does it exist in shared/jobs.lua?
[     script:qbx_core] [qbx_core] [ERROR] cannot set job. Job firefighter does not have grade 5
[     script:qbx_core] [qbx_core] [ERROR] cannot set job. Job firefighter does not have grade 5


correçoes:
    Sistema de shop:
        - Corrigir o modo de visualizaçao da loja, ela esta mostrando modelo ox_lib (eu quero que mostre no modelo do ox_inventory, igual voce fez com a loja com a loja dos empregos).
        - a loja esta para todos gerenciar e sacar dinheiro, so deveria ser para o dono.
        - precisa por opçao de comprar a loja.
        - no gerenciamento admin precisa por para poder teleportar para a coordenada da loja.
