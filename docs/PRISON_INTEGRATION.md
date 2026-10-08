# Integração opcional XT Prison

Implementada em 01/10/2026; aprovação no FiveM pendente.

- `server/player/prison.lua` usa o provedor de prisão do PR Bridge, sem dependência obrigatória de XT Prison.
- `bridge/prison/server.lua` no PR Bridge centraliza estado de recurso e exports do provedor.
- Dados próprios retornam pelo callback do F9. Dados de outro jogador passam pela gestão administrativa já autorizada.
- Definir e remover pena têm autorização de servidor pelo JobService/callback security do Forge; esconder a opção na interface não é a única proteção.
- Menus só mostram integração com provedor ativo; F9 exibe pena apenas quando preso.
- Textos novos em `locale/pt-br.lua` e `locale/en-us.lua`.
- Ações usam espera de 60 segundos porque entrada/saída incluem teleporte e streaming. O provedor possui deadline próprio de 45 segundos e rollback de pena em falha.
- Não foram modificados QBX Core, inventário, HUD ou outros recursos de gameplay.

Validação: 157 arquivos Lua do Forge aprovados em luac55; testes isolados do XT Prison carregam os menus e o serviço reais do Forge e conferem provedor parado, permissões, ações e dados. Não houve homologação em FiveM ou operação no banco real.

Roteiro completo em `resources/[standalone]/xt-prison/docs/FORGE_CACHE_MIGRATION.md`.
