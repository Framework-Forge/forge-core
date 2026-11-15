# Porte privado QBX — lote 10

Derivado dos fontes instalados `qbx_core/server/{main,weapons,commands}.lua`. Licença MIT integral e autoria originais preservadas em LICENSE-QBX.

Fábricas e composição privadas/inativas: não carregadas por manifesto, sem registro de comandos/eventos/exports nem bootstrap automático. Reutilizam o mesmo PlayerCore/Lifecycle/Shared, serviços de jogador, Lib e Logger locais. Natives, promessas, RNG, codec, tradução e entrega global são portas explícitas; chat e remoção de chave passam por futuras integrações PR, não por exports externos diretos.

Initialize conserva diagnósticos herdados de startup (inclusive solicitação de quit em erro) apenas como chamadas da porta injetada. Não chamar no recurso real antes de revisar dependências/configuração e obter autorização operacional. Repetição do callback de classes sem resposta e erros de entradas legadas permanecem como na origem; não aprovados para ativação. O catálogo de armas não substitui a conciliação com Forge WeaponRegistry/JSON/OX nem valida bloqueio de item. Detalhes em `.planning/migration/LOTE-10.md`.
