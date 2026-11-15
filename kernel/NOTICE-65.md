# Procedência e limites — lote65

Extensão privada PR de chaves e aviso ao Forge Garage, com contexto sobre o lote64. Não carregada por manifesto. Reutiliza contratos locais PR/pr_carkeys e evento instalado Forge Garage, sem criar persistência, framework ou cache duplicados. Persistência interna continua em Helpers07.

Testes executam sv_shop.lua instalado inteiro e o handler instalado da garagem extraído sem reescrita; banco/inventário/entidades/tempo/transport são virtuais. Temporárias/locks são conferidos pela delegação PR e configuração06, não pelo runtime completo externo. Compra original pode indicar sucesso mesmo se AddItem falhar; entrega à garagem não tem ack/retry. Close não desfaz efeito aceito. Nenhuma nova política para R01/R04/R06/R07, rename/corte/SQL/ativação. Ver .planning/migration/LOTE-65.md.
