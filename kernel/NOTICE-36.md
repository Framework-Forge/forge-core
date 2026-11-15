# Lote36 — catálogo e administração de veículos (privado/inativo)

Sete módulos: configuração, catálogo, projeção interna, callbacks administrativos, composição servidor e menu/composição cliente. Mantêm implementações Forge instaladas e o corpo interno do setter runtime10; Shared.SetVehicles é a única mutação dos índices por nome/hash. Guarda pública do runtime10 permanece intacta, enquanto chamada interna não herda caller de outro recurso que antes era substituído pelo export intermediário Forge→QBX.

Nenhum construtor lê/grava catálogo, registra eventos/callbacks/exports/contextos ou inicia timer. Initialize apenas prepara futuramente a leitura e sync original. Descritores não são instalados. Helpers07/Persistence, lookup/Player/Security/JobService e Menu/Shared/settings34 são os mesmos canônicos.

IO do catálogo é local ao próprio recurso, com portas raw explícitas: não trocar por PR JSON recovery sem decisão, pois retorno0/nil, backup, lock e erros diferem. Integrações de chaves temporárias, DB, streaming, propriedades e UI continuam PR. BuyOriginalKey e notificação de veículo existente à garagem exigem binder PR futuro, sem export/evento externo direto novo no kernel.

Preservados save anterior a sync, campos/defaults/aliases, import load em ambiente vazio (sem orçamento no runtime), ausência de transação/lock e falhas/rollback/aceites herdados. Testes têm limites de instruções somente no harness. Não equivalem a SQL/banco/chave/item/veículo real nem provam entrega item quando o provedor ignora AddItem.

Origens/capturas anteriores, Syn_Sit, JSONs operacionais, manifesto/boot e dados permanecem intactos. Licenças originais e [LICENSE-QBX](LICENSE-QBX) preservadas. Ver [lote36](../../../../../.planning/migration/LOTE-36.md).
