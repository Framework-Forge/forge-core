# Lote 46 — consumidores VIP e slots/prévias

Preparação privada/inativa dos corpos completos instalados de shared/character_slots.lua, server/character_slots/service.lua e callbacks.lua, server/vip/callbacks.lua, client/menu/menu_vip.lua e menu_character_slots.lua; composições locais adicionais.

Não consta do fxmanifest. Não altera arquivos originais, dados/tabelas, QBX, PR/Syn_Sit, inventário personalizado ou tempo mínimo da loadscreen. Mantidos contratos legados, payloads, erros e comportamentos herdados catalogados em LOTE-46.md. Política slots11, Player/Lookup/Logout, VIP16 e State35 permanecem únicos.

PR continua responsável por recovery/lock, catálogo OX, uso/remoção/reembolso/registro de item, RPC, menus e posicionador animado. As rotas para o próprio núcleo são internas, não exports externos nem PR framework. Callbacks/exports/eventos são descritos e não instalados automaticamente; start permanece explícito.

Testes em memória não comprovam SQL/IO durável, provider OX/CEF/editor, artefatos/streaming nem boot FiveM. Bootstrap, binders PR, compatibilidades, descarte e decisões herdadas exigem gates próprios antes da ativação. Nenhuma guarda dos lotes anteriores foi afrouxada.
