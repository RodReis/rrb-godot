# FRONTEND-LAUNCHER.md — Contrato de engenharia da interface do Launcher

**Normativo. Toda tarefa de UI do Launcher começa por aqui.** A HUD do Game segue as seções 2, 3 e 6 deste documento (mesmo Theme e componentes); o restante é específico do Launcher. Aparência: `docs/design-system/`. Arquitetura: `ARCHITECTURE-LAUNCHER.md`.

## 1. Stack fixada

| Item | Valor | Não negociável sem ADR |
|---|---|---|
| Engine | Godot **4.7.2**, GDScript estático (`untyped_declaration` = erro) | sim |
| UI | nós `Control` nativos + `Theme` único (`shared/ui/theme/theme_moba.tres`) | sim |
| Resolução de design | 1920×1080, `stretch/mode=canvas_items`, `aspect=expand` (DV §1.4) | sim |
| Fontes | 2 famílias (display + dados), arquivos em `shared/ui/theme/fonts/` — nome definido em `TOKENS.md` | sim |
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
        ├── <corpo>             HBox/Grid conforme DV
        └── ScreenFooter        componente: atalhos de teclado · status
```

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

Verificação visual final é do PI (`CLAUDE.md`): o Code para e pede.

## 7. O que não é deste documento

Cores, fontes, espaçamentos e componentes (→ `docs/design-system/`); fluxo de telas e serviços (→ `ARCHITECTURE-LAUNCHER.md`); textos e regras de domínio (→ `CONVENTION.md`).
