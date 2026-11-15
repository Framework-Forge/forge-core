# Lote39 — NPCs (privado/inativo)

Porte integral das sete origens Forge instaladas (três configs, serviço/callbacks, cliente e menu). Nove módulos privados e quatro suítes/harness novos. Não estão no manifesto. Sem nomes/tabelas/dados/boot novos ou execução junto às origens.

Serviço usa mesmo JobService/Security/World35; getAll player/seis mutações admin. Cliente usa mesma ForgeSession31, Groups08 e Menu/Shared/settings34, ao lado de Objects38. Catálogos/presets completos preservados; configs já fornecidas não são sobrescritas. Construtores não iniciam serviço, workers, RPC ou registro de comando/eventos.

Menu não consulta exports do QBX: catálogo/readiness locais. Ações configuradas (D041/D042/comando) exigem porta explícita integration com resourceState/resolveExports/command/event para futuro binder PR; não há fallback direto novo. Resolver preserva lookup e chamada pcall sem self adicional, argumentos e retornos. Binder deve manter chamador/erros e revisar referência ao próprio núcleo, sem ciclo Forge→PR→Forge. Não é integração pública pronta.

PR recovery/cache/RPC/context/streaming/blips instalados executados nos testes; devtools.placePed/target/drawtext/action exports e Cfx nativos/IO/JSON codec/tempo/vetores são fronteiras virtuais. Não comprovam visual/IA/foco/CEF, segurança de serviços de terceiros, durabilidade nem boot.

Riscos herdados preservados: timers/streaming tardios, worker sem token de stop, target não reinstalado no cancel imediato, disabled mantendo handle existente, acesso job OU gang só no cliente e onSelect sem nova checagem, nil compactado no parser de argumentos, retorno false do export ignorado se pcall sucede, setOutline no-op, RPC lançando erro retendo placementActive/target desabilitado, revisão no mesmo tick e startflag anterior ao load. Mensagem devtools_failed pode vir mesmo com retorno true por expressão and/or da origem. Nada corrigido silenciosamente.

Ver .planning/migration/LOTE-39.md a partir da raiz. R01/R04/R06/R07 e binders/compat/bootstrap/descarte continuam pendentes. Sem autorização de restart/corte/SQL real.
