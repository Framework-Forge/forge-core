# Lote52 — callbacks privados, ainda inativos

22/10/2026. Três fábricas novas Forge e uma fábrica privada PR; nenhuma entrada de manifesto/bootstrap alterada. Nenhum fonte original ou captura01–51 alterado. Licenças e atribuições anteriores permanecem.

Instalação explícita sobre os mesmos blocos48/50;201 callbacks servidor (196 Security, quatro Character ox, um World nativo),13 cliente (quatro ox/nove nativos). Propriedade por lease, protocolo preservado, reserva antes de bind, descarte inverso e wrappers desativados antes da remoção. Security compila o próprio wrapper com capturador entregue antes da construção; a mesma library é uma porta explícita de composição. Não copiar regras de permissão nem usar PR framework para operações internas.

O novo módulo PR não adota engines públicos já instalados. Open recebe as opções do adapter correspondente e cria um transporte exclusivo: o futuro bootstrap deve garantir um único engine por protocolo/contexto e verificar o namespace externo completo antes de reservar. Não abrir em paralelo com o legado no mesmo contexto. O binder não faz essa substituição operacional.

Testes usam os arquivos PR instalados de native, ox_callback, transport e registry em ambiente virtual; os adapters só encaminham a fábrica do engine ao proprietário privado. Nativos/event bus/tempo/ACL/SQL/JSON/providers são virtuais. Não constitui boot FiveM, teste CEF, durabilidade, compatibilidade integral ou MIG-23. A remoção de registros não encerra listeners-base, rede registrada, requests/timers/handlers em andamento. Falha após efeito sem token/claim confirmado não tem rollback garantido. R07 continua aberto; R01/R04/R06 também.

Sem restart/corte, alterações de banco/JSON operacional, renomeação, remoção do QBX, instalação pública ou dependências. Primeiro teste de inicialização ainda NÃO pronto. Ver .planning/migration/LOTE-52.md.
