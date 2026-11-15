# Núcleo preparado — lote 01

Módulos privados portados da instalação local de `qbx_core` em 18/10/2026:

- `shared/main.lua`: criação do estado compartilhado e `SetVehicles`.
- `shared/functions.lua`: `GetPlayerGroups` e `HasPlayerGotGroup`.
- `server/groups.lua`: 15 APIs de jobs/gangs, enum `GroupType`, callback `qbx_core:server:getGroups` e serializador privado.

Os originais permanecem em `resources/[qbx]/qbx_core`. A licença da instalação foi preservada integralmente em `LICENSE-QBX`, sem corrigir ou remover sua atribuição histórica. O aviso MIT/Overextended incorporado em `shared/functions.lua` também foi mantido. Estes avisos não renomeiam interfaces nem substituem as obrigações da licença original.

## Estado operacional

**Preparado/inativo.** `fxmanifest.lua` não carrega estes módulos. Nenhum serviço em uso foi trocado, nenhum export público foi publicado e o QBX continua sendo a autoridade da configuração atual.

`init.lua` retorna uma fábrica privada de composição do lado servidor neste recorte; não é um bootstrap compartilhado/cliente. Cada instância tem seus próprios registros; os catálogos fornecidos são referências explícitas, não cópias obtidas de outro recurso. Para testes e futura composição interna, as dependências são:

- `shared`: tabelas `locations`, `weapons`.
- `membership`: funções `tableType` (Cfx `table.type`) e `warn` (biblioteca PR).
- `groups`: tabelas `jobs`, `gangs`; funções `emitServer`, `emitClient`, `logError`, `saveGroups`.

`saveGroups(kind, text)` recebe `job` ou `gang` e o conteúdo que o QBX serializaria. Não tem implementação de arquivo nem caminho de destino aqui. A conciliação com JSON/Registry/Storage do Forge é P05; não conectar a um arquivo real antes dessa revisão. A origem ignora o retorno falso da gravação; este lote mantém e testa esse comportamento, sem apresentá-lo como persistência transacional garantida.

`Groups.Callbacks` contém handlers, não registros ativos. O futuro bootstrap usará PR Bridge para registrar as fronteiras públicas uma única vez no corte aprovado. As operações internas usam as funções dessa instância, sem `exports.qbx_core`, sem chamar export do próprio Forge e sem voltar pelo adaptador de framework do PR Bridge.

## Limites

Este lote não migra jogadores, dinheiro, sessões, banco, status, personagem ou inventário; não internaliza ainda C01/C03 nos consumidores existentes. Testes diferenciais cobrem o comportamento especificado no lote, não paridade integral nem execução FiveM. Ver `.planning/migration/LOTE-01.md` na raiz do workspace para resultados e pendências.
