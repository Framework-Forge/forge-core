# Lote51 — registro privado de eventos

Três fábricas privadas ligam os eventos já descritos pelos blocos servidor48/cliente50 a portas explícitas de registro/remoção/origem/marca de rede. Construção inativa, instalação única explícita, descarte inverso com wrappers desativados antes das remoções. Mesmos produtores/serviços/dados; assinaturas antigas recebem origem na entrada, handlers Forge recebem payload conforme cada contrato. Fan-out legítimo e ordem relativa dos manifestos preservados.

Capturas e corpos01–50/licença/autoria/nomes QB/QBX/PR/inventário personalizado intactos. Fora do manifesto: nenhum restart, boot, serviço, timer, SQL ou dado operacional iniciado. Testes em bus/nativos/IO virtuais. Remoção cobre apenas tokens retornados; marca de rede não reversível; não cancela chamadas/timers já iniciados, não promete rollback de ação externa que falhou antes de devolver token.

Callbacks/protocolos PR nativo/ox, comandos, exports conflitantes, statebags, keybinds, subscrições/threads e initializers ainda exigem binders/ordem/limpeza próprios. Não é instalação pública, migração completa, prova MIG-23 nem autorização/prontidão de teste real FiveM.
