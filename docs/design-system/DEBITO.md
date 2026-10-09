# DEBITO.md — Débito de design (intencional e registrado)

O que está fora do contrato **de propósito**, com dono e gatilho. Débito sem linha aqui não existe — é defeito. Linha fechada move para "Quitado".

## Aberto

| # | Débito | Por que aceito | Dono | Gatilho / prazo |
|---|---|---|---|---|
| DS-02 | Sem opção "reduzir animação" | fatia; nenhuma animação > 0,6 s | Cowork | playtest M4 reportar desconforto |
| DS-03 | Diorama 3D do lobby pode ser trocado por imagem estática | custo de GPU/manutenção ainda não medido | PI | FPS do lobby < 60 em máquina de referência do PI |
| DS-04 | `RED` (4,4:1) e `PURPLE` (4,1:1) da paleta de `telas/` **não passam** 4,5:1 como texto sobre `BG_PANEL` (`BLUE` passou a 5,2:1 com a paleta nova) | paleta é do PI (R-PEND-11); regra: só fundo/borda/ícone ou texto ≥ 24 px bold | PI | se precisar de texto pequeno nessas cores → tokens `*_TEXT` mais claros (ex.: `#F87171`, `#C084FC`) — decisão do PI |
| DS-05 | Sem tema claro / alto contraste | PC, público casual, fatia | — | fase B |
| DS-06 | Ícones de skills/itens/HUD inexistentes (DV §3.1 lista nomes, não arquivos) | arte CC0 até M4; placeholders geométricos com letra | Code (placeholder) / PI (arte) | antes do playtest M4 |
| DS-07 | `Minimap` da fase 1 por `SubViewport` (câmera ortográfica) pode custar FPS | mais simples que desenhar; medir | Code | `TIME_FPS` < 60 em partida → trocar por `_draw` como o `ZoneRadar` |
| DS-08 | `ScoreBanner`, `ZoneRadar`, `Minimap`, `LatencyPlot` só existem a partir do MVP2/M0 — galeria incompleta até lá | ordem de implementação | Code | fechar com as fatias F13/F17 |
| DS-09 | Textos em `tr()` sem arquivo de tradução | só pt-BR na fatia (PRD §12) | — | localização entrar no roadmap |
| DS-10 | Sem som de UI definido (DV cita "lâmina/madeira") | assets de áudio não escolhidos | PI | antes de F24 |

## Quitado

| # | Débito | Quitado em |
|---|---|---|
| DS-01 | Fonte display escolhida: Space Grotesk (OFL), com Outfit e JetBrains Mono — paleta e fontes de `docs/prd/telas/` (R-PEND-11) | 2026-10-09 |
