# Porte privado QBX — lote 09

Derivado dos fontes instalados `qbx_core/client/{main,events,loops,discord}.lua` sob a licença MIT preservada integralmente em LICENSE-QBX. Autoria/copyright originais permanecem nessa licença.

Fábricas/composição privadas e inativas. Efeitos de inicialização são explícitos; descritores não registram eventos/callbacks/threads/statebags nem exports. Estado canônico, Shared, Lib e Notify são locais. Natives, biblioteca, configuração, RNG e tradução recebem portas explícitas, sem encaminhar operações internas pelo PR Bridge.

O binding real da porta ShutdownLoadingScreenNui deverá respeitar o mínimo configurável do Forge Loadscreen; este lote não altera esse recurso nem seu JSON. O algoritmo herdado de waypoint continua tentando a posição/sucesso após falha de chão; não está aprovado para ativação. Simulações não validam FiveM, Discord, mídia, entidades ou propriedade de rede reais. Consulta: `.planning/migration/LOTE-09.md`.
