# Starterpack — veículo no chão e embarque do Lamar

Implementado em 04/10/2026. Validação isolada aprovada; homologação visual no FiveM pendente.

## Índice

- [Causas encontradas](#causas-encontradas)
- [Correções](#correções)
- [Custo e limites](#custo-e-limites)
- [Verificação](#verificação)
- [Teste no jogo](#teste-no-jogo)

## Causas encontradas

1. O Starterpack criava o carro pelo PRBridge com `placeProperly`, mas essa chamada tentava assentar apenas uma vez, sem aguardar colisões nem propagar o resultado do assentamento. Depois, o Starterpack congelava o carro independentemente desse resultado. Um cenário criado antes do streaming do chão podia permanecer suspenso.
2. A tarefa normal de entrada do Lamar estava correta, mas o loop de contenção do jogador aplicava tranca `4` a cada quadro durante essa mesma entrada. O NPC encontrava o carro trancado e tentava entrar à força.

O editor PRBridge salva a origem do modelo já ajustada em relação ao chão. O Starterpack não deve acrescentar novamente a altura do modelo.

## Correções

Alterações restritas a `client/starterpack/main.lua`, sem alterar o PRBridge nem o PR Carkeys:

- Preparo automático aguarda sessão carregada e aproximação até 200 metros do ponto do veículo. Não cria um carro distante durante a seleção de personagem/spawn.
- Na criação, solicita colisões, preserva a origem/posição e o rumo salvos, aguarda colisão e tenta assentar o veículo por até 5 segundos, com intervalo de 50 ms.
- Só aceita sucesso confirmado e mantém o carro estacionado após um quadro de atualização da física. Se não conseguir, remove a tentativa, sem deixar carro flutuante ou NPC/target associado a essa tentativa.
- Preparo automático pode tentar novamente até três vezes, com intervalo de 5 segundos. Após isso, mostra a mensagem de falha já traduzida; o administrador deve revisar modelo/chão/posição e testar novamente.
- Carro permanece destrancado para entrada normal do Lamar. A contenção do jogador usa os controles de entrar/sair, direção, aceleração, freio, freio de mão e combate, além da proteção de assento já existente.
- Freio de mão/imobilização durante o embarque são independentes das trancas. Após embarque, a condução automática segue o fluxo existente.
- Controles são liberados na conclusão, falha de embarque, morte, substituição do ped, troca/saída de personagem e parada do recurso.
- Um identificador local da cena impede preparos cancelados e timers antigos de apagar ou controlar uma cena nova.
- Posicionamento do Lamar, chaves/propriedade, recompensas e persistência do Starterpack não foram modificados.

O retorno da nativa deve ser conferido para confirmar o assentamento: [contrato oficial de SetVehicleOnGroundProperly](https://github.com/citizenfx/natives/blob/master/VEHICLE/SetVehicleOnGroundProperly.md).

## Custo e limites

- Nenhum novo state bag, evento recorrente de rede, escrita em JSON/SQL ou loop de jogadores no servidor.
- Enquanto o cenário ainda não foi preparado, o cliente verifica apenas a distância até um único ponto a cada 2 segundos. Essa verificação para ao preparar a cena ou desativar/trocar sua configuração.
- A espera por colisão é limitada e só ocorre no preparo. Não há nova varredura de veículos para assentamento ou embarque.
- O bloqueio de controles usa o loop por quadro já necessário à cena; chamadas duplicadas de controles e a atualização redundante no loop de rota foram removidas.
- A limpeza de trânsito à frente durante a rota é comportamento anterior; não foi expandida ou redesenhada nesta correção.
- Não existe garantia de suporte a 2.000 jogadores sem teste de carga real. Este ajuste não foi homologado com FXServer/jogadores conectados.

## Verificação

`tests/starterpack_scene_test.lua` carrega o código real do Starterpack com providers/nativas simulados, sem gravações reais. Cobre:

- colisão atrasada, assentamento com falhas iniciais, retorno numérico de sucesso, origem e rumo salvos;
- chão/colisão indisponíveis e handle inválido;
- preparo simultâneo, cancelamento durante carregamento do modelo e assentamento;
- login distante, criação na aproximação, parada do timer após sucesso e limite de tentativas;
- entrada normal do Lamar sem trancar a porta, controles bloqueados e reposição do jogador se uma saída externa for forçada;
- término, timeout de embarque, morte, troca de ped, logout e parada do recurso;
- timer de conclusão antigo não remove cena nova.

Regressão: 18 suítes Forge Core e 7 suítes PRBridge, sem gravações em dados reais. Sintaxe de todos os 183 arquivos Lua do Forge Core validada com `luac55.exe`.

## Teste no jogo

1. Recarregar `forge-core` em momento seguro; não foi reiniciado automaticamente.
2. Reutilizar o posicionamento já salvo do carro/Lamar e testar. Confirmar rodas apoiadas no chão, posição e rumo corretos, também após reconexão e aproximação vinda de outra região.
3. Entrar como motorista: Lamar abre a porta e senta sem quebrar vidro; jogador não sai, acelera, freia ou interfere na direção durante a cena.
4. Confirmar trajeto, câmeras, recompensas e saída normal ao final. Os controles devem voltar e Lamar deve ir embora.
5. Em cópia de teste, interromper embarque/recurso ou trocar personagem e verificar que não restaram bloqueios/tarefas da cena anterior.
6. Manter o PR Carkeys ativo e testar carros normais depois da cena. Esta alteração não concede chave nem modifica suas regras de acesso/motor.

As nativas físicas e a convivência visual com mapas/props personalizados exigem essa validação no jogo; os mocks não comprovam contato real das rodas ou animação do vidro.
