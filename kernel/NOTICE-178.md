# Etapa178

Resolvedor privado de fábricas PR usadas pelos contextos. Carrega somente caminhos explícitos, não framework/compat público. Fábricas são lazy; construtor nenhum é chamado no resolver. As instâncias continuam pertencendo aos contextos e recebem guarda combinada de propriedade. Os serviços raw canônicos123 substituem as factories servidor correspondentes antes da montagem, conforme135.
