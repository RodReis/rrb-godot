# FRONTEND-LAUNCHER.md — Contrato de engenharia da interface do Launcher

**Normativo. Toda tarefa de UI do Launcher começa por aqui — e toda tela do Launcher é entregue fiel ao protótipo de `docs/prd/telas/` (§8).** A HUD do Game segue as seções 2, 3 e 6 deste documento (mesmo Theme e componentes); o restante é específico do Launcher. Aparência: `docs/design-system/`. Arquitetura: `ARCHITECTURE-LAUNCHER.md`.

## 1. Stack fixada

| Item | Valor | Não negociável sem ADR |
|---|---|---|
| Engine | Godot **4.7.2**, GDScript estático (`untyped_declaration` = erro) | sim |
| UI | nós `Control` nativos + `Theme` único (`shared/ui/theme/theme_moba.tres`) | sim |
| Resolução de design | 1920×1080, `stretch/mode=canvas_items`, `aspect=expand` (DV §1.4) | sim |
| Fontes | as 3 famílias dos protótipos (Space Grotesk, Outfit, JetBrains Mono — `TOKENS.md`) + ícones Material Symbols Outlined, arquivos em `shared/ui/theme/fonts/` (decisão do PI 2026-10-10, §8) | sim |
| 3D no Launcher | apenas o diorama do lobby e previews em `SubViewport` | sim |
| Animação | `Tween` criado por código (`create_tween()`); `AnimationPlayer` só para sequências com > 3 propriedades | — |
| Rede | `HTTPRequest` via `ApiClient`; **nunca** em tela | sim |
| Testes | GUT (`launcher/test/unit`) | sim |
| Proibido | plugin de UI de terceiros, `RichTextLabel` com BBCode vindo do servidor sem escape, `get_node("../../..")`, `yield`, nó sem tipo | sim |

## 2. Tipagem e organização de script

- Ordem no arquivo e nomenclatura: `CLAUDE.md` "Regras de código GDScript".
- Um controller de tela estende `Control` e tem `class_name <Nome>Screen`. Referências a nós **só** por `@onready var _x: Tipo = %NomeUnico` (unique names, `%`). Caminho relativo profundo é P1.
- Sinais da tela para fora: passado (`queue_requested`, `logout_requested`). A tela **nunca** chama o router; emite e o `App` decide.
- Dados que entram na tela: um método público `bind(model: X) -> void` tipado. Tela sem `bind` é tela estática.
- Strings de UI em `tr()` desde o início (só pt-BR na fatia, PRD §12 — mas `tr()` custa zero e evita refatoração).

## 3. Padrão de tela (todas as 5)

```
<Nome>Screen (Control, Full Rect, theme = theme_moba)
├── Backdrop            PanelCard variant=surface (ou diorama no lobby)
└── MarginContainer     margem = TOKENS.space.screen (40 px)
    └── VBoxContainer
        ├── ScreenHeader        componente: botão voltar · título H1 · slot direito (ação/filtro)
        ├── <corpo>             HBox/Grid conforme o protótipo (§8)
        └── ScreenFooter        componente: atalhos de teclado · status
```

- O cabeçalho e o rodapé seguem o protótipo da tela (§8); `ScreenHeader`/`ScreenFooter` são os componentes que os implementam.
- **Estados obrigatórios** de qualquer tela ou card que carrega dado remoto: `idle`, `loading`, `ready`, `empty`, `error(message, retry)`. Implementados por um `StateBox` (componente) que troca o filho visível. Tela sem os 5 estados não passa em revisão.
- Foco: toda tela define `focus_neighbor` e o primeiro foco (`grab_focus()` em `_ready`); navegável só por teclado/gamepad (dual-focus do 4.6: feedback visual difere por dispositivo — testar os dois).
- `Esc` = `cancel` → `back_requested`. Nunca `get_tree().quit()` de dentro de tela.

### 3.1 Tela de catálogo (Bestiário, Forja) — padrão "lista + detalhe"

Esquerda `ItemList`/`VBox` de botões (largura fixa `TOKENS.size.list_col`), direita `DetailCard` que recebe `bind(resource)`. Seleção por sinal `selected(id)`. Dados de `CatalogService` (`shared/data`), nunca hardcoded na cena — **o DV traz valores de exemplo nos wireframes; eles não são fonte**.

### 3.2 Tela de formulário (Login, Configurações)

`LineEdit`/`OptionButton`/`HSlider` dentro de `FormRow` (label + controle + erro). Validação local síncrona antes de chamar service; erro do servidor exibido no `FormRow` correspondente ou no `StateBox` da tela. Botão primário desabilitado durante `loading`.

### 3.3 Tela de lista (Histórico)

`Tree` com colunas configuradas em código a partir de `MatchSummary`; paginação simples (20 por página); linha selecionada → `DetailCard`.

## 4. Performance

- Alvo: 60 fps no lobby com diorama; ≥ 120 fps nas demais telas em 1080p (medido com `Performance.get_monitor`).
- Diorama: `SubViewport.render_target_update_mode = UPDATE_WHEN_VISIBLE`, 30 fps, pausa ao perder foco.
- Nada em `_process` em telas de catálogo (`set_process(false)` após `_ready`). Polling da fila é `Timer`, não `_process`.
- Sem `instantiate()` em loop de UI a cada frame; listas grandes (histórico) usam `Tree`, não um `PanelCard` por linha.
- `Theme` único: evita `StyleBox` por nó (draw calls); override local só via `theme_type_variation`.

## 5. Acessibilidade mínima

- Contraste texto/fundo ≥ 4,5:1: `TEXT`, `TEXT_MUTED`, `GOLD`, `GOLD_BRIGHT`, `CYAN`, `GREEN` passam; `BLUE`, `RED`, `PURPLE` **não** (tabela em `TOKENS.md` §1) — usar só em fundo/borda/ícone ou texto ≥ 24 px bold.
- Tamanho mínimo de alvo clicável 40×40 px.
- Tudo acionável por teclado; rótulos de atalho visíveis (`HotkeyBadge`).
- Nunca cor como único portador de significado (raridade tem cor **e** texto/ícone).

## 6. Prova por tela (checklist da PR de UI)

Toda PR que toca uma tela anexa:

1. Captura 1920×1080 **e** 1280×720 (stretch) de cada estado (`loading`, `ready`, `empty`, `error`).
2. Navegação completa só por teclado (descrição ou GIF curto).
3. Saída do GUT da tela/serviço afetado.
4. `Performance.get_monitor(TIME_FPS)` no lobby se tocou no diorama.
5. Confirmação de que nenhum valor de catálogo está hardcoded (grep por números do GDB na cena/script).
6. **Fidelidade (§8):** captura Godot × `screen.png` do protótipo, lado a lado, por tela e estado, com a lista de desvios e o motivo de cada um.

Verificação visual final é do PI (`CLAUDE.md`): o Code para e pede.

## 7. O que não é deste documento

Cores, fontes, espaçamentos e componentes (→ `docs/design-system/`); fluxo de telas e serviços (→ `ARCHITECTURE-LAUNCHER.md`); textos e regras de domínio (→ `CONVENTION.md`).

## 8. Fidelidade ao protótipo (obrigatória — decisão do PI em 2026-10-10)

Toda tela do Launcher é entregue **pronta e com acabamento**, fiel ao protótipo da sua pasta em `docs/prd/telas/` — não uma versão básica. Cada pasta tem `screen.png` (referência visual), `code.html` (medidas: classes Tailwind → px, cores, efeitos, animações), `DESIGN.md` (tokens) e um texto descritivo.

### 8.1 Tela → protótipo → card

| Tela | Pasta em `docs/prd/telas/` | Card |
|---|---|---|
| Configurações (+ aba Créditos) | `Ajustes & Diagnóstico de Rede/` | F24 #80 |
| Login e cadastro | `Tela de Login & Autenticação/` | F25 #81 |
| Lobby | `Menu Principal/` (`screen1.png`, `screen2.png`) | F25 #81 |
| Histórico | `Histórico de Partidas — Duelos/` | F26 #83 |
| Bestiário | `Guia & Bestiário — Monstros e Equipamentos/` | F27 #84 |
| Forja | `Equipamentos & Forja/` | F27 #84 |
| Arena & Mapa | `Arena & Mapa — O Vale Rúnico Apocalíptico/` | F33 #85 |
| Perfil (nickname, avatar) | sem pasta: formulário no estilo do Login; perfil = chip do cabeçalho do `Menu Principal/` com `#nickname` e avatar, sem ELO | F35 #86 |

As pastas `Seleção de Heróis/`, `Destaques da Tela de Fim de Partida/` e `Pop-up Tático In-Game/` são do Game ou sem requisito e ficam fora desta regra.

### 8.2 O que é fiel

Composição e layout, hierarquia, cores, tipografia, espaçamentos, raios, bordas, sombras, brilhos e desfoques, ícones (mesmo glifo do `code.html`), cartões e badges, cabeçalho e rodapé, estados de hover/foco/pressionado, transições e animações (pulsos, tweens). O que o CSS faz e o `Control` não faz nativamente (ex.: `backdrop-blur`, gradiente) é feito com `StyleBox`, shader ou textura — não omitido.

### 8.3 O que segue as decisões, não o protótipo

1. **Elemento sem requisito ou excluído** (`FORA-DE-ESCOPO.md`, `RASTREABILIDADE.md`, `CONVENTION.md`, ADRs) é **removido** — sem placeholder, sem "em breve", sem botão desabilitado. O espaço é recomposto mantendo o equilíbrio visual do protótipo. A lista do que sai de cada tela está na issue do card.
2. **Todo número, nome e contagem** vem de `shared/data` (GDB), do backend ou do estado real. Nenhum texto de exemplo do protótipo entra (ELO, "34 duelistas", "24ms", patch, versão do Godot, servidores, KDA de exemplo).
3. **Imagens** do protótipo (geradas, hospedadas fora do repo, licença desconhecida) **não entram**: são substituídas por renders dos assets reais (KayKit/Blender, ADR-0005) com a mesma composição e enquadramento, em `shared/assets/ui/`.
4. **Ícones**: Material Symbols Outlined (Apache-2.0), empacotados como fonte em `shared/ui/theme/fonts/` e listados na aba Créditos.

### 8.4 Estrutura e resolução

O protótipo **vence o DV na composição** (emenda da R-PEND-11 em 2026-10-10). Os protótipos são páginas web com rolagem; a tela é adaptada a 1920×1080 **sem rolagem de página** (rolagem só dentro de listas), mantendo ordem, proporções e agrupamentos. O DV continua valendo para comportamento, sinais e navegação (`ARCHITECTURE-LAUNCHER.md` §3.4): abas do cabeçalho apontam só para rotas que existem.

### 8.5 Aceite

Item 6 da §6: captura Godot × `screen.png`, lado a lado, por tela e estado, na PR, com a lista de desvios e o motivo de cada um (regras 1–4 de §8.3 ou limitação técnica do Godot demonstrada). **Desvio sem motivo reprova.** O card só vai para `proplan:done` após a aprovação visual do PI.
