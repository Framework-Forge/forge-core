# Planejamento QBX Core + Forge Core

## Visao Geral

| Tema | Direcao | Objetivo | Observacao |
|---|---|---|---|
| Autoridade da base | `qbx_core` permanece como nucleo central | Otimizar e modernizar sem trocar a framework | `forge_core` nao substitui o `qbx_core` |
| Papel do `forge_core` | Ferramenta/pilar auxiliar | Apoiar edicao in-game, cache, debug, paineis e automacao | Sem inverter a hierarquia |
| Meta de performance | Aproximar FPS de uma base sem framework | Reduzir loops, sync, callbacks, statebags e cargas client | Foco principal em computadores fracos |
| Meta de flexibilidade | Diminuir dependencia de arquivos `shared` fixos | Permitir criar/editar jobs, gangs, veiculos, armas e configs in-game | Manter compatibilidade com scripts existentes |
| Metodo | Auditoria antes de alteracao | Medir, mapear, otimizar e depois dinamizar | Sem refactor cego |

## Performance / FPS

| Area | Problema possivel | Acao de analise | Acao de otimizacao | Prioridade | Status |
|---|---|---|---|---|---|
| Loops client | `Wait(0)` ou loops sempre ativos | Mapear threads client do `qbx_core` | Dormir loops, ativar sob demanda, reduzir polling | Alta | Pendente |
| PlayerData | Envio completo em mudancas pequenas | Rastrear eventos de update e payload | Enviar delta quando possivel e cachear snapshot | Alta | Pendente |
| Statebags | Uso excessivo pode pesar sync | Mapear chaves e frequencia de atualizacao | Usar somente para dados que precisam replicar | Alta | Pendente |
| Callbacks | Consultas repetidas client-server | Listar callbacks quentes e repetidos | Cache por player e invalidacao por evento | Alta | Pendente |
| Banco de dados | Queries desnecessarias ou repetidas | Auditar login, save, job, metadata e vehicles | Batch, cache, save programado e dirty flags | Alta | Pendente |
| Status fome/sede | Atualizacao frequente demais | Medir intervalo e eventos disparados | Aumentar intervalo e enviar apenas mudancas reais | Media | Pendente |
| Shared carregado no client | Tabelas grandes trafegando/carregando | Ver o que vai para client sem necessidade | Separar registries client/server e lazy load | Alta | Pendente |
| Exports/events | Eventos redundantes entre scripts | Mapear chamadas de maior volume | Criar rotas internas mais diretas e cacheadas | Media | Pendente |

## Flexibilidade

| Modulo | Limitacao atual | Modelo desejado | Como manter compatibilidade | Prioridade | Status |
|---|---|---|---|---|---|
| Jobs | `shared/jobs.lua` exige restart e arquivo fixo | Jobs criados/editados in-game e cacheados no `qbx_core` | Manter `QBX.Shared.Jobs` alimentado pelo registry | Alta | Pendente |
| Gangs | `shared/gangs.lua` rigido | Gangs dinamicas com grades/permissoes no banco | Manter estrutura antiga exposta para scripts legados | Alta | Pendente |
| Veiculos | Catalogo/descricao depende de arquivo | Cadastro, descricao, categoria e preco editaveis in-game | Registry interno atualiza shared/exports sem restart | Alta | Pendente |
| Armas | Modelos e regras dependem de arquivo | Cadastro dinamico de modelos/regras/metadados | Compatibilidade com nomes e hashes ja usados | Media | Pendente |
| Itens | Itens dependem de arquivo e reinicio | Criacao/edicao in-game quando seguro | Sincronizar com inventario e manter cache | Media | Pendente |
| Configs | Configs estaticas exigem restart | Configs em banco com reload controlado | Fallback em arquivo para boot seguro | Media | Pendente |
| Permissoes | Regras espalhadas | Permissoes centralizadas e editaveis | Exports/eventos antigos seguem funcionando | Media | Pendente |

## Fases De Implementacao

| Fase | Entrega | Descricao | Criterio de sucesso | Status |
|---|---|---|---|---|
| 0 - Auditoria | Mapa do `qbx_core` | Levantar loops, callbacks, DB, statebags e shareds | Relatorio com arquivos e prioridades | Pendente |
| 1 - Instrumentacao | Debug e metricas | Usar `pr_bridge`/`pr_lib` para medir pontos quentes | Logs controlados sem poluir cliente | Pendente |
| 2 - Jobs dinamicos | Registry de jobs | Primeiro modulo dinamico ligado ao `qbx_core` | Criar/editar job sem restart | Pendente |
| 3 - Cache PlayerData | Snapshot e dirty flags | Reduzir updates completos e consultas repetidas | Menos eventos e payload menor | Pendente |
| 4 - Catalogos dinamicos | Veiculos/armas/itens | Transformar dados rigidos em registries reloadaveis | Editar dados principais in-game | Pendente |
| 5 - Limpeza final | Reducao de peso | Remover redundancias e loops antigos | Startup limpo e FPS melhor medido | Pendente |

## Regras De Arquitetura

| Regra | Aplicacao pratica | Motivo |
|---|---|---|
| `qbx_core` continua nucleo | Nao inverter dependencia para `forge_core` | Preservar identidade e compatibilidade da framework |
| `forge_core` auxilia | Ferramentas in-game, cache auxiliar, paineis e operacao | Evoluir sem trocar o coracao da base |
| Sem refactor cego | Toda mudanca deve ter medicao ou gargalo identificado | Evitar criar peso novo |
| Compatibilidade primeiro | Exports/events atuais devem continuar funcionando | Nao quebrar scripts existentes |
| Cache com invalidacao | Consulta no banco apenas quando necessario | Reduzir latencia e carga |
| Statebag com prudencia | Usar so para dados que precisam replicar | Evitar excesso de sync |
| Shared como fallback | Arquivos podem existir como boot/fallback, nao como prisao | Permitir edicao in-game e reload |

## Diretorios Importantes

| Uso | Caminho |
|---|---|
| `forge-core` | `E:\QBOXPIERRE\resources\[teste]\[pierre]\forge-core` |
| `luac` | `E:\QBOXPIERRE\[PASTAS]\LUAC` |

