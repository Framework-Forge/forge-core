# Lote33 — preparação privada/inativa
20/10/2026. Ver [.planning/migration/LOTE-33.md](../../../../../.planning/migration/LOTE-33.md).

Cliente integral de whitelist, dezesseis métodos de menu, editor AFK e composição no mesmo
ProducerCore/WorkMenus/AdministrationMenus/Forge Session31. Nenhum manifesto público alterado.
Três callbacks, quatro ouvintes e um worker inicial são descritores, não instalações.
Workers dinâmicos seguem a implementação instalada e só nascem ao executar suas ações.

UI/target/notificações/RPC permanecem PR. ShowTextUI/HideTextUI usam as funções públicas PR
que bridge/init.lua atribui também ao adaptador de framework. Nenhum acesso ao framework PR
para executar operação interna. A consulta externa spacebox_multichar exige uma porta de
integração para PR preservando resourceState/pcall/retorno; binder público ainda pendente.
O pai menu_server e fetchAfkSettings continuam pendentes. Não há dois editores AFK privados.

Preservados os contratos QB/QBX, temporizações, retornos e falhas herdadas, inclusive add
administrativo no servidor e nota no cliente, respostas/diálogos tardios sem guarda adicional,
finish sem limpeza imediata do target/blip, possíveis workers concorrentes após reentrada,
mutação antes da confirmação e locks retidos após erro. Nenhuma correção implícita aprovada.

Testes executam somente natives/tempo/UI/transporte/JSON/DB virtuais. Não representam
NUI, FiveM, SQL, bucket, webhook, saldo, item, ACE ou corte operacional reais.
Licença QBX continua integral em LICENSE-QBX. Nenhum start/restart/renomeação/exclusão permitido.
