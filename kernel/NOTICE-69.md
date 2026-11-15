# Lote69 — streaming/áudio cliente

Factories privadas de portas PR e contexto sobre57–58; autoria/licença dos portes anteriores preservada. Um PlayerData/Helpers/Renderer, sem importar o núcleo antigo ou usar PR.framework. Não muda manifestos, loadscreen/tempo mínimo, posições ou política de asset do Renderer.

CloseIngress bloqueia create/request/som e fallback nativo; delete/release só entram por janela de limpeza da coroutine autorizada. Chamadas já aceitas podem terminar e produzir efeitos depois do fechamento; parada nativa é melhor esforço, sem rollback ou reprodução confirmada. Parte das recusas de streaming é ignorada pelo Renderer instalado e permanece assim; imports/compat/readiness/MIG-23 e R01/R04/R06/R07 continuam gates. Ver .planning/migration/LOTE-69.md.
