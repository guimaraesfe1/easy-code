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

Na seleção de níveis, Fábrica 01, 02 e 03 abrem suas fases 3D. Os demais níveis mostram “Em breve”. O campo `scene_path` de cada nível define a cena jogável. Não há exercícios, desbloqueio ou save. Ao iniciar o aplicativo com F5, o menu inicial sempre é exibido.

## Fases da fábrica

Abra uma destas cenas e pressione **F6** para explorar com **WASD ou setas**:

| Cena em `gameplay/levels/factory/` | Setor | Área de circulação |
| --- | --- | --- |
| `factory_01_assembly.tscn` | Linha de montagem, braços robóticos, embalagem e consoles | 18 × 14 unidades |
| `factory_02_coolant.tscn` | Torres de refrigeração, tubulações elevadas e turbina | 22 × 16 unidades |
| `factory_03_dispatch.tscn` | Depósito, prateleiras carregadas, guindastes e expedição | 20 × 20 unidades |

Toda a montagem está nas cenas `.tscn`: props, piso, marcações, iluminação e animações podem ser editados no Inspector. Cada sala possui uma faixa de equipamentos de serviço fora dos guarda-corpos. Essa faixa faz parte do mapa e dá espaço para a câmera enquadrar as bordas sem mostrar o exterior.

`gameplay/props/factory/` contém 143 cenas que referenciam os GLBs originais. Peças simples usam caixas posicionadas conforme os limites do modelo; tubos, guindastes, passarelas e outros elementos com vãos usam colisão côncava estática. Setas, engrenagens e produtos decorativos não bloqueiam a circulação. As cenas em `modules/` compõem prateleiras, sinalizadores e vapor. Os pisos têm material próprio e pequenas juntas visuais, mantendo a colisão contínua.

O humanoide existente agora tem raiz `CharacterBody3D`, colisão de cápsula e animações de caminhada/repouso. O controlador usa movimentos relativos à câmera. O addon Phantom Camera fornece o acompanhamento suave; `gameplay/camera/factory_camera.tscn` usa projeção ortográfica, inclinação de 55° e orientação diagonal. Os limites consideram os quatro cantos projetados no piso e se adaptam ao tamanho da janela. O campo `floor_bounds` de cada fase representa os limites externos desse piso, enquanto `walk_bounds` descreve a área interna dos guarda-corpos.

Para validar props, física, acompanhamento, cantos do mapa e redimensionamento:

```sh
godot --headless --path . --script res://tests/factory_level_test.gd
```

Com um display disponível, remova `--headless` e acrescente `-- --capture` para capturas em `/tmp/easy-code-factory-*.png`. As imagens `overview` usam uma câmera temporária exclusiva do teste para mostrar a montagem completa; essa câmera não existe nas fases.

A cena compartilhada `ui/game_menu/game_menu.tscn` adiciona a engrenagem no canto superior direito de cada fase. Clique nela ou pressione Esc para pausar. O botão de fechar ou Esc retoma a fase; Menu principal retorna à tela inicial e Sair encerra o jogo. O painel utiliza o tema com sprites de UI Essentials e um ícone SVG de engrenagem.

## Controles e validação

Mouse ou Tab/setas para navegar; Enter/Espaço para selecionar. Escape fecha o painel de detalhes ou volta uma tela. O botão Sair encerra o aplicativo.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/menu_flow_test.gd
godot --headless --path . --script res://tests/gameplay_menu_test.gd
```

O teste exercita os três mapas, os 18 níveis, isolamento do modal, restauração de foco, redimensionamento e reinicialização. Com um display disponível, execute sem `--headless` e acrescente `-- --capture` para salvar capturas em `/tmp/easy-code-*.png`.
