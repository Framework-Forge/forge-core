# Etapa174

Vista nativa própria para imports73/74. Leitura sob demanda por tick e refresh explícito, sem thread ou eventos de coleta e sem uso do cache passivo PR. Preserva o último ped válido durante transição ped=0 e valores false de veículo/assento/arma. O escopo é leitura dos consumidores inventariados; não implementa a API onCache do ox_lib.
