# Lote 35 — preparação privada/inativa

Porta integral de configurações clima/densidade, política/callbacks, estado público de mundo, dois workers de densidade e menus. Não carrega pelo manifesto nem registra callbacks/eventos/exports, limpa cache, inicia worker ou lê/grava JSON no construtor. Initialize/start e instalação de descritores pertencem ao bootstrap futuro. Serviços internos usam o mesmo Player/Job/Security/Menu/Shared; o estado público não é autoridade PlayerData/Session.

Clima/horário e painel persistente permanecem externos via PR. OpenWeatherAdmin exige binder PR futuro, sem fallback direto novo. GetCachedState mundo e export homônimo QBX são descritores separados: facade pública ainda deve resolver a colisão, sem renomeação neste lote. PR cache continua passivo; espelhamento SetResourceState de consumidores públicos precisa de entrega explícita futura, nunca polling/getter com export.

Preservados revisão por relógio, merge por índice, retornos/truthiness/erros, densidade0 ao desabilitar e ausência de restauração de modelos/cenários/dispatch. Nenhuma correção silenciosa. Testes usam Lua5.4 e PR instalado, com IO/JSON codec/relógio/nativos/rede/UI e exports Renewed virtuais. Entry do painel externo exercitado integralmente; motor/configs/permissões próprios do provedor não declarados auditados.

Sem alteração dos fontes ativos QBX/PR/OX/Forge, JSON operacional, banco, manifesto ou boot. Licenças originais permanecem nos recursos e [LICENSE-QBX](LICENSE-QBX) mantém integralmente a licença QBX; não presume mudança de licença do código Forge ou provedores. Ver plano, regras e [lote35](../../../../../.planning/migration/LOTE-35.md).
