# Easy Code

Jogo educativo em Godot 4. A cena principal é `app/app.tscn`: execute o projeto com **F6 nesta cena** ou **F5 em qualquer cena** para começar pelo menu.

## Editar as telas

Os layouts são cenas editáveis pelo Inspector:

- `app/app.tscn`: estrutura comum, botão Voltar e navegação entre telas.
- `ui/main_menu/main_menu.tscn`: menu inicial com título e botões Jogar, Opções e Sair em uma coluna centralizada.
- `ui/options_menu/options_menu.tscn`: opção de ativar ou desativar o tema escuro.
- `ui/theme_settings.gd`: tema global dos menus, cartões, detalhes e pausa; salva a preferência em `user://settings.cfg`.
- `ui/map_selection/map_selection.tscn`: seleção de mapas.
- `ui/level_selection/level_selection.tscn`: lista reutilizável de níveis.
- `ui/level_details/level_details.tscn`: painel modal de detalhes.
- `ui/components/map_card.tscn` e `level_button.tscn`: cartões instanciados a partir dos dados.
- `ui/menu_theme.tres`: cores, estilos e aparência dos controles compartilhados.

O tema usa diretamente os sprites de `assets/ui_essentials/Sprites/` como `StyleBoxTexture` com nove regiões para redimensionamento: botões, estados de interação, seleção e painéis. Azul e laranja retomam as cores do humanoide; o fundo azul claro mantém a leitura dos textos. Os sprites originais são preservados, com as variações de cor configuradas no tema pelo Inspector.

A interface deve conter apenas textos essenciais: títulos, nomes, números e ações. Não adicionar slogans, descrições, dicas ou outros textos sem solicitação do usuário.

Os scripts conectam navegação e dados. A estrutura dos controles fica nos arquivos `.tscn`. Os cartões da seleção são preenchidos ao executar o projeto.

## Conteúdo

`content/maps/` contém Factory (Fábrica), Dungeon (Masmorra) e Forest (Floresta). Cada Resource referencia seis níveis de `content/levels/`. Para adicionar conteúdo, crie os Resources no Inspector e inclua o mapa na propriedade **Maps** da cena App. Preserve os identificadores existentes ao renomear conteúdo.

As ilustrações SVG em `ui/art/` foram criadas para esta interface.

O campo `scene_path` de cada nível define a cena jogável; níveis sem cena mostram “Em breve”. A Fábrica possui seis fases com exercícios de lógica e desbloqueio sequencial. Ao iniciar o aplicativo com F5, o menu inicial sempre é exibido.

## Fases da fábrica

Abra uma destas cenas e pressione **F6** para explorar com **WASD ou setas**:

| Cena em `gameplay/levels/factory/` | Setor | Área de circulação |
| --- | --- | --- |
| `factory_01_assembly.tscn` | Linha de montagem, braços robóticos, embalagem e consoles | 18 × 14 unidades |
| `factory_02_coolant.tscn` | Torres de refrigeração, tubulações elevadas e turbina | 22 × 16 unidades |
| `factory_03_dispatch.tscn` | Depósito, prateleiras carregadas, guindastes e expedição | 20 × 20 unidades |
| `factory_04_diagnostics.tscn` | Montagem com novos defeitos e três variáveis | 18 × 14 unidades |
| `factory_05_control.tscn` | Refrigeração com proposições mais compostas | 22 × 16 unidades |
| `factory_06_final.tscn` | Expedição com exercícios finais de equivalência e implicação | 20 × 20 unidades |

Toda a montagem está nas cenas `.tscn`: props, piso, marcações, iluminação e animações podem ser editados no Inspector. Cada sala possui uma faixa de equipamentos de serviço fora dos guarda-corpos. Essa faixa faz parte do mapa e dá espaço para a câmera enquadrar as bordas sem mostrar o exterior.

`gameplay/props/factory/` contém 143 cenas que referenciam os GLBs originais. Peças simples usam caixas posicionadas conforme os limites do modelo; tubos, guindastes, passarelas e outros elementos com vãos usam colisão côncava estática. Setas, engrenagens e produtos decorativos não bloqueiam a circulação. As cenas em `modules/` compõem prateleiras, sinalizadores e vapor. Os pisos têm material próprio e pequenas juntas visuais, mantendo a colisão contínua.

O humanoide existente agora tem raiz `CharacterBody3D`, colisão de cápsula e animações de caminhada/repouso. O controlador usa movimentos relativos à câmera. O addon Phantom Camera fornece o acompanhamento suave; `gameplay/camera/factory_camera.tscn` usa projeção ortográfica, inclinação de 55° e orientação diagonal. Os limites consideram os quatro cantos projetados no piso e se adaptam ao tamanho da janela. O campo `floor_bounds` de cada fase representa os limites externos desse piso, enquanto `walk_bounds` descreve a área interna dos guarda-corpos.

As máquinas `machine`, `machine_window`, `machine_window_bar` e `machine_fortified` possuem **Fault Type** no Inspector: **None** (normal), **Smoke** (fumaça), **Sparks** (faíscas) e **Fire** (fogo com fumaça e faíscas). Algumas máquinas das seis fases começam com defeito. As partículas saem de **Fault Origin**, em coordenadas locais da máquina. Alterar `fault_type` durante o jogo liga ou desliga os efeitos; `None` também apaga a luz do fogo. A cena reutilizável `modules/machine_fault.tscn` usa partículas de CPU compatíveis com o renderizador GL Compatibility.

Ao chegar a até 2,3 unidades de uma máquina com defeito, ela recebe uma borda verde contrastante. **E** seleciona a máquina mais próxima; um clique seleciona a máquina destacada sob o cursor. O painel pausa a fase e apresenta uma tabela verdade com as proposições simples e intermediárias preenchidas. Complete apenas a última coluna com **V/F** e clique em **Consertar**. Respostas incompletas ou incorretas mantêm o defeito e permitem outra tentativa. **Fechar/Esc** retoma a fase preservando a tentativa.

O painel de proposições em `ui/repair_panel/repair_panel.tscn` tem moldura metálica, parafusos, telas luminosas e cabos, seguindo a referência industrial. **V** aparece em verde e **F** em vermelho; os cabos acompanham o valor escolhido na última coluna e ficam neutros nas linhas sem resposta. O visual é desenhado em Godot por `industrial_plate.gd`, com cores e espaçamentos em `industrial_theme.tres`, e mantém rolagem para exercícios com mais colunas ou oito linhas.

Ao consertar todas as máquinas, a próxima fase é desbloqueada e o botão **Próxima fase** permite continuar. O autoload `GameProgress` salva os níveis concluídos em `user://progress.cfg`, independentemente da preferência de tema. As fases 4–6 herdam os layouts das três primeiras com novos defeitos. `gameplay/logic/logic_puzzle.gd` define os exercícios: a dificuldade cresce com mais operadores, resultados intermediários e, a partir da fase 4, três variáveis/oito linhas. Os campos **Level Number** e **Interaction Distance** são editáveis no Inspector da fase.

Para validar props, física, acompanhamento, cantos do mapa e redimensionamento:

```sh
godot --headless --path . --script res://tests/factory_level_test.gd
godot --headless --path . --script res://tests/machine_fault_test.gd
godot --headless --path . --script res://tests/repair_flow_test.gd
```

Com um display disponível, remova `--headless` e acrescente `-- --capture` para capturas em `/tmp/easy-code-factory-*.png`. As imagens `overview` usam uma câmera temporária exclusiva do teste para mostrar a montagem completa; essa câmera não existe nas fases.

O teste `repair_flow_test.gd` cobre tabelas verdade, proximidade, borda, seleção por mouse/E, tentativas, isolamento do painel, redimensionamento, as seis fases e persistência do desbloqueio. Ele usa um save separado em `/tmp`. Com `-- --capture` e um display, também salva a borda, os exercícios e as conclusões em `/tmp/easy-code-repair-*.png`.

A cena compartilhada `ui/game_menu/game_menu.tscn` adiciona a engrenagem no canto superior direito de cada fase. Clique nela ou pressione Esc para pausar. O botão de fechar ou Esc retoma a fase; Menu principal retorna à tela inicial e Sair encerra o jogo. O painel utiliza o tema com sprites de UI Essentials e um ícone SVG de engrenagem.

## Fases da floresta e da masmorra

Os doze níveis de Floresta e Masmorra abrem fases 3D de exploração livre, com o mesmo humanoide, câmera e menu de pausa da fábrica. O script `gameplay/levels/exploration_level.gd` só guarda `floor_bounds` e `walk_bounds`.

| Cena em `gameplay/levels/forest/` | Ambiente |
| --- | --- |
| `forest_01_glade.tscn` | Clareira ao meio-dia, lago, alvos de arco e círculo de pedras |
| `forest_02_creek.tscn` | Riacho sinuoso de manhã, duas pontes e trilha em circuito |
| `forest_03_camp.tscn` | Acampamento ao entardecer, barracas, fogueira, cercas e torres |
| `forest_04_canyon.tscn` | Desfiladeiro de rochas em dia nublado, passagens estreitas |
| `forest_05_lake.tscn` | Lago ao pôr do sol, ilha central e trilha em anel |
| `forest_06_deepwood.tscn` | Mata fechada à noite, trilhas em teia e fogueiras |

| Cena em `gameplay/levels/dungeon/` | Ambiente |
| --- | --- |
| `dungeon_01_cellar.tscn` | Adega com depósitos e uma caverna nos fundos |
| `dungeon_02_mine.tscn` | Túneis de mina escavados, escoras de madeira |
| `dungeon_03_hall.tscn` | Grande salão com colunas, mesas e estandartes |
| `dungeon_04_prison.tscn` | Corredor de celas com grades e túnel de fuga |
| `dungeon_05_vault.tscn` | Cofres, armadilhas e baús ao redor de um salão |
| `dungeon_06_lair.tscn` | Covil em caverna aberta, com orcs e braseiros |

`gameplay/props/forest/` (22 cenas) e `gameplay/props/dungeon/` (30 cenas) seguem o padrão da fábrica: raiz, `Visual` com o GLB original e `Collision`. Os kits têm metade da escala do humanoide, por isso `Visual` é dobrado dentro do prop e as fases usam os props em escala 1 (um ladrilho mede 2 unidades). Troncos, barris e colunas usam cilindros; rochas, barracas e estruturas vazadas usam colisão côncava; a ponte e o portal colidem só nas laterais para permitir a passagem. `modules/` reúne fogueira, torre de vigia, abrigo e braseiro.

Na floresta, o chão, as trilhas e a água são camadas `MultiMeshInstance3D` em `Terrain`; `Barriers` contém os colisores invisíveis ao longo da mata e das margens. Objetos entre a câmera e as áreas de passagem são mais baixos para não esconder o jogador. Na masmorra, as paredes do lado da câmera ficam rebaixadas pelo mesmo motivo; salas pavimentadas recebem alvenaria e cavernas ficam em terra bruta. `Waypoints` marca os pontos de interesse de cada fase.

```sh
godot --headless --path . --script res://tests/exploration_levels_test.gd
```

O teste percorre props, módulos e as doze fases: chão, barreiras em quatro direções, pontos de interesse, enquadramento e redimensionamento. Com um display, `-- --capture` salva `/tmp/easy-code-<fase>-*.png`.

## Bibliotecas de áudio e efeitos

`assets/background-sounds/30 Sci-fi Space Tracks/` mantém 30 músicas completas em `Tracks/ogg/` e 30 versões para repetição em `Loops/ogg/`, além da licença do pacote. As cópias WAV e MP3 ficam apenas locais e são ignoradas pelo Git; as mesmas 60 faixas em OGG ocupam aproximadamente 197 MiB. A biblioteca está disponível para uso futuro e ainda não está conectada às cenas.

`assets/brackeys_vfx_bundle/`, `assets/kenney_particle/`, `assets/kenney_smoke-particles/` e `assets/fonts/` guardam os recursos de efeitos e fontes disponíveis no projeto.

## Controles e validação

Mouse ou Tab/setas para navegar; Enter/Espaço para selecionar. Escape fecha o painel de detalhes ou volta uma tela. O botão Sair encerra o aplicativo.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/menu_flow_test.gd
godot --headless --path . --script res://tests/gameplay_menu_test.gd
```

O teste exercita os três mapas, os 18 níveis, isolamento do modal, restauração de foco, redimensionamento e reinicialização. Com um display disponível, execute sem `--headless` e acrescente `-- --capture` para salvar capturas em `/tmp/easy-code-*.png`.
