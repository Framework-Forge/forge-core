# Etapa175

Portas nativas de idiomas com os serviços PR existentes. Forge domain usa bridge/locale e arquivos locale reais; runtime QBX usa forge_locale e kernel/locales. Configuração PR de idioma prevalece e fallback usa getLocaleKey do PR. Sem inicializar adaptador de framework ou registrar eventos/exports. Os contextos74/75 continuam responsáveis por inicialização e ciclo de vida da tradução posicional.
