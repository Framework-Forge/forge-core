# Forge Core — migracao para PR Bridge

## Concluido nesta revisao

- Reconciliacao de empregos/gangues persistidos e consulta alternativa de funcionarios usam `pr_lib.database.query` / `transaction`.
- Consulta com falha nao e tratada como lista vazia; transacao com falha nao e reportada como sucesso.
- Nenhuma referencia direta a `ox_lib`, `ox_target`, `oxmysql` ou `MySQL` permanece nos arquivos Lua do Forge Core.
- Menus usam a interface nativa publicada pelo PR Bridge. Target esta configurado como `native`; progress usa o provider nativo. Notificacoes client usam `pr_lib.Notify`; envio server passa pelo evento do PR Bridge.
- Corrigido o receptor de `bridge:notify`: somente o host pr_bridge registra o evento, embora o modulo seja importado por varios resources. O host usa `Bridge.Notify`, a interface nativa. Nao foi aplicado um filtro que descartasse notificacoes legitimas repetidas.

## Banco de dados

O driver e selecionado no PR Bridge (`Config.Database`): `auto`, `oxmysql`, `ghmattimysql` ou `mysql_async`. A disponibilidade de um driver adicional exige um adaptador implementado no bridge. Os drivers alternativos nao foram testados contra bancos reais nesta revisao.

## Escopo

Revisão de consistência JSON e desempenho (03/10/2026): rascunhos, confirmação após salvar, compensações, testes de falha e limites para a meta de 2.000 jogadores estão em [JSON_PERSISTENCE_PERFORMANCE.md](JSON_PERSISTENCE_PERFORMANCE.md). Implementação verificada em testes isolados; aprovação no jogo e teste de carga permanecem pendentes.

As integracoes existentes do Forge Core com qbx_core e ox_inventory foram preservadas. Esta migracao nao remove dependencias internas desses dois resources. Portanto, nao comprova que o ox_lib ja pode ser parado em toda a base.

## Validacao

`.tmp/validate-forge-core-migration.py`: sintaxe de 156 arquivos Lua (hash literals FiveM normalizados apenas no teste), cinco consumidores de notificacao com um unico receptor, reconciliacao sem registros, falha de consulta sem escrita, ajuste/remocao em transacao e falha de commit. Auditoria estatica das referencias diretas acima.

## Testes no jogo

1. Reiniciar a base em manutencao para descarregar tambem os receptores antigos dos consumidores do PR Bridge.
2. Spawnar um veiculo pelo painel: conferir uma notificacao de resultado, sem varias copias da mesma placa.
3. Conceder/remover uma permissao de staff e conferir uma notificacao por envio previsto. Notificacoes destinadas a pessoas diferentes devem continuar funcionando.
4. Abrir menus, formularios, targets de lojas e as barras de progresso do Forge Core.
5. Consultar funcionarios e editar empregos/cargos; verificar servidor sem erros de banco. Nao testar reconciliacao destrutiva contra dados de producao.
6. Antes de remover ox_lib da base, concluir separadamente a auditoria dos resources ainda dependentes.
