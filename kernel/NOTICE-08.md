# Lote 08 — utils legado e cliente

Porte dos fontes instalados qbx_core/modules/utils.lua, client/functions.lua e client/groups.lua. Licença integral em LICENSE-QBX; referências/comentários de origem preservados. Composição legacy_core.lua nova e privada.

Nada carregado pelo manifesto. Globais legados e extensões math/string tornam-se tabelas privadas; avisos e sincronização inicial são explícitos. Biblioteca local Lib e membership permanecem internos. Inventário Search e Notify são portas para o PR Bridge, sem chamada direta a OX. Não há nova autoridade PlayerData ou encaminhamento PR framework de volta ao núcleo.

Preservadas particularidades/limitações instaladas, inclusive retornos legados de DeleteVehicle, defaults de partículas/horário, erros de bone e algoritmo KickWithReason. Entrada nil nesse último pode girar sem yield; scheduler real não foi executado. Imports públicos e bootstrap/cleanup reais ainda precisam de revisão; este lote não autoriza sua ativação ou correções silenciosas.
