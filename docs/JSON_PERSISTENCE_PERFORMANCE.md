# Persistência JSON — consistência e meta de 2.000 jogadores

Implementado em 03/10/2026. Testes isolados aprovados; homologação no FXServer e teste de carga real pendentes. Não foi reiniciado o servidor, executado SQL real ou alterado JSON de produção durante esta revisão.

## Índice

- [Escopo](#escopo)
- [Fluxo de gravação](#fluxo-de-gravação)
- [Proteção financeira](#proteção-financeira)
- [Custo e política de backup](#custo-e-política-de-backup)
- [Limites importantes](#limites-importantes)
- [Validação e testes no jogo](#validação-e-testes-no-jogo)

## Escopo

O `qbx_core` continua sendo a autoridade de personagens e dinheiro. A infraestrutura de persistência fica no PR Bridge; os serviços do Forge Core conservam sua responsabilidade sobre seus dados.

| Bloco | Alterações |
| --- | --- |
| Cache global | Objetos, NPCs, spotlights, billboards, lojas, farms, starterpack, densidade, Vinewood e prévias de personagens usam rascunhos; memória/cache só mudam depois de salvar. |
| Configurações | AFK, senha do servidor, multiempregos e whitelist só confirmam a configuração após salvar. |
| Catálogos | VIP, itens/munições/componentes, empregos/gangues, armas e skills/reputações não expõem alterações rejeitadas. Sincronização com framework/inventário fica depois da confirmação. |
| Outros | Configuração de pagamentos conserva também o agendamento antigo se falhar. Histórico de backup não inclui em memória uma entrada não gravada. |
| Dinheiro | O adaptador QBX do PR Bridge agora devolve o resultado de `AddMoney`, permitindo verificar créditos e devoluções. |
| Cliente | Atualizar saldo/estoque das lojas conserva targets e blips; alterações de localização, acesso ou aparência continuam recriando-os. |

Veículos e AutoMedic já preparavam a configuração antes de gravar. A lógica de veículos permaneceu intacta; em 04/10/2026 o AutoMedic recebeu a recuperação hospitalar descrita no guia específico. Não foi feita nova migração de state bags, prisão, rádio, clima ou telefone nesta revisão.

## Fluxo de gravação

1. Serializar a mutação por arquivo dentro do recurso proprietário. Uma segunda coroutine recebe `busy`; não há fila ilimitada, thread de espera ou polling.
2. Validar e modificar um rascunho. Outros leitores continuam vendo a versão confirmada. Na loja, copiar apenas a loja alterada e seu estoque temporário.
3. Codificar JSON com erro protegido e verificar o retorno da gravação. Aceitar apenas `true` ou o BOOL nativo `1`; `nil`, `false`, `0` e exceção não são sucesso.
4. Somente depois de gravar, substituir a memória, publicar no cache e sincronizar os consumidores necessários.
5. Se falhar, descartar o rascunho. O escritor tenta conservar os bytes anteriores e restaurar o arquivo em caso de escrita parcial reportada.

A API é exclusiva do servidor e opt-in: `jsonDraft`, `withJsonLock`, `wrapJsonMutations`, `loadJsonRecovery`, `saveJsonRecovery`, `saveJsonBatch` e `recordJsonIncident`. O `saveJson` antigo também passou a proteger codificação/escrita e rejeitar retorno nulo. Não foram criadas rotinas periódicas de integridade. Em 04/10/2026 foi corrigida a interpretação do BOOL numérico do artefato FiveM, que causava rejeição falsa na inicialização das lojas; detalhes em [AutoMedic e correções de inicialização](AUTOMEDIC_HOSPITAL_RECOVERY.md).

`loadJsonRecovery` consulta o arquivo principal e, se inválido/ausente, a cópia `.bak`. Se ambos existem mas estão inválidos, gera diagnóstico; não sobrescreve dados econômicos com defaults silenciosamente. O conteúdo previamente validado é lembrado para não decodificar o arquivo anterior em cada compra.

Empregos e gangues usam gravação conjunta com bloqueios e restauração dos arquivos já gravados caso uma etapa posterior falhe. Se a própria restauração falhar, um incidente é registrado e novas gravações são bloqueadas. Isso não é uma transação atômica contra queda de energia.

## Proteção financeira

- Compra direta de produto: devolve dinheiro e remove o item entregue se não conseguir confirmar a loja.
- Compra de loja: conserva o proprietário anterior e verifica a devolução do pagamento.
- Depósito de estoque: conserva os metadados dos slots removidos para devolver os mesmos itens em caso de rejeição.
- Saque: verifica o crédito; se o arquivo falhar, tenta reverter exatamente esse crédito e conserva o saldo original da loja.
- Starterpack/recompensas: desfaz entregas anteriores quando falha um item seguinte ou o salvamento da marca de recebimento. Recebimentos confirmados continuam sendo recusados nas novas tentativas quando a configuração é uma vez por personagem.
- Farms: confirma limites/cooldown antes de ativar a rota. Rotas sem limite persistente não precisam escrever JSON.
- MEI: o reembolso desconta primeiro a transferência feita ao governo; não cria dinheiro ao simplesmente devolver ao jogador sem reverter a outra ponta.

Compensações rejeitadas ou resultados desconhecidos de exports são sinalizados para reconciliação, com bloqueio das novas tentativas da loja/personagem afetado. Os incidentes ficam em arquivos `.incidents.json` privados; não são enviados ao cache global nem ao cliente. Se até esse registro falhar, o bloqueio continua em memória e há diagnóstico no console, mas sua recuperação após reinício exige verificar os logs.

O hook **pós-compra** do inventário já recebeu uma operação externa concluída. Se não conseguir confirmar o JSON, registra os dados conhecidos e bloqueia novas compras naquela loja; não repete ou reembolsa cegamente uma operação cujo resultado completo não controla. Esta situação exige conferência administrativa, não um replay automático.

## Custo e política de backup

Resultados locais com `lua55.exe`, coletor de memória ligado. São microbenchmarks; não medem OneSync, renderização, tráfego, JSON nativo do FXServer ou o servidor cheio.

| Cenário sintético | Custo médio observado |
| --- | --- |
| Copiar catálogo inteiro, 100 lojas × 100 produtos | 21,85–24,16 ms/operação |
| Copiar uma loja nesse catálogo | 0,156–0,170 ms/operação |
| Rascunho do mapa com 2.000 recebimentos privados | 0,140–0,150 ms/operação |
| Bloqueio livre por arquivo, sem I/O | 0,0005–0,0006 ms/operação |

As operações de lojas em execução não usam a cópia integral desse catálogo sintético. Uma compra registra novamente somente a loja alterada, não todas. Os testes também confirmam que atualizações financeiras não recriam targets/blips no cliente.

Uma comparação de gravações .NET em arquivos temporários exclusivos no volume `E:` usando 24.994 bytes encontrou aproximadamente 2,07 ms para uma gravação e 5,18 ms para backup + principal. Isso apenas identifica o risco de duplicar I/O; **não equivale a um benchmark de `SaveResourceFile` nem a garantia de persistência em disco físico**. Os arquivos temporários foram removidos.

Por isso foram separadas duas políticas:

- **Administração:** copiar os bytes anteriores para `.bak` antes de cada edição; o custo ocorre somente ao salvar configurações/catálogos.
- **Operações frequentes:** `backup = 'on_failure'`. Após a preparação inicial da cópia de segurança, o caminho normal faz **uma gravação**, como antes. Se a gravação reportar falha, atualiza a recuperação com os últimos bytes conhecidos e tenta restaurar o principal. Não há timer contínuo de backup ou varredura dos jogadores.

Uma cópia inicial pode acrescentar uma gravação na primeira operação do arquivo. Falhas também podem exigir mais I/O para restaurar os dados; não se sacrifica a recuperação para otimizar uma situação excepcional.

## Limites importantes

**Não afirmar que a base está homologada para 2.000 jogadores.** Não havia FXServer/jogadores conectados disponíveis para um teste dessa capacidade.

**Não afirmar proteção total contra crash/queda de energia.** No modo frequente, a `.bak` não é atualizada em cada sucesso e pode ser mais antiga se o processo cair durante uma escrita, antes de tratar o erro. Dinheiro, inventário e JSON pertencem a sistemas diferentes; as compensações atuais não tornam essas três gravações uma única transação durável. Para garantia superior nesse cenário, planejar armazenamento operacional transacional e um registro durável/idempotente compartilhado com os providers envolvidos, medindo seu custo antes de migrar.

Gargalos existentes que precisam de avaliação antes da meta de 2.000:

1. Dados operacionais de lojas ainda fazem gravação do documento JSON completo; o rascunho é seletivo, mas a serialização final não virou uma atualização SQL por loja.
2. O domínio `stores` ainda replica seu catálogo completo quando muda, com coalescência já existente por tick. Não foi trocado o contrato do cache por uma nova replicação por loja nesta correção.
3. Históricos de recebimento/uso crescem com personagens ao longo do tempo; 2.000 registros no teste não limitam seu crescimento futuro.
4. Salvamentos administrativos podem sincronizar catálogos e sessões existentes. Isso não virou trabalho por frame, mas seus picos precisam aparecer no profiler.

Próxima evolução indicada para grande escala: separar catálogo estático de saldo/estoque/histórico operacional, persistir deltas operacionais por entidade e restringir atualizações de rede aos consumidores que precisam delas. Não foi aplicada uma migração de banco ou quebra do contrato público do cache sem homologação.

## Validação e testes no jogo

As suítes `persistence_services_test.lua`, `persistence_admin_test.lua`, `store_refresh_test.lua` e `pr_bridge/tests/json_persistence_test.lua` injetam falhas sem escrever arquivos reais do servidor. Cobrem memória, revisões/cache, entregas parciais, devolução de dinheiro, metadados, bloqueio de repetição incerta, concorrência, backup, codificação, retorno nulo e restauração de uma gravação conjunta.

Também foram repetidos os testes existentes de sessão, postura, prisão/empregos, integração de painéis, consumidores/produtores do cache, keybinds, bancos de dados simulados, interact e target. O benchmark reproduzível está em `tests/persistence_benchmark.lua`.

Para homologar em manutenção:

1. Reiniciar a base para carregar o PR Bridge e seus consumidores atualizados. Não foi feito automaticamente.
2. Editar e reabrir as configurações/catálogos afetados; reiniciar novamente e conferir a persistência.
3. Comprar, depositar estoque com metadados, sacar, adquirir loja, receber starterpack e criar MEI; conferir as duas pontas de cada movimentação.
4. Simular indisponibilidade de gravação **somente numa cópia de teste**. Conferir memória, valores, item e notificação, sem aceitar sucesso falso.
5. Confirmar que um incidente bloqueia repetição. Conferir inventário/banco/arquivos antes de liberar o bloqueio; nunca simplesmente apagar um incidente sem reconciliar os dados.
6. Fazer teste de carga progressivo e medir p95/p99 de tempo do recurso, duração/volume de escrita, tráfego de cache, memória/GC e hitch warnings. A quantidade de jogadores, sozinha, não define a taxa de compras, uso de itens ou alterações simultâneas.
