# Lote 06 — configurações, hooks e logger

Porte privado de qbx_core/config/{shared,server,client}.lua e modules/{hooks,logger}.lua instalados neste workspace. Licença integral preservada em LICENSE-QBX; avisos de autoria originais, inclusive Linden/Dunak/Luke no módulo de hooks, mantidos. Composição nova em support.lua.

Não carregado pelo manifesto. Nomes/formatos QBX, defaults e regras específicas da base preservados. Closures são implementações locais; nenhum require/export para o QBX em execução. Chaves de veículos e logs de biblioteca são portas explícitas para o futuro PR Bridge; adaptadores faltantes são pendências, não atalhos implementados. HTTP Discord é porta de plataforma e não é executado na construção.

Hooks internos mantêm ownership, IDs, veto/exceção/tempo e limpeza por recurso; não substituem os hooks do inventário. Verificação legada de dependência e instalação dos descritores só podem ocorrer no bootstrap revisado/autorizado. Nada nesta pasta autoriza iniciar recursos ou alterar banco.
