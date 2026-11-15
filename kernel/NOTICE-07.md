# Lote 07 — biblioteca e helpers

Porte dos fontes instalados qbx_core/modules/lib.lua, shared/locale.lua, modules/playerdata.lua e server/vehicle-persistence-compat.lua. Licença integral em LICENSE-QBX; comentários/atribuições de origem preservados. Composição helpers.lua é privada e nova.

Sem manifesto, globais qbx/QBX/Locale ou registros automáticos. Library/native/audio são portas explícitas; consultas de catálogo, buckets e persistência usam serviços internos. Integração de pr_3dsound pelo PR Bridge ainda deve ser implementada e ligada; não há chamada direta externa nesta cópia. Algoritmos e retornos instalados permanecem, inclusive particularidades legadas.

Playerdata é apenas uma vista importada para consumidores de compatibilidade, não estado autoritativo. Seus handlers sem guarda não podem substituir client/events do núcleo. Imports públicos e locales JSON estão pendentes; utils legado também não foi portado neste lote. Nenhuma entidade, áudio, banco ou operação de recurso real foi executada.
