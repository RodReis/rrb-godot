# DEBITO.md — Débito de design (intencional e registrado)

O que está fora do contrato **de propósito**, com dono e gatilho. Débito sem linha aqui não existe — é defeito. Linha fechada move para "Quitado".

## Aberto

| # | Débito | Por que aceito | Dono | Gatilho / prazo |
|---|---|---|---|---|
| DS-02 | Sem opção "reduzir animação" | fatia; nenhuma animação > 0,6 s | Cowork | playtest M4 reportar desconforto |
| DS-03 | Diorama 3D do lobby pode ser trocado por imagem estática | custo de GPU/manutenção ainda não medido | PI | FPS do lobby < 60 em máquina de referência do PI |
| DS-04 | `RED` (4,4:1) e `PURPLE` (4,1:1) da paleta de `telas/` **não passam** 4,5:1 como texto sobre `BG_PANEL` (`BLUE` passou a 5,2:1 com a paleta nova) | paleta é do PI (R-PEND-11); regra: só fundo/borda/ícone ou texto ≥ 24 px bold | PI | se precisar de texto pequeno nessas cores → tokens `*_TEXT` mais claros (ex.: `#F87171`, `#C084FC`) — decisão do PI |
| DS-05 | Sem tema claro / alto contraste | PC, público casual, fatia | — | fase B |
| DS-06 | Ícones de **skills** são placeholders geométricos SVG (`shared/ui/icons/`, F43; um conjunto por herói, 10 heróis); os 24 ícones de **itens** saíram renderizados no Blender no F48 (`shared/ui/icons/items/`) | arte própria das skills ainda não existe | PI (arte) | antes do playtest M4 |
| ~~DS-07~~ | **Fechado no F65 (#170, 2026-10-13):** o `Minimap` desenha uma imagem pronta do mapa em `_draw`, sem `SubViewport`. Era: `Minimap` da fase 1 por `SubViewport` (câmera ortográfica) pode custar FPS | mais simples que desenhar; medir | Code | `TIME_FPS` < 60 em partida → trocar por `_draw` como o `ZoneRadar`. Medido 2026-10-09 (F13, offline + bot, sem vsync): ~600–670 fps com o minimapa, ~570–620 sem — custo não mensurável nesta máquina |
| DS-11 | Galeria incompleta: `Minimap` não está em `_gallery.tscn`; `HeroPreview3D`, `StatsGrid` e `LatencyPlot` (COMPONENTS.md) nunca foram implementados | nenhuma tela os pediu; `ScoreBanner`, `ZoneRadar` e `TargetFrame` já estão na galeria | Code | tela que precise deles, ou remover da tabela |
| DS-09 | Textos em `tr()` sem arquivo de tradução | só pt-BR na fatia (PRD §12) | — | localização entrar no roadmap |
| DS-10 | Sem som de UI definido (DV cita "lâmina/madeira") | assets de áudio não escolhidos; o Launcher continua sem som de UI (nenhum `AudioStreamPlayer`) | PI | quando o PI escolher os assets |

## Quitado

| # | Débito | Quitado em |
|---|---|---|
| DS-01 | Fonte display escolhida: Space Grotesk (OFL), com Outfit e JetBrains Mono — paleta e fontes de `docs/prd/telas/` (R-PEND-11) | 2026-10-09 |
| DS-08 | Fontes provisórias e `StyleBoxFlat` até o design system v2 — trocadas por Cinzel/Montserrat/Barlow Condensed (R-PEND-14) e molduras `StyleBoxTexture` (F43, ADR-0006) | 2026-10-11 |
