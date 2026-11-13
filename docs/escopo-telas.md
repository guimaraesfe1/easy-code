# Escopo das telas

Escopo do que cada tela mostra e faz, derivado da camada de dados e lógica que já existe no projeto. O Easy Code não tem servidor: o "backend" aqui são os Resources de conteúdo, os autoloads e os scripts de regra do jogo. Cada tela lista só o que essa camada já fornece; o que ela ainda não fornece está em [Lacunas](#lacunas).

Regra herdada do README: a interface contém apenas textos essenciais (títulos, nomes, números e ações). Nada de slogans, descrições ou dicas sem pedido explícito.

## Camada de dados e lógica

| Fonte | Onde | O que expõe para as telas |
| --- | --- | --- |
| `MapDefinition` | `content/maps/*.tres` | `id`, `display_name`, `illustration`, `accent`, `levels[]`. O campo `description` existe, mas não é exibido. |
| `LevelDefinition` | `content/levels/*.tres` | `id`, `number`, `scene_path` (vazio = "Em breve"). Não há nome nem descrição por nível. |
| `GameProgress` (autoload) | `gameplay/progression/game_progress.gd` | `completed_factory_level` (0–6), `is_level_unlocked(map_id, number)`, `complete_factory_level(number)`, sinal `changed`. Salva em `user://progress.cfg`. |
| `ThemeSettings` (autoload) | `ui/theme_settings.gd` | `dark_mode`, `set_dark_mode(bool)`, `set_accent(label, color)`, sinal `theme_changed`. Salva em `user://settings.cfg`. |
| `UIAudio` (autoload) | `ui/ui_audio.gd` | Som de clique automático em todo `BaseButton`. Sem controle de volume. |
| `LogicPuzzle` | `gameplay/logic/logic_puzzle.gd` | `proposition`, `headers[]`, `rows[][]` (colunas já resolvidas), `answers[]`, `accepts(choices)`. |
| `FaultyMachine` | `factory/prop/faulty_machine.gd` | `fault_type`, `answer_choices` (tentativa guardada), `set_highlighted()`, `repair()`, sinal `repaired`. |
| Fase da fábrica | `gameplay/levels/factory/factory_level.gd` | `level_number`, contagem de máquinas, `nearest_machine`, `select_machine()`, estado de conclusão. |
| Fase de exploração | `gameplay/levels/exploration_level.gd` | Só `floor_bounds` e `walk_bounds`. Sem objetivo nem conclusão. |

Conteúdo atual: 3 mapas (Fábrica, Floresta, Masmorra) com 6 níveis cada, todos com cena jogável. Só a Fábrica tem exercícios, bloqueio sequencial e status de concluído; Floresta e Masmorra ficam sempre liberadas.

## Fluxo

```
Menu inicial ─┬─ Jogar ──► Mapas ──► Níveis ──► Fase 3D
              ├─ Opções                 └─► Detalhes "Em breve" (nível sem cena)
              └─ Sair

Fase 3D ─┬─ HUD ─► Painel de conserto ─► Conclusão ─┬─ Próxima fase
         └─ Engrenagem / Esc ─► Pausa               └─ Menu principal
```

Elementos comuns a Mapas, Níveis e Opções (`app/app.tscn`): botão **← Voltar** no cabeçalho, Esc volta uma tela, música de fundo, tamanho mínimo de janela 640 × 480.

## Telas

### 1. Menu inicial — `ui/main_menu/`

- **Mostra:** título "Easy Code"; créditos no rodapé ("Feito por Felipe Guimarães e Cauan Sampaio").
- **Ações:** Jogar → Mapas; Opções → Opções; Sair → encerra.
- **Dados:** `ThemeSettings.dark_mode` troca o layout (tema escuro usa botões planos mais largos e título maior).
- **Estados:** foco inicial em Jogar; Esc não faz nada.

### 2. Opções — `ui/options_menu/`

- **Mostra:** título "Opções".
- **Ações:** alternância **Tema escuro**, aplicada na hora em todas as telas e salva.
- **Dados:** `ThemeSettings.dark_mode` / `set_dark_mode()`.
- **Estados:** o botão reflete a preferência salva ao abrir.

### 3. Seleção de mapas — `ui/map_selection/` + `components/map_card`

- **Mostra:** título "Mapas"; um cartão por mapa com ilustração e nome, fundo tingido pelo `accent`.
- **Ações:** escolher um cartão → Níveis daquele mapa.
- **Dados:** `App.maps[]` → `display_name`, `illustration`, `accent`.
- **Estados:** grade de 3, 2 ou 1 colunas conforme a largura (≥ 960, ≥ 650, menor); ao voltar de Níveis, o foco retorna ao mapa visitado.

### 4. Seleção de níveis — `ui/level_selection/` + `components/level_button`

- **Mostra:** nome do mapa na cor de destaque, ilustração do mapa; um botão por nível com o número em dois dígitos e, quando houver, o status.
- **Ações:** escolher nível liberado → abre a fase (ou o painel "Em breve" se não houver cena).
- **Dados:** `MapDefinition.levels[]`; `GameProgress.is_level_unlocked()` e `completed_factory_level`; sinal `changed` atualiza a lista.
- **Estados por botão:** liberado (sem rótulo), **Concluído**, **Bloqueado** (desabilitado). Só a Fábrica usa os dois últimos. Grade de 3, 2 ou 1 colunas (≥ 850, ≥ 550, menor); foco vai ao último nível escolhido ou ao primeiro liberado.

### 5. Detalhes do nível (modal) — `ui/level_details/`

- **Mostra:** nome do mapa em maiúsculas, ilustração, "Nível NN", "Em breve".
- **Ações:** Fechar (ou Esc) → volta a Níveis com o foco no botão de origem.
- **Dados:** `display_name`, `accent`, `illustration`, `number`.
- **Estados:** bloqueia cliques e foco no fundo. Hoje nenhum nível cai aqui, porque os 18 têm cena; a tela fica como reserva para conteúdo novo.

### 6. HUD da fase da fábrica — `ui/repair_panel/factory_repair_ui.tscn`

- **Mostra:** "Fábrica · Nível NN"; contador "Máquinas: X / Y"; aviso "E ou clique · Consertar" quando há máquina com defeito ao alcance; engrenagem no canto superior direito.
- **Ações:** E seleciona a máquina mais próxima; clique seleciona a máquina destacada; engrenagem ou Esc abre a pausa.
- **Dados:** `level_number`, total inicial de defeitos e restantes, `nearest_machine` (alcance de 2,3 unidades).
- **Estados:** aviso some sem máquina ao alcance, com painel aberto ou com a fase concluída; máquina ao alcance ganha borda verde.

### 7. Painel de conserto (modal) — `ui/repair_panel/repair_panel.tscn`

- **Mostra:** título "Proposições"; a proposição do exercício; tabela verdade com cabeçalhos (p, q, intermediárias, proposição final) e 4 linhas, todas preenchidas menos a última coluna; linha de feedback.
- **Ações:** escolher **V** ou **F** em cada linha da última coluna; **Consertar**; **Fechar** (ou Esc).
- **Dados:** `LogicPuzzle.create(level_number, índice da máquina)` → `proposition`, `headers`, `rows`; `accepts(choices)` valida; `FaultyMachine.answer_choices` restaura a tentativa.
- **Estados:** linha sem resposta ("—"); incompleto → "Complete todas as linhas." e foco na primeira vazia; incorreto → "Há valores incorretos. Revise a última coluna."; correto → fecha, conserta a máquina e toca o efeito. Fechar preserva a tentativa. A fase fica pausada enquanto o painel está aberto. V em verde, F em vermelho; rolagem horizontal em janelas estreitas.

### 8. Conclusão da fase (modal) — nó `Completion` de `factory_repair_ui.tscn`

- **Mostra:** "Nível NN concluído" (ou "Fábrica concluída" no nível 6); "Todas as máquinas foram consertadas."
- **Ações:** **Próxima fase** (oculto no nível 6); **Menu principal**.
- **Dados:** `GameProgress.complete_factory_level()` e `is_level_unlocked()`; `factory.tres` dá a cena seguinte.
- **Estados:** foco em Próxima fase, ou em Menu principal quando não há próxima; falha ao trocar de cena mostra "Não foi possível abrir a fase."

### 9. Pausa (modal) — `ui/game_menu/`

- **Mostra:** painel sobre a fase escurecida.
- **Ações:** fechar (ou Esc) retoma; **Menu principal**; **Sair**.
- **Dados:** nenhum; usa só `get_tree().paused`.
- **Estados:** presente nas 18 fases; fica bloqueada enquanto o painel de conserto ou a conclusão estão abertos.

### 10. Fases de exploração (Floresta e Masmorra)

- **Mostra:** apenas a engrenagem da pausa.
- **Ações:** andar (WASD/setas), correr (Shift), pausar.
- **Dados:** nenhum. Não há HUD, objetivo, contador nem tela de conclusão.

## Lacunas

O que a camada de dados ainda não oferece. Cada item precisa de trabalho de lógica antes de virar tela.

| Lacuna | Efeito na interface | O que falta no "backend" |
| --- | --- | --- |
| Floresta e Masmorra sem objetivo | Fases sem HUD nem conclusão; níveis nunca aparecem como concluídos | Mecânica, regra de conclusão e progresso por mapa (`GameProgress` só conhece a Fábrica) |
| Sem controle de áudio | Opções só tem o tema | Volume de música/efeitos em `settings.cfg` e buses de áudio |
| Sem reinício de progresso | Não há como recomeçar pelo jogo | Método de reset em `GameProgress` |
| Pausa sem "Reiniciar fase" | Só dá para sair ao menu | Nada além do botão (recarregar a cena atual) |
| Nível sem nome | Botões mostram só o número | Campo de nome em `LevelDefinition` |
| Sem registro de desempenho | Conclusão não mostra tentativas nem tempo | Contagem de erros/tempo por fase |
| Propostas repetidas | Fases com mais de 3 máquinas com defeito (níveis 1, 4 e 5) repetem exercícios, pois há 3 variações por nível | Mais expressões por nível em `LogicPuzzle.EXPRESSIONS` |
| Sem tutorial | Operadores (¬, ∧, ∨, →, ↔) aparecem sem apresentação | Conteúdo explicativo; depende de liberar texto além do essencial |
