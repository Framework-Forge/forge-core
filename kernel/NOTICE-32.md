# Lote 32 — inativo

Portes privados completos de configuração/serviço/callbacks de whitelist e AFK no servidor. Sete módulos, nenhum carregado pelo manifesto. Identificadores, SQL, dados e contratos existentes preservados. Consulte .planning/migration/LOTE-32.md.

Lookup e buckets são locais ao mesmo Player/Functions; AFK usa a vista Forge Session30 já existente, não um novo produtor. JobService/Security canônicos, oito callbacks administrativos e dois player. JSON, banco, identificadores, RPC e notificação continuam PR. Nenhuma operação real de schema/ban/drop/bucket ocorre no construtor; start e workers exigem chamada explícita e futuro bootstrap autorizado.

Webhook pré-exame exige webhookIntegration.request da camada PR, sem fallback HTTP direto. O logger PR instalado não tem contrato equivalente. O binder público e o cliente/menus/exame/plugins/gerenciamento de jogadores continuam pendentes.

Riscos herdados de source após espera, permissões diferentes entre camadas, SQL/Save/RPC não confirmados, whitelist por identificador compartilhado, respostas do exame no payload, preExam sem esquema e AFK por iteração são preservados, não aprovados para ativação. R08–R11 permanecem correções limitadas às substituições autorizadas05.
