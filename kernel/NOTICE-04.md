# Porte privado QBX — lote 04

Derivado dos arquivos instalados `server/functions.lua` (26 funções após os nove getters do lote 02), `server/queue.lua`, `config/queue.lua` e `server/events.lua`. Licença original em LICENSE-QBX. Preservar estas personalizações locais, não substituir por uma versão upstream.

Transformações estruturais: factories e locals em vez de funções globais; consultas/players/storage/membership/grupos são dependências internas do mesmo núcleo; ACE, natives, callbacks de execução assíncrona, clock, logs e entrega de notificação são portas explícitas. O Notify mantém seu payload, mas a entrega é própria para bind via PR Bridge, sem novo envio direto a ox_lib. Nenhuma parte passa pelo adaptador de framework para consultar o próprio núcleo.

Eventos retornam descritores sem registro. Handlers recebem `eventSource` como primeiro argumento, antes dos argumentos originais; capturá-lo no dispatcher antes de qualquer espera. A fila tem configuração local com closures próprias, não importadas do QBX. Hardcap só é tratado quando `Queue.Bootstrap()` for explicitamente chamado; nenhuma chamada a StopResource ocorre na construção. O handler de DDL retorna como código inativo e não é executado pelo lote.

As quatro factories e a composição extra não entram no manifesto. Eventos/nomes/chaves, payloads, textos, SQL descrito, configuração padrão e semântica de falhas da origem são preservados nos casos comparados. Não foi feita correção implícita dos riscos de drop/buckets, espera de Save ou deferrals. A ativação depende de resolver decisões, completar integrações e receber autorização operacional.
