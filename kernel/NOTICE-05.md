# Correções autorizadas R08–R11 — lote 05

O usuário autorizou explicitamente estas quatro diferenças em relação ao QBX instalado. Somente cópias privadas e seus testes foram alterados; os recursos ativos, schemas e dados continuam intactos. Licença e autoria originais permanecem em LICENSE-QBX e avisos dos lotes anteriores.

- R08: snapshots aguardados e espontâneos são vinculados ao objeto, PlayerData, citizenid e geração do status. `_session`/`_character` são campos transitórios de transporte; não entram em PlayerData, metadata, catálogos, JSONs ou SQL. Servidor recusa payload sem identificação válida; cliente mantém high-water de geração e captura identidade antes de chamar extensões. Cliente/servidor portados devem ser implantados juntos no corte futuro. Não é um novo anticheat nem um segredo de autenticação.
- R09: drop limpa o mapa de buckets pelo source, como no cadastro, e não por license.
- R10: finalização de deferrals idempotente e recusa terminal, sem continuar para fila/admissão após ban/whitelist. A fila recebe uma fronteira `done` protegida; suas prioridades, timeouts e cards não foram alterados.
- R11: ownership revalidado após logger, snapshot, Save, eventos e espera de Logout; Save antigo não confirma revisão da sessão nova. SaveAll não troca o destinatário de uma operação já iniciada. Se o SQL antigo já foi emitido, sua persistência pode terminar para o objeto antigo, sem limpar/confirmar estado da nova sessão.

Não há ativação no manifesto. Capturas 01–04 são históricas e imutáveis; captura 05 registra exatamente sete substituições de artefatos e quatro novos testes/aviso. Comparações legadas normalizam apenas os dois campos aditivos de transporte; as proteções têm suítes dedicadas, sem exigir que o destino repita os defeitos.

R06 (dinheiro offline), R07 (listeners) e R01/R04 (inventário) não foram alterados. Nenhum restart, SQL real, teste visual/FiveM, renomeação pública ou corte foi autorizado por estas correções.
