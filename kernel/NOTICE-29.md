# Lote29 — Cliente/menus de skills privados
Quatro módulos inativos: réplica cliente completa, composição com ProducerCore, menus completos e anexação ao Menu/Shared existente.
PR continua proprietário do ledger puro, UI/RPC e cache passivo. Não há segundo PlayerData nem export de retorno à framework.
Treze métodos de menu, cinco exports, quatro eventos, um worker, um callback e dois comandos somente descritos; nenhum registro/thread/UI na construção.
Paridade inclui defeitos herdados: definitions antes de receive, token sem geração, dirty no unload, full-save stale, locks/timers/parent.
Server28/cliente e PR ledger/RPC/context/persistência são executados em testes de memória; providers/cache/rede/natives/SQL/UI/time são simulados.
Manifesto e fontes ativos não modificados. Binds/descarte, riscos e teste real continuam pendentes; não autoriza ativação.

