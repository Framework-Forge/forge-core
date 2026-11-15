# Lote 24 — pontos/negócios cliente inativos
Porte integral dos arquivos instalados client/job/points.lua e business.lua do Forge, com três módulos privados e dependências explícitas. GetPlayerData/GetJobInfo do núcleo são locais; PR permanece biblioteca e camada de integrações. Eventos são descritores, timers só existem após chamar APIs; não há zonas/instalação/IO no construtor.
Minigame Glitch depende de portas futuras PR com estado/assinatura exatos; sem export externo ou alteração no PR. Preservados os riscos de debounce/stop/unload/callback antigo/erro parcial. Testes em memória não autorizam ativação nem equivalem a uso real de alvo/inventário/UI.

