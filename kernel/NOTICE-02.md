# Preparação do núcleo de jogadores — lote 02

Port da instalação local QBX em 18/10/2026; originais preservados. A licença da origem continua integralmente em `LICENSE-QBX`. `NOTICE.md` documenta o lote anterior; este aviso o complementa, sem apagar seu histórico.

- `server/player.lua`: 29 funções nomeadas de primeiro nível, 27 contratos de export preservados como API privada, callback de exclusão com posse, objeto Player/Functions, grupos, money/metadata/CharInfo, login/logout, save/retries/travas e identificadores. A implementação completa foi adaptada, não apenas encaminhada para o recurso QBX.
- `server/storage.lua`: módulo completo de storage, com as mesmas tabelas, SQL e campos. Dois comandos e o bootstrap são retornados inativos; não são registrados nem executados na construção.
- `server/player_lookup.lua`: somente as nove consultas iniciais de `server/functions.lua`, até antes dos routing buckets. O restante de `server/functions.lua` ainda não foi portado por este lote.
- `server/player_core.lua`: compõe um estado Players único com grupos/shared existentes e serviços internos. Recusa compor um segundo núcleo de jogadores para a mesma base privada.

## Fronteiras

Sem imports externos, sem exports diretos para OX/QBX/Forge e sem usar o adaptador `pr_lib.framework` para consultar a própria framework. Inventário, biblioteca/logs, plataforma, status/cache e slots são portas explícitas. A vinculação real com PR Bridge/OX ainda é uma etapa posterior; não há fallback para chamadas diretas caso falte uma porta. Referências antigas a exports em comentários são documentação da origem, não instruções de integração.

O array de contas e limites/políticas de jobs/gangs são parâmetros explícitos correspondentes aos convars atuais. Nenhum convar operacional foi modificado. Os nomes de eventos/callbacks, mensagens e campos QB/QBX continuam preservados.

## Sem ativação

O manifesto continua sem carregar o kernel. Não há mudança da autoridade operacional nem registro duplo no servidor em uso. APIs de exclusão, limpeza, conversão e bootstrap somente podem ser chamadas após os gates de segurança/ambiente correspondentes; sua existência no módulo não autoriza sua execução real.

Status/cache/slots fornecidos em testes são doubles. A portabilidade dos produtores reais, tratamento do lifecycle, compatibilidades/imports e integrações públicas ainda precisam ser concluídos antes de testar inicialização sem QBX.

## Diferenças estruturais intencionais e limites

Factories e namespace local substituem globals/registros públicos. Sintaxe Cfx de `?.`, `?[...]`, `+=` e `-=` foi expressa em Lua 5.4 para teste e port; na origem usada para comparação, somente essa sintaxe foi adaptada em memória. Vetores, codecs, banco e nativos foram simulados; testes não provam detalhes do host FiveM ou do banco real.

Preservou-se um risco da origem: métodos de dinheiro offline podem retornar true mesmo após SaveOffline retornar false. Isso está coberto como baseline, não corrigido nem aprovado para ativação. A origem também registra listeners por objeto offline criado; o descarte desses listeners precisa ser reconciliado em P04. Ver `.planning/migration/LOTE-02.md` para resultados e riscos.
