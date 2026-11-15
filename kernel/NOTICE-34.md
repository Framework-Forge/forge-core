# Lote34 — senha, backup e configurações (inativo)

20/10/2026. Ver [.planning/migration/LOTE-34.md](../../../../../.planning/migration/LOTE-34.md).

Nove módulos privados: duas configs integrais, dois serviços, quatro descritores de callbacks
administrativos e composições servidor/cliente, com o painel menu_server completo menos o
editor AFK já portado33. Reutiliza Job/Staff/Security e Menu/Shared/Access canônicos.

Nenhum start de serviço, ouvinte de conexão, RPC, contexto, timer, SQL ou JSON operacional é
executado pelo construtor. wrapJsonMutations somente decora o método local save com lock.
O local resourceName legado é consultado por porta nativa e não inicializa outro recurso.
Ouvinte playerConnecting é descritor inativo; sua instalação/fila/deferrals fica para o boot.

JSON e backup continuam PR. Gerador SQL instalado em PR foi testado sobre SHOW/SELECT e
SaveResourceFile virtuais, sem banco real, arquivo SQL real ou restauração.
As chamadas OpenAdminMenu externas exigem porta de integração para PR, com started/pcall,
mesmo parent/owner e sem atalho direto. Binder público ainda pendente.

Preservados máscara de leitura, retorno cru de save, snapshot de senha anterior à espera,
done repetido/sem timeout, backup antes start, running/histórico/nome do mesmo segundo,
falha de histórico ignorada e retorno nil/0 aceito pelo writer SQL PR.
A expressão de error do histórico guarda tostring(result) mesmo em sucesso. Não foi corrigida.
Timers/locks de UI e consumidores futuros permanecem explícitos; menu não está pronto para boot.

Licença original preservada em LICENSE-QBX. Sem controles de recursos, grants, SQL/dados/backup
operacional, itens/saldos/ACE, renomeação ou exclusão de originais.
