# Lote 43 — fazendas/farms

Porta privada dos cinco fontes Forge instalados: shared/farms.lua, server/farms/service.lua e callbacks.lua, client/farms/main.lua e client/menu/menu_farms.lua. Preservar autoria/licenças; não substitui LICENSE-QBX dos lotes de núcleo.

Sete módulos fora do manifesto. PlayerData/job/gang e catálogo de veículos usam Lookup/JobCatalog/runtime10 locais; inventário/progress/targets/context/devlaser/persistência continuam PR. Fallbacks raw de AddItem/Search/SetDurability/Items são contratos explícitos para futuro binder, não exports diretos.

Preservados os riscos herdados: validação de ponto/tempo/veículo/maxPerRoute parcialmente ou somente cliente, falta de atomicidade de durabilidade/recompensas, rotas por source e trabalho tardio após refresh/stop. Descritores estáticos não executam workers; threads de animação/captura agendadas somente na ação. Testes virtuais não provam MIG-23, uso de itens/durabilidade reais, CEF, FiveM, durabilidade JSON ou prontidão operacional. Nenhuma ativação autorizada.
