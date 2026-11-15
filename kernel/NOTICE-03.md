# Porte privado QBX — lote 03

Derivado dos sete arquivos instalados de cache, sessão e status do QBX Core. Licença integral em LICENSE-QBX. Não substituir pela implementação upstream: estas cópias preservam as personalizações locais.

Mudanças estruturais: fábricas com dependências explícitas, estado privado compartilhado com o lote 02, registradores substituídos por listas de descritores, callbacks/exports devolvidos em tabelas e threads não iniciadas. Handlers de servidor recebem `eventSource` antes dos argumentos originais; o futuro bootstrap deve capturar `source` ao entrar no evento, sem guardar o global durante uma espera. Inicialização do cache de cliente exige chamada explícita e idempotente.

Nenhum módulo entra no manifesto. Nomes transitórios QB/QBX e chaves `resource:qbx_core:*` preservados. Entrega ao PR Bridge é uma porta de escrita explícita; não há hidratação, polling ou consulta ao adaptador da própria framework. O status continua calculado no cliente e checkpointado no servidor como na origem; não há nova validação clínica/anticheat implícita.

Riscos herdados não aprovados para ativação: resposta de status atrasada após troca do personagem/source; retenção histórica de chaves por personagem na fila; listeners offline R07. A duplicação instalada da atribuição de seatbelt é mantida na lista de descritores. Drop/shutdown/queue/deferrals e registro/descarte operacional ainda não portados por este lote.
