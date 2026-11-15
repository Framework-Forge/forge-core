# Lote 27 — Staff privado/inativo
Porta as configurações, serviço integral legado+v2, cinco callbacks, três comandos e seis métodos de menu instalados. Mesmo Player/Lookup/Groups/JobService/Security/Menu; sem QBX externo ou PR framework para funções próprias. PR continua responsável por DB, catálogo/consulta ACE, notificações, menus e RPC.
A consulta ACE exige integração PR explícita segura: o provider instalado pode resolver identidade via Bridge.framework e não deve ser ligado silenciosamente pelo bootstrap. Testes usam provider instalado com lookup local injetado; binder PR seguro ainda é lacuna.
Não há grants/SQL real, instalação, start, timer ou registro público no construtor. Defeitos de confirmação/persistência, efeitos parciais/identifiers/legado/timers e locks preservados, não corrigidos silenciosamente. Não ativa o núcleo ou muda dados/nomes/ACE/arquivos originais.

