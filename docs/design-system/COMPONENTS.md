# COMPONENTS.md — Componentes reutilizáveis

Cenas em `shared/ui/components/<snake_case>.tscn`, script `class_name <PascalCase>` com API pública tipada e sinais no passado. Usados pelo Launcher e pela HUD do Game. Componente que só uma tela usa **não** entra aqui (fica na pasta da tela).

Convenções: props por `@export`; dados por `bind(...)`; estados por `enum State`; nenhum componente faz rede nem lê `shared/data` sozinho (recebe o Resource).

| Componente | Extende | API pública | Variantes / estados | Usado em |
|---|---|---|---|---|
| `PanelCard` | `PanelContainer` | `@export var variant: Variant_ = PANEL` ; `@export var accent: Accent = NONE` | `variant`: `SURFACE`, `PANEL`, `INNER` ; `accent`: `NONE`, `GOLD`, `RED`, `GREEN`, `PURPLE` (borda 3 px) | todas |
| `ScreenHeader` | `HBoxContainer` | `bind(title: String, show_back: bool)` ; slot `%RightSlot` ; sinal `back_requested` | — | todas as telas do Launcher; `hero_select` |
| `ScreenFooter` | `PanelContainer` | `bind(hints: Array[HotkeyHint], status: String)` | — | todas |
| `HotkeyBadge` | `Label` (variation `LabelBadge`) | `@export var key: String` | `size`: `SM` (12 px), `MD` (sobre ícone de skill) | HUD, rodapés, tela de controles |
| `StatBar` | `HBoxContainer` | `bind(label: String, value: float, max_value: float, variant)` ; `animate_to(value, dur)` | `variant`: `HP`, `HP_ENEMY`, `XP`, `STAT` (azul) ; `show_numbers: bool` | seleção de herói, forja, HUD |
| `SlotItem` | `TextureButton` | `bind(item: ItemData)` ; `clear()` ; sinal `hovered(item)`, `pressed_slot(slot)` | borda por raridade (`RARITY_*`); `empty` ; tooltip rico (`ItemTooltip`) | HUD F1/F2, forja |
| `ItemTooltip` | `PanelCard` | `bind(item: ItemData)` | — | `SlotItem` |
| `SkillButton` | `TextureProgressBar` | `bind(skill: SkillData, level: int)` ; `set_cooldown(remaining: float, total: float)` ; `set_locked(bool)` | `locked` (R < nível 6), `ready`, `cooling`, `upgradable` (ponto disponível) | HUD |
| `TimerLabel` | `Label` (`LabelCounter`) | `set_seconds(s: float)` ; `@export var format: Format = MM_SS` | `warning` (pisca `GOLD`), `danger` (`RED`) | HUD, lobby (fila), pick |
| `StateBox` | `Control` | `set_state(State, message := "")` ; sinal `retry_requested` | `IDLE`, `LOADING` (spinner), `READY`, `EMPTY`, `ERROR` | toda tela/card com dado remoto |
| `FormRow` | `VBoxContainer` | `bind(label)` ; slot `%Control` ; `set_error(msg)` ; `clear_error()` | `error` | login, configurações |
| `Toast` | `PanelCard` | `show_message(text, kind, dur := 3.0)` | `kind`: `INFO`, `SUCCESS`, `WARN`, `ERROR` | overlay global (App), HUD (notificação de loot) |
| `ModalDialog` | `PanelCard` (overlay) | `open(title, body, actions: Array[DialogAction]) -> int` (await) | — | confirmar sair, abandonar partida, encerrar jogo |
| `HeroPreview3D` | `SubViewportContainer` | `bind(hero: HeroData)` ; `set_animation(name)` | `idle`, `pose` | lobby (diorama), pick, bestiário (monstro: `MonsterPreview3D`, mesma base) |
| `StatsGrid` | `GridContainer` (2 col) | `bind(stats: Dictionary[String, float], max_ref: Dictionary)` | — | pick, forja, bestiário |
| `ScoreBanner` | `PanelCard` | `bind(p1: PlayerScore, p2: PlayerScore, target: int)` | destaque do líder | HUD F2, fim de partida |
| `ZoneRadar` | `Control` (`_draw`) | `set_zone(radius_pct: float, next_radius_pct: float, t_next: float)` ; `set_players(positions)` | — | HUD F2 (minimapa) |
| `Minimap` | `SubViewportContainer` | `bind(world: Node3D)` ; `set_markers(...)` | — | HUD F1 |
| `LatencyPlot` | `Control` (`_draw`) | `push_sample(ms)` ; `@export var ceiling_ms := 80` | — | `net_debug.tscn` (Game) |
| `CatalogList` | `VBoxContainer` | `bind(entries: Array[CatalogEntry])` ; sinal `selected(id: StringName)` | — | bestiário, forja |
| `DetailCard` | `PanelCard` | `bind(resource: Resource)` (despacha por tipo) | — | bestiário, forja, histórico |

## Regras

1. Todo componente tem cena de demonstração em `shared/ui/components/_gallery.tscn` com cada variante/estado lado a lado — é a "prova visual" do componente e o que o PI olha.
2. Todo componente com lógica (`StatBar.animate_to`, `TimerLabel`, `StateBox`, `SlotItem` raridade) tem GUT em `shared/test/ui/`.
3. Componente não conhece tela: não emite "vá para X"; emite o que aconteceu.
4. Sem `add_theme_*_override` dentro de componente; variantes via `theme_type_variation` ou `modulate`.
5. Nome de nó interno único com `%`; nada de `get_node("VBox/HBox/Label")`.
