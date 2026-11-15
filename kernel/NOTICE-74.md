# Lote74 — idiomas locais/imports servidor

36 JSONs copiados da instalação QBX para kernel/locales, preservando autoria/licença QBX (kernel/LICENSE-QBX). Nova factory PR de locale deriva do import ox_lib sob LGPL-3.0 ou superior; copyright Linden preservado no fonte. Não substitui Locale QB07 ou Locale PR, nem instala o ox_lib de novo.

Contexto servidor preparado explicitamente sobre72 com tradução antes de Commands/Player/Lifecycle/Character e cache nativo PR73 distinto do cache passivo. Eventos/export de idioma são guardados/possuídos pelo contexto; carga e preparação não são ativação do manifesto. Testes cliente73/servidor72 usam os JSONs locais e motores instalados com IO/JSON/Cfx/clock virtuais. Não prova rede/msgpack, boot, entrega ao cliente, durabilidade ou descarte integral. Imports públicos/compat/readiness e teste real autorizado seguem gates.
