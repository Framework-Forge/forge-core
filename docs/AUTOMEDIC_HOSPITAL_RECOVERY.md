# AutoMedic — recuperação hospitalar e correções de inicialização

Implementado em 04/10/2026. Testes Lua isolados aprovados; teste visual/funcional no FiveM pendente. O servidor não foi reiniciado automaticamente e nenhum JSON de produção foi editado pelos testes.

## Índice

- [Erro das lojas](#erro-das-lojas)
- [Cadastrar leitos](#cadastrar-leitos)
- [Fluxo médico](#fluxo-médico)
- [Segurança e desempenho](#segurança-e-desempenho)
- [Tecla C nas paredes](#tecla-c-nas-paredes)
- [Roteiro de homologação](#roteiro-de-homologação)

## Erro das lojas

O escritor JSON novo comparava o retorno de `SaveResourceFile` exclusivamente com o booleano `true`. O wrapper Lua do artefato instalado usa `Citizen.ReturnResultAnyway()`; a nativa pode expor o resultado BOOL como inteiro `1`/`0`. Uma gravação com retorno `1` era rejeitada, incluindo a preparação de backup, impedindo a inicialização das lojas.

O PR Bridge agora aceita **`true` ou `1`**, e continua recusando `false`, `0`, `nil` e exceções. Não foi removida a proteção de persistência nem aceito qualquer valor simplesmente por ser truthy em Lua. A falha real informa recurso, caminho e tipo/valor do retorno, sem exibir o conteúdo salvo. A inicialização das lojas conserva o motivo específico (`backup_failed`, `save_failed`, etc.), em vez de esconder todos sob a mesma mensagem genérica.

Cobertura: fábrica de persistência, carregador `bridge/core.lua`, backups, retorno inteiro, rejeição de zero/nulo e dados confirmados preservados. O erro observado é compatível com essa incompatibilidade; a inicialização real ainda deve ser confirmada no servidor do usuário.

## Cadastrar leitos

No painel administrativo do Forge Core:

1. Abrir **Auto Atendimento Médico → Leitos de recuperação → Adicionar leito**.
2. Ficar no piso ao lado de uma cama do hospital. Essa posição será a saída segura inicial.
3. Informar nome e escolher `v_med_bed1` ou `v_med_bed2` como identificação da cama existente.
4. No posicionador animado do PR Bridge, alinhar o ped **deitado** sobre a cama, ajustar direção/altura pelos controles do editor e confirmar com ENTER.
5. Se necessário, usar **Definir saída na minha posição**, estando novamente no piso ao lado da cama. A saída deve ficar a até 10 metros da pose.

Não há inputs numéricos de coordenadas. São aproveitadas camas já presentes no mapa; cadastrar um leito **não cria um segundo prop**, nem remove a cama do mapa ao excluir o cadastro. O editor mostra a animação que será usada na recuperação. A posição salva segue o mesmo ajuste da origem do ped usado pelo editor, evitando uma diferença de altura entre preview e execução.

É possível cadastrar vários hospitais e vários leitos. Cada entrada permite reposicionar, definir saída, marcar como **leito da prisão** e remover. Os submenus mantêm o menu pai. A imagem do modelo usa a API de imagens do PR Bridge.

Os registros são persistidos em `data/automedic.json`, dentro de `beds`; configurações antigas continuam válidas, com lista inicialmente vazia. É necessário cadastrar pelo menos um leito compatível para o fallback funcionar.

## Fluxo médico

- O atendimento normal por NPC continua disponível, com cooldown, cobrança, perda de inventário e saúde configurados anteriormente.
- Falha de carregamento/criação do médico, NPC perdido/morto, tempo de chegada excedido, falha de posicionamento ou de animação podem acionar a recuperação hospitalar.
- O cliente apresenta o token do atendimento aprovado e um motivo conhecido. O servidor valida personagem/estado de morte e escolhe o leito compatível **livre mais próximo** da posição do jogador observada no servidor.
- O mesmo fluxo de cobrança/inventário/reanimação é usado uma única vez. Não é solicitado outro tratamento nem feita uma segunda cobrança pelo transporte.
- A tela escurece; são solicitadas colisões do destino; o jogador é reanimado e aparece deitado no leito.
- **E** executa a animação de sentar na beira/levantar e coloca o jogador na saída segura cadastrada, liberando a reserva.

Quando não há leitos livres/compatíveis, o atendimento não inventa coordenadas nem debita pela recuperação: informa a indisponibilidade e cancela a tentativa. Existe também a opção **Hospital quando o NPC falhar** para habilitar/desabilitar o fallback.

## Segurança e desempenho

- Configuração/cadastro/exclusão exigem autorização administrativa no servidor.
- Coordenadas finitas, modelo permitido, identificador, direção e distância da saída são validados; o cliente não fornece o destino do fallback.
- Token de atendimento vinculado ao personagem; duplicatas e conclusão concorrente são recusadas.
- Um leito reservado não é reutilizado até a saída, morte, descarregamento do personagem ou desconexão. Reservas são separadas por routing bucket.
- Jogador **preso** só usa leitos marcados para prisão. Jogador livre/foragido usa os demais; não é alterada a pena nem permitido escapar para um hospital civil.
- Respostas/threads antigas não reposicionam um personagem após troca de sessão. Falha de animação não deixa tela preta/ped congelado permanentemente.
- Não foi adicionada varredura global de leitos, objetos ou jogadores. A seleção ocorre apenas quando o NPC falha; a lista persistida de leitos não é gravada em cada atendimento. Reservas são memória temporária ligada ao personagem.
- Carregamento de colisão/animação e saída da cama só executam durante a recuperação local. Não foi acrescentada uma rotina de polling em repouso para os leitos.

Isso não homologa a base para 2.000 conexões. A consulta aos leitos é linear no número de leitos configurados, feita somente no fallback; a meta de capacidade ainda exige medição no FXServer. Não foram alterados os gargalos de catálogo JSON/rede das lojas já descritos em [Persistência e desempenho](JSON_PERSISTENCE_PERFORMANCE.md).

## Tecla C nas paredes

Dois probes de colisão sob demanda identificam a superfície vertical antes da procura por assentos. O resultado do shape test é aguardado com prazo limitado; um resultado ainda pendente não é interpretado como ausência de parede.

Paredes usam as mesmas animações masculinas/femininas de encostar utilizadas em veículos, com entrada/base/idles/saída e publicação na postura `lean` do cache. **C** também encerra essa postura. Bancos/bordas/chão mantêm o fluxo de sentar; **O** conserva o fluxo de encostar em veículos. Posturas concorrentes são bloqueadas enquanto o jogador está no leito.

## Roteiro de homologação

1. Reiniciar a base em manutenção para carregar PR Bridge/Forge Core atualizados; conferir que as lojas iniciam sem a rejeição falsa do retorno `1`.
2. Configurar leitos em dois hospitais, testar pose e saída em cada cama/modelo e confirmar persistência após novo reinício.
3. Falhar uma chegada/posicionamento do NPC; confirmar hospital mais próximo, tela, roupa/modelo do personagem, saúde e animação deitada.
4. Pressionar E e verificar animação de saída, piso correto e liberação do leito.
5. Fazer dois atendimentos simultâneos; verificar que não usam o mesmo leito no mesmo bucket. Testar todos ocupados e nenhum configurado.
6. Verificar atendimento normal por NPC, cobrança/inventário de cada categoria e ausência de dupla cobrança.
7. Testar preso/foragido/livre, logout durante carregamento/recuperação e reinício do recurso sem ped congelado.
8. Testar C em parede, banco, borda e chão; O em veículo; confirmar postura visível para outro jogador próximo.

Suítes específicas: `automedic_hospital_test.lua`, `hospital_client_test.lua`, `automedic_menu_test.lua`, `wall_posture_test.lua`, `pr_bridge/tests/json_persistence_test.lua` e `pr_bridge/tests/json_native_contract_test.lua`. Incluem o roteamento real de falha de modelo do NPC até a recuperação, além dos testes anteriores de cache/postura/persistência.
